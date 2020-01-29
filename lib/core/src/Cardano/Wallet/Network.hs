{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

module Cardano.Wallet.Network
    (
    -- * Interface
      NetworkLayer (..)
    , NextBlocksResult (..)
    , Cursor
    , follow
    , FollowAction (..)

    -- * Errors
    , ErrNetworkUnavailable (..)
    , ErrCurrentNodeTip (..)
    , ErrGetBlock (..)
    , ErrPostTx (..)
    , ErrGetAccountBalance (..)

    -- * Logging
    , FollowLog (..)

    -- * Initialization
    , defaultRetryPolicy
    , waitForNetwork
    ) where

import Prelude

import Cardano.BM.Data.Severity
    ( Severity (..) )
import Cardano.BM.Data.Tracer
    ( DefinePrivacyAnnotation (..), DefineSeverity (..) )
import Cardano.Wallet.Primitive.Types
    ( BlockHeader (..)
    , BlockchainParameters (..)
    , ChimericAccount (..)
    , EpochNo
    , Hash (..)
    , PoolId (..)
    , SealedTx
    , SlotId
    )
import Control.Arrow
    ( first )
import Control.Concurrent
    ( threadDelay )
import Control.Concurrent.Async
    ( AsyncCancelled (..) )
import Control.Exception
    ( AsyncException (..)
    , Exception (..)
    , SomeException
    , asyncExceptionFromException
    , catch
    )
import Control.Monad
    ( when )
import Control.Monad.Trans.Except
    ( ExceptT, runExceptT )
import Control.Retry
    ( RetryPolicyM, constantDelay, limitRetriesByCumulativeDelay, retrying )
import Control.Tracer
    ( Tracer, traceWith )
import Data.List.NonEmpty
    ( NonEmpty (..) )
import Data.Map
    ( Map )
import Data.Quantity
    ( Quantity (..) )
import Data.Text
    ( Text )
import Data.Text.Class
    ( ToText (..) )
import Data.Word
    ( Word64 )
import Fmt
    ( pretty )
import GHC.Generics
    ( Generic )
import UnliftIO.Exception
    ( throwIO )

import qualified Data.List.NonEmpty as NE
import qualified Data.Text as T

data NetworkLayer m target block = NetworkLayer
    { nextBlocks
        :: Cursor target
        -> ExceptT ErrGetBlock m (NextBlocksResult target block)
        -- ^ Starting from the given 'Cursor', fetches a contiguous sequence of
        -- blocks from the node, if they are available. An updated cursor will
        -- be returned with a 'RollFoward' result.
        --
        -- Blocks are returned in ascending slot order, without skipping blocks.
        --
        -- If the node does not have any blocks after the specified cursor
        -- point, it will return 'AwaitReply'.
        --
        -- If the node has adopted an alternate fork of the chain, it will
        -- return 'RollBackward' with a new cursor.

    , initCursor
        :: [BlockHeader] -> m (Cursor target)
        -- ^ Creates a cursor from the given block header so that 'nextBlocks'
        -- can be used to fetch blocks.

    , cursorSlotId
        :: Cursor target -> SlotId
        -- ^ Get the slot corresponding to a cursor.

    , currentNodeTip
        :: ExceptT ErrCurrentNodeTip m BlockHeader
        -- ^ Get the current tip from the chain producer

    , postTx
        :: SealedTx -> ExceptT ErrPostTx m ()
        -- ^ Broadcast a transaction to the chain producer

    , staticBlockchainParameters
        :: (block, BlockchainParameters)
        -- ^ Get the genesis block and blockchain parameters.

    , stakeDistribution
        :: ExceptT ErrNetworkUnavailable m
            ( EpochNo
            , Map PoolId (Quantity "lovelace" Word64)
            )

    , getAccountBalance
        :: ChimericAccount
        -> ExceptT ErrGetAccountBalance m (Quantity "lovelace" Word64)
    }

instance Functor m => Functor (NetworkLayer m target) where
    fmap f nl = nl
        { nextBlocks = fmap (fmap f) . nextBlocks nl
        , staticBlockchainParameters = first f $ staticBlockchainParameters nl
        }

{-------------------------------------------------------------------------------
                                  Errors
-------------------------------------------------------------------------------}

-- | Network is unavailable
data ErrNetworkUnavailable
    = ErrNetworkUnreachable Text
      -- ^ Cannot connect to network backend.
    | ErrNetworkInvalid Text
      -- ^ Network backend reports that the requested network is invalid.
    deriving (Generic, Show, Eq)

instance Exception ErrNetworkUnavailable

-- | Error while trying to get the node tip
data ErrCurrentNodeTip
    = ErrCurrentNodeTipNetworkUnreachable ErrNetworkUnavailable
    | ErrCurrentNodeTipNotFound
    deriving (Generic, Show, Eq)

instance Exception ErrCurrentNodeTip

-- | Error while trying to get one or more blocks
data ErrGetBlock
    = ErrGetBlockNetworkUnreachable ErrNetworkUnavailable
    | ErrGetBlockNotFound (Hash "BlockHeader")
    deriving (Generic, Show, Eq)

-- | Error while trying to send a transaction
data ErrPostTx
    = ErrPostTxNetworkUnreachable ErrNetworkUnavailable
    | ErrPostTxBadRequest Text
    | ErrPostTxProtocolFailure Text
    deriving (Generic, Show, Eq)

instance Exception ErrPostTx

data ErrGetAccountBalance
    = ErrGetAccountBalanceNetworkUnreachable ErrNetworkUnavailable
    | ErrGetAccountBalanceAccountNotFound ChimericAccount
    deriving (Generic, Eq, Show)

{-------------------------------------------------------------------------------
                              Initialization
-------------------------------------------------------------------------------}

-- | Wait until 'currentNodeTip networkLayer' succeeds according to a given
-- retry policy. Throws an exception otherwise.
waitForNetwork
    :: ExceptT ErrNetworkUnavailable IO ()
    -> RetryPolicyM IO
    -> IO ()
waitForNetwork getStatus policy = do
    r <- retrying policy shouldRetry (const $ runExceptT getStatus)
    case r of
        Right _ -> return ()
        Left e -> throwIO e
  where
    shouldRetry _ = \case
        Right _ ->
            return False
        Left ErrNetworkInvalid{} ->
            return False
        Left ErrNetworkUnreachable{} ->
            return True

-- | A default 'RetryPolicy' with a delay that starts short, and that retries
-- for no longer than a minute.
defaultRetryPolicy :: Monad m => RetryPolicyM m
defaultRetryPolicy =
    limitRetriesByCumulativeDelay (3600 * second) (constantDelay second)
  where
    second = 1000*1000

{-------------------------------------------------------------------------------
                                Chain Sync
-------------------------------------------------------------------------------}

-- | A cursor is local state kept by the chain consumer to use as the starting
-- position for 'nextBlocks'. The actual type is opaque and determined by the
-- backend @target@.
data family Cursor target

-- | The result of 'nextBlocks', which is instructions for what the chain
-- consumer should do next.
data NextBlocksResult target block
    = AwaitReply
        -- ^ There are no blocks available from the node, so wait.
    | RollForward (Cursor target) BlockHeader [block]
        -- ^ Apply the given contiguous non-empty sequence of blocks. Use the
        -- updated cursor to get the next batch. The given block header is the
        -- current tip of the node.
    | RollBackward (Cursor target)
        -- ^ The chain consumer must roll back its state, then use the cursor to
        -- get the next batch of blocks.

instance Functor (NextBlocksResult target) where
    fmap f = \case
        AwaitReply -> AwaitReply
        RollForward cur bh bs -> RollForward cur bh (fmap f bs)
        RollBackward cur -> RollBackward cur

-- | @FollowAction@ enables the callback of @follow@ to signal if the
-- chain-following should @ExitWith@, @Continue@, or if the current callback
-- should be forgotten and retried (@Retry@).
--
-- NOTE: @Retry@ is needed to handle data-races in
-- 'Cardano.Pool.Metrics', where it is essensial that we fetch the stake
-- distribution while the node-tip
--
-- FIXME:
-- Retry actions with the Haskell nodes are not possible (or at least, requires
-- some additional manipulation to find a new intersection). As a possible fix,
-- we could use a type family to define 'FollowAction' in terms of the
-- underlying target. 'RetryImmediately' and 'RetryLater' could be authorized in
-- the context of Jormungandr but absent in the context of the Haskell nodes.
data FollowAction err
    = ExitWith err
      -- ^ Stop following the chain.
    | Continue
      -- ^ Continue following the chain.
    | RetryImmediately
      -- ^ Forget about the blocks in the current callback, and retry immediately.
    | RetryLater
      -- ^ Like 'RetryImmediately' but only retries after a short delay
    deriving (Eq, Show, Functor)

-- | Subscribe to a blockchain and get called with new block (in order)!
--
-- Exits when the node switches to a different chain with the greatest known
-- common tip between the follower and the node. This makes it easier for client
-- to re-start following from a different point if they have, for instance,
-- rolled back to a point further in the past. If this occurs, clients will need
-- to restart the chain follower from a known list of headers, re-initializing
-- the cursor.
--
-- Exits with 'Nothing' in case of error.
follow
    :: forall target block e. (Show e)
    => NetworkLayer IO target block
    -- ^ The @NetworkLayer@ used to poll for new blocks.
    -> Tracer IO FollowLog
    -- ^ Logger trace
    -> [BlockHeader]
    -- ^ A list of known tips to start from. Blocks /after/ the tip will be yielded.
    -> (NE.NonEmpty block -> BlockHeader -> IO (FollowAction e))
    -- ^ Callback with blocks and the current tip of the /node/.
    -- @follow@ stops polling and terminates if the callback errors.
    -> (block -> BlockHeader)
    -- ^ Getter on the abstract 'block' type
    -> IO (Maybe SlotId)
follow nl tr cps yield header =
    sleep 0 =<< initCursor nl cps
  where
    delay0 :: Int
    delay0 = 500*1000 -- 500ms

    retryDelay :: Int -> Int
    retryDelay 0 = delay0
    retryDelay delay = min (2*delay) (10 * delay0)

    -- | Wait a short delay before querying for blocks again. We also take this
    -- opportunity to refresh the chain tip as it has probably increased in
    -- order to refine our syncing status.
    sleep :: Int -> Cursor target -> IO (Maybe SlotId)
    sleep delay cursor = do
        when (delay > 0) (threadDelay delay)
        step delay cursor `catch` retry
      where
        retry (e :: SomeException) = case asyncExceptionFromException e of
            Just ThreadKilled ->
                return Nothing
            Just UserInterrupt ->
                return Nothing
            Nothing | fromException e == Just AsyncCancelled -> do
                return Nothing
            Just _ -> do
                traceWith tr $ MsgFatalUnhandledException eT
                return Nothing
            _ -> do
                traceWith tr $ MsgUnhandledException eT
                sleep (retryDelay delay) cursor
          where
            eT = T.pack (show e)

    step :: Int -> Cursor target -> IO (Maybe SlotId)
    step delay cursor = runExceptT (nextBlocks nl cursor) >>= \case
        Left e -> do
            traceWith tr $ MsgNextBlockFailed e
            sleep (retryDelay delay) cursor

        Right AwaitReply -> do
            traceWith tr MsgSynced
            sleep delay0 cursor

        Right (RollForward cursor' _ []) -> do -- FIXME Make RollForward return NE
            traceWith tr MsgSynced
            sleep delay0 cursor'

        Right (RollForward cursor' tip (blockFirst : blocksRest)) -> do
            let blocks = blockFirst :| blocksRest
            traceWith tr $ MsgApplyBlocks (header <$> blocks)
            action <- yield blocks tip
            traceWith tr $ MsgFollowAction (fmap show action)
            handle cursor' action

        Right (RollBackward cursor') ->
            -- NOTE
            -- In case the node asks us to rollback to the last checkpoints we
            -- gave, we take no action and simply move on to the next query.
            -- This happens typically with the Haskell nodes which always
            -- initiates the protocol by asking clients to rollback to the last
            -- known intersection.
            case (cursorSlotId nl cursor', cps) of
                (sl, _:_) | sl == slotId (last cps) ->
                    step delay0 cursor'
                (sl, _) ->
                    pure (Just sl)
      where
        handle :: Cursor target -> FollowAction e -> IO (Maybe SlotId)
        handle cursor' = \case
            ExitWith _ -> -- NOTE error logged as part of `MsgFollowAction`
                return Nothing
            Continue ->
                step delay0 cursor'
            RetryImmediately ->
                step delay0 cursor
            RetryLater ->
                sleep delay0 cursor

{-------------------------------------------------------------------------------
                                    Logging
-------------------------------------------------------------------------------}

data FollowLog
    = MsgFollowAction (FollowAction String)
    | MsgFatalUnhandledException Text
    | MsgUnhandledException Text
    | MsgNextBlockFailed ErrGetBlock
    | MsgSynced
    | MsgApplyBlocks (NonEmpty BlockHeader)
    deriving (Show, Eq)

instance ToText FollowLog where
    toText = \case
        MsgFollowAction action -> case action of
            ExitWith e -> "Failed to roll forward: " <> T.pack e
            _ -> T.pack $ "Follower says " <> show action
        MsgFatalUnhandledException err ->
            "Non-recoverable error following the chain: " <> err
        MsgUnhandledException err ->
            "Recoverable error following the chain: " <> err
        MsgNextBlockFailed e ->
            T.pack $ "Failed to get next blocks: " <> show e
        MsgSynced ->
            "In sync with the node."
        MsgApplyBlocks hdrs ->
            let (slFst, slLst) =
                    ( slotId $ NE.head hdrs
                    , slotId $ NE.last hdrs
                    )
            in mconcat
                [ "Applying blocks [", pretty slFst, " ... ", pretty slLst, "]" ]

instance DefinePrivacyAnnotation FollowLog
instance DefineSeverity FollowLog where
    defineSeverity = \case
        MsgFollowAction (ExitWith _) -> Error
        MsgFollowAction _ -> Debug
        MsgFatalUnhandledException _ -> Error
        MsgUnhandledException _ -> Error
        MsgNextBlockFailed _ -> Warning
        MsgSynced -> Debug
        MsgApplyBlocks _ -> Info
