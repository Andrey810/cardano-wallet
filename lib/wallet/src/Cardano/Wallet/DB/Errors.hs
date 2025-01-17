{-# LANGUAGE DataKinds #-}

module Cardano.Wallet.DB.Errors where

import Prelude

import Cardano.Wallet.Primitive.Types
    ( WalletId (..) )
import Cardano.Wallet.Primitive.Types.Hash
    ( Hash )
import Control.Exception
    ( Exception )

-- | Can't read the database file because it's in a bad format
-- (corrupted, too old, …)
data ErrBadFormat
    = ErrBadFormatAddressPrologue
    | ErrBadFormatCheckpoints
    deriving (Eq,Show)

instance Exception ErrBadFormat

-- | Can't add a transaction to the local tx submission pool.
data ErrPutLocalTxSubmission
    = ErrPutLocalTxSubmissionNoSuchWallet ErrNoSuchWallet
    | ErrPutLocalTxSubmissionNoSuchTransaction ErrNoSuchTransaction
    deriving (Eq, Show)

-- | Can't remove pending or expired transaction.
data ErrRemoveTx
    = ErrRemoveTxNoSuchWallet ErrNoSuchWallet
    | ErrRemoveTxNoSuchTransaction ErrNoSuchTransaction
    | ErrRemoveTxAlreadyInLedger (Hash "Tx")
    deriving (Eq, Show)

-- | Indicates that the specified transaction hash is not found in the
-- transaction history of the given wallet.
data ErrNoSuchTransaction
    = ErrNoSuchTransaction WalletId (Hash "Tx")
    deriving (Eq, Show)

-- | Forbidden operation was executed on an already existing wallet
newtype ErrWalletAlreadyExists
    = ErrWalletAlreadyExists WalletId -- Wallet already exists in db
    deriving (Eq, Show)

-- | Can't perform given operation because there's no wallet
newtype ErrNoSuchWallet
    = ErrNoSuchWallet WalletId -- Wallet is gone or doesn't exist yet
    deriving (Eq, Show)
