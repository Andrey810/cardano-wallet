{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Cardano.Wallet.Api.TypesSpec (spec) where

import Prelude hiding
    ( id )

import Cardano.Address.Script
    ( KeyHash (..), Script (..), ValidationLevel (..) )
import Cardano.Mnemonic
    ( CheckSumBits
    , ConsistentEntropy
    , Entropy
    , EntropySize
    , MnemonicException (..)
    , SomeMnemonic (..)
    , ValidChecksumSize
    , ValidEntropySize
    , entropyToMnemonic
    , mkEntropy
    )
import Cardano.Wallet.Api
    ( Api )
import Cardano.Wallet.Api.Types
    ( AccountPostData (..)
    , AddressAmount (..)
    , AnyAddress (..)
    , ApiAccountKey (..)
    , ApiAccountPublicKey (..)
    , ApiAddress (..)
    , ApiAddressData (..)
    , ApiAddressDataPayload (..)
    , ApiAddressInspect (..)
    , ApiAsset (..)
    , ApiBlockInfo (..)
    , ApiBlockReference (..)
    , ApiByronWallet (..)
    , ApiByronWalletBalance (..)
    , ApiCertificate (..)
    , ApiCoinSelection (..)
    , ApiCoinSelectionChange (..)
    , ApiCoinSelectionInput (..)
    , ApiCoinSelectionOutput (..)
    , ApiCoinSelectionWithdrawal (..)
    , ApiCredential (..)
    , ApiDelegationAction (..)
    , ApiEpochInfo (..)
    , ApiEra (..)
    , ApiEraInfo (..)
    , ApiErrorCode (..)
    , ApiFee (..)
    , ApiHealthCheck (..)
    , ApiMaintenanceAction (..)
    , ApiMaintenanceActionPostData (..)
    , ApiMnemonicT (..)
    , ApiNetworkClock (..)
    , ApiNetworkInformation (..)
    , ApiNetworkParameters (..)
    , ApiNtpStatus (..)
    , ApiPostAccountKeyData
    , ApiPostRandomAddressData
    , ApiPutAddressesData (..)
    , ApiRawMetadata (..)
    , ApiSelectCoinsAction (..)
    , ApiSelectCoinsData (..)
    , ApiSelectCoinsPayments (..)
    , ApiSlotId (..)
    , ApiSlotReference (..)
    , ApiStakePool (..)
    , ApiStakePoolFlag (..)
    , ApiStakePoolMetrics (..)
    , ApiT (..)
    , ApiTransaction (..)
    , ApiTxId (..)
    , ApiTxInput (..)
    , ApiTxMetadata (..)
    , ApiUtxoStatistics (..)
    , ApiVerificationKey (..)
    , ApiWallet (..)
    , ApiWalletAssetsBalance (..)
    , ApiWalletBalance (..)
    , ApiWalletDelegation (..)
    , ApiWalletDelegationNext (..)
    , ApiWalletDelegationStatus (..)
    , ApiWalletDiscovery (..)
    , ApiWalletMigrationInfo (..)
    , ApiWalletMigrationPostData (..)
    , ApiWalletPassphrase (..)
    , ApiWalletPassphraseInfo (..)
    , ApiWalletSignData (..)
    , ApiWithdrawal (..)
    , ApiWithdrawalPostData (..)
    , ByronWalletFromXPrvPostData (..)
    , ByronWalletPostData (..)
    , ByronWalletPutPassphraseData (..)
    , DecodeAddress (..)
    , DecodeStakeAddress (..)
    , EncodeAddress (..)
    , EncodeStakeAddress (..)
    , HealthCheckSMASH (..)
    , Iso8601Time (..)
    , NtpSyncingStatus (..)
    , PostExternalTransactionData (..)
    , PostTransactionData (..)
    , PostTransactionFeeData (..)
    , SettingsPutData (..)
    , SomeByronWalletPostData (..)
    , WalletOrAccountPostData (..)
    , WalletPostData (..)
    , WalletPutData (..)
    , WalletPutPassphraseData (..)
    , toApiAsset
    )
import Cardano.Wallet.Gen
    ( genMnemonic
    , genNatural
    , genPercentage
    , genScript
    , genTxMetadata
    , shrinkPercentage
    , shrinkTxMetadata
    )
import Cardano.Wallet.Primitive.AddressDerivation
    ( DerivationIndex (..)
    , DerivationType (..)
    , HardDerivation (..)
    , Index (..)
    , NetworkDiscriminant (..)
    , Passphrase (..)
    , PassphraseMaxLength (..)
    , PassphraseMinLength (..)
    , Role (..)
    , WalletKey (..)
    , passphraseMaxLength
    , passphraseMinLength
    )
import Cardano.Wallet.Primitive.AddressDerivation.Shelley
    ( ShelleyKey (..), generateKeyFromSeed )
import Cardano.Wallet.Primitive.AddressDerivationSpec
    ()
import Cardano.Wallet.Primitive.AddressDiscovery.Sequential
    ( AddressPoolGap, getAddressPoolGap )
import Cardano.Wallet.Primitive.SyncProgress
    ( SyncProgress (..) )
import Cardano.Wallet.Primitive.Types
    ( EpochNo (..)
    , PoolId (..)
    , PoolMetadataGCStatus (..)
    , PoolMetadataSource
    , PoolOwner (..)
    , Settings
    , SlotId (..)
    , SlotInEpoch (..)
    , SlotNo (..)
    , SmashServer
    , SortOrder (..)
    , StakePoolMetadata (..)
    , StakePoolTicker
    , StartTime (..)
    , WalletDelegationStatus (..)
    , WalletId (..)
    , WalletName (..)
    , walletNameMaxLength
    , walletNameMinLength
    )
import Cardano.Wallet.Primitive.Types.Address
    ( Address (..), AddressState (..) )
import Cardano.Wallet.Primitive.Types.Coin
    ( Coin (..) )
import Cardano.Wallet.Primitive.Types.Coin.Gen
    ( genCoinLargePositive )
import Cardano.Wallet.Primitive.Types.Hash
    ( Hash (..) )
import Cardano.Wallet.Primitive.Types.RewardAccount
    ( RewardAccount (..) )
import Cardano.Wallet.Primitive.Types.TokenBundle
    ( AssetId (..), TokenBundle )
import Cardano.Wallet.Primitive.Types.TokenBundle.Gen
    ( genTokenBundleSmallRange, shrinkTokenBundleSmallRange )
import Cardano.Wallet.Primitive.Types.TokenMap
    ( TokenMap )
import Cardano.Wallet.Primitive.Types.TokenMap.Gen
    ( genAssetIdSmallRange, genTokenMapSmallRange, shrinkTokenMapSmallRange )
import Cardano.Wallet.Primitive.Types.TokenPolicy
    ( TokenFingerprint, mkTokenFingerprint )
import Cardano.Wallet.Primitive.Types.Tx
    ( Direction (..)
    , TxIn (..)
    , TxIn (..)
    , TxMetadata (..)
    , TxMetadata (..)
    , TxOut (..)
    , TxStatus (..)
    )
import Cardano.Wallet.Primitive.Types.UTxO
    ( HistogramBar (..)
    , UTxO (..)
    , UTxOStatistics (..)
    , computeUtxoStatistics
    , log10
    )
import Cardano.Wallet.Unsafe
    ( unsafeFromText, unsafeXPrv )
import Control.Lens
    ( at, (?~) )
import Control.Monad
    ( forM, forM_, replicateM )
import Control.Monad.IO.Class
    ( liftIO )
import Crypto.Hash
    ( hash )
import Data.Aeson
    ( FromJSON (..), Result (..), fromJSON, withObject, (.:?), (.=) )
import Data.Aeson.QQ
    ( aesonQQ )
import Data.Char
    ( toLower )
import Data.Data
    ( dataTypeConstrs, dataTypeOf, showConstr )
import Data.Either
    ( lefts )
import Data.FileEmbed
    ( embedFile, makeRelativeToProject )
import Data.Function
    ( (&) )
import Data.List
    ( foldl' )
import Data.List.NonEmpty
    ( NonEmpty (..) )
import Data.Maybe
    ( fromJust, fromMaybe )
import Data.OpenApi
    ( Definitions, NamedSchema (..), Schema, ToSchema (..) )
import Data.OpenApi.Declare
    ( Declare, declare, look )
import Data.Proxy
    ( Proxy (..) )
import Data.Quantity
    ( Percentage, Quantity (..) )
import Data.Text
    ( Text )
import Data.Text.Class
    ( FromText (..), TextDecodingError (..) )
import Data.Time.Clock
    ( NominalDiffTime )
import Data.Time.Clock.POSIX
    ( utcTimeToPOSIXSeconds )
import Data.Word
    ( Word32, Word8 )
import Data.Word.Odd
    ( Word31 )
import GHC.TypeLits
    ( KnownSymbol, natVal, symbolVal )
import Network.URI
    ( URI, parseURI )
import Numeric.Natural
    ( Natural )
import Servant
    ( (:<|>)
    , (:>)
    , Capture
    , Header'
    , JSON
    , PostNoContent
    , QueryFlag
    , QueryParam
    , ReqBody
    , StdMethod (..)
    , Verb
    )
import Servant.API.Verbs
    ( NoContentVerb )
import Servant.OpenApi.Test
    ( validateEveryToJSON, validateEveryToJSONWithPatternChecker )
import System.Environment
    ( lookupEnv )
import System.FilePath
    ( (</>) )
import Test.Hspec
    ( Spec, SpecWith, describe, it, shouldBe )
import Test.Hspec.Extra
    ( parallel )
import Test.QuickCheck
    ( Arbitrary (..)
    , Gen
    , InfiniteList (..)
    , applyArbitrary2
    , applyArbitrary3
    , arbitraryBoundedEnum
    , arbitraryPrintableChar
    , arbitrarySizedBoundedIntegral
    , choose
    , counterexample
    , elements
    , frequency
    , oneof
    , property
    , scale
    , shrinkIntegral
    , vector
    , vectorOf
    , (.&&.)
    , (===)
    )
import Test.QuickCheck.Arbitrary.Generic
    ( genericArbitrary, genericShrink )
import Test.QuickCheck.Extra
    ( reasonablySized )
import Test.Text.Roundtrip
    ( textRoundtrip )
import Test.Utils.Paths
    ( getTestData )
import Test.Utils.Roundtrip
    ( httpApiDataRoundtrip )
import Test.Utils.Time
    ( genUniformTime )
import Text.Regex.PCRE
    ( compBlank, execBlank, makeRegexOpts, matchTest )
import Web.HttpApiData
    ( FromHttpApiData (..) )

import qualified Cardano.Wallet.Api.Types as Api
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Types as Aeson
import qualified Data.ByteArray as BA
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B8
import qualified Data.HashMap.Strict as HM
import qualified Data.List.NonEmpty as NE
import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Yaml as Yaml
import qualified Prelude
import qualified Test.Utils.Roundtrip as Utils

spec :: Spec
spec = parallel $ do
    let jsonRoundtripAndGolden = Utils.jsonRoundtripAndGolden
            ($(getTestData) </> "Cardano" </> "Wallet" </> "Api")

    parallel $ describe
        "can perform roundtrip JSON serialization & deserialization, \
        \and match existing golden files" $ do
            jsonRoundtripAndGolden $ Proxy @AnyAddress
            jsonRoundtripAndGolden $ Proxy @ApiCredential
            jsonRoundtripAndGolden $ Proxy @ApiAddressData
            jsonRoundtripAndGolden $ Proxy @(ApiT DerivationIndex)
            jsonRoundtripAndGolden $ Proxy @ApiPostAccountKeyData
            jsonRoundtripAndGolden $ Proxy @ApiAccountKey
            jsonRoundtripAndGolden $ Proxy @ApiEpochInfo
            jsonRoundtripAndGolden $ Proxy @(ApiSelectCoinsData ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @(ApiCoinSelection ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @(ApiCoinSelectionChange ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @(ApiCoinSelectionInput ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @(ApiCoinSelectionOutput ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @(ApiCoinSelectionWithdrawal ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @ApiRawMetadata
            jsonRoundtripAndGolden $ Proxy @ApiBlockReference
            jsonRoundtripAndGolden $ Proxy @ApiSlotReference
            jsonRoundtripAndGolden $ Proxy @ApiDelegationAction
            jsonRoundtripAndGolden $ Proxy @ApiNetworkInformation
            jsonRoundtripAndGolden $ Proxy @ApiNetworkParameters
            jsonRoundtripAndGolden $ Proxy @ApiEraInfo
            jsonRoundtripAndGolden $ Proxy @ApiEra
            jsonRoundtripAndGolden $ Proxy @ApiNetworkClock
            jsonRoundtripAndGolden $ Proxy @ApiWalletDelegation
            jsonRoundtripAndGolden $ Proxy @ApiHealthCheck
            jsonRoundtripAndGolden $ Proxy @ApiWalletDelegationStatus
            jsonRoundtripAndGolden $ Proxy @ApiWalletDelegationNext
            jsonRoundtripAndGolden $ Proxy @(ApiT (Hash "Genesis"))
            jsonRoundtripAndGolden $ Proxy @ApiStakePool
            jsonRoundtripAndGolden $ Proxy @ApiStakePoolMetrics
            jsonRoundtripAndGolden $ Proxy @(AddressAmount (ApiT Address, Proxy ('Testnet 0)))
            jsonRoundtripAndGolden $ Proxy @(ApiTransaction ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @(ApiPutAddressesData ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @ApiWallet
            jsonRoundtripAndGolden $ Proxy @ApiByronWallet
            jsonRoundtripAndGolden $ Proxy @ApiByronWalletBalance
            jsonRoundtripAndGolden $ Proxy @ApiWalletMigrationInfo
            jsonRoundtripAndGolden $ Proxy @(ApiWalletMigrationPostData ('Testnet 0) "lenient")
            jsonRoundtripAndGolden $ Proxy @(ApiWalletMigrationPostData ('Testnet 0) "raw")
            jsonRoundtripAndGolden $ Proxy @ApiWalletPassphrase
            jsonRoundtripAndGolden $ Proxy @ApiUtxoStatistics
            jsonRoundtripAndGolden $ Proxy @ApiFee
            jsonRoundtripAndGolden $ Proxy @ApiStakePoolMetrics
            jsonRoundtripAndGolden $ Proxy @ApiTxId
            jsonRoundtripAndGolden $ Proxy @ApiVerificationKey
            jsonRoundtripAndGolden $ Proxy @(PostTransactionData ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @(PostTransactionFeeData ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @WalletPostData
            jsonRoundtripAndGolden $ Proxy @AccountPostData
            jsonRoundtripAndGolden $ Proxy @WalletOrAccountPostData
            jsonRoundtripAndGolden $ Proxy @SomeByronWalletPostData
            jsonRoundtripAndGolden $ Proxy @ByronWalletFromXPrvPostData
            jsonRoundtripAndGolden $ Proxy @WalletPutData
            jsonRoundtripAndGolden $ Proxy @SettingsPutData
            jsonRoundtripAndGolden $ Proxy @WalletPutPassphraseData
            jsonRoundtripAndGolden $ Proxy @ByronWalletPutPassphraseData
            jsonRoundtripAndGolden $ Proxy @(ApiT (Hash "Tx"))
            jsonRoundtripAndGolden $ Proxy @(ApiT (Passphrase "raw"))
            jsonRoundtripAndGolden $ Proxy @(ApiT (Passphrase "lenient"))
            jsonRoundtripAndGolden $ Proxy @(ApiT Address, Proxy ('Testnet 0))
            jsonRoundtripAndGolden $ Proxy @(ApiT AddressPoolGap)
            jsonRoundtripAndGolden $ Proxy @(ApiT Direction)
            jsonRoundtripAndGolden $ Proxy @(ApiT TxMetadata)
            jsonRoundtripAndGolden $ Proxy @(ApiT TxStatus)
            jsonRoundtripAndGolden $ Proxy @(ApiWalletBalance)
            jsonRoundtripAndGolden $ Proxy @(ApiT WalletId)
            jsonRoundtripAndGolden $ Proxy @(ApiT WalletName)
            jsonRoundtripAndGolden $ Proxy @ApiWalletPassphraseInfo
            jsonRoundtripAndGolden $ Proxy @(ApiT SyncProgress)
            jsonRoundtripAndGolden $ Proxy @(ApiT StakePoolMetadata)
            jsonRoundtripAndGolden $ Proxy @ApiPostRandomAddressData
            jsonRoundtripAndGolden $ Proxy @ApiTxMetadata
            jsonRoundtripAndGolden $ Proxy @ApiMaintenanceAction
            jsonRoundtripAndGolden $ Proxy @ApiMaintenanceActionPostData
            jsonRoundtripAndGolden $ Proxy @ApiAsset

    describe "Textual encoding" $ do
        describe "Can perform roundtrip textual encoding & decoding" $ do
            textRoundtrip $ Proxy @Iso8601Time
            textRoundtrip $ Proxy @SortOrder
            textRoundtrip $ Proxy @Coin
            textRoundtrip $ Proxy @TokenFingerprint

    describe "AddressAmount" $ do
        it "fromText \"22323\"" $
            let err =
                    "Parse error. " <>
                    "Expecting format \"<amount>@<address>\" but got \"22323\""
            in
                fromText @(AddressAmount Text) "22323"
                    === Left (TextDecodingError err)

    describe
        "can perform roundtrip HttpApiData serialization & deserialization" $ do
            httpApiDataRoundtrip $ Proxy @(ApiT WalletId)
            httpApiDataRoundtrip $ Proxy @(ApiT AddressState)
            httpApiDataRoundtrip $ Proxy @Iso8601Time
            httpApiDataRoundtrip $ Proxy @(ApiT SortOrder)

    describe
        "verify that every type used with JSON content type in a servant API \
        \has compatible ToJSON and ToSchema instances using validateToJSON." $ do
        let match regex sourc = matchTest
                (makeRegexOpts compBlank execBlank $ T.unpack regex)
                (T.unpack sourc)
        validateEveryToJSONWithPatternChecker
            match
            (Proxy :: Proxy (Api ('Testnet 0) ApiStakePool))
        -- NOTE See (ToSchema WalletOrAccountPostData)
        validateEveryToJSON
            (Proxy :: Proxy (
                ReqBody '[JSON] AccountPostData :> PostNoContent
              :<|>
                ReqBody '[JSON] WalletPostData  :> PostNoContent
            ))

    describe
        "verify that every path specified by the servant server matches an \
        \existing path in the specification" $
        validateEveryPath (Proxy :: Proxy (Api ('Testnet 0) ApiStakePool))

    parallel $ describe "verify JSON parsing failures too" $ do
        it "ApiT (Passphrase \"raw\") (too short)" $ do
            let minLength = passphraseMinLength (Proxy :: Proxy "raw")
            let msg = "Error in $: passphrase is too short: \
                    \expected at least " <> show minLength <> " characters"
            Aeson.parseEither parseJSON [aesonQQ|"patate"|]
                `shouldBe` (Left @String @(ApiT (Passphrase "raw")) msg)

        it "ApiT (Passphrase \"raw\") (too long)" $ do
            let maxLength = passphraseMaxLength (Proxy :: Proxy "raw")
            let msg = "Error in $: passphrase is too long: \
                    \expected at most " <> show maxLength <> " characters"
            Aeson.parseEither parseJSON [aesonQQ|
                #{replicate (2*maxLength) '*'}
            |] `shouldBe` (Left @String @(ApiT (Passphrase "raw")) msg)

        it "ApiT (Passphrase \"lenient\") (too long)" $ do
            let maxLength = passphraseMaxLength (Proxy :: Proxy "lenient")
            let msg = "Error in $: passphrase is too long: \
                    \expected at most " <> show maxLength <> " characters"
            Aeson.parseEither parseJSON [aesonQQ|
                #{replicate (2*maxLength) '*'}
            |] `shouldBe` (Left @String @(ApiT (Passphrase "lenient")) msg)

        it "ApiT WalletName (too short)" $ do
            let msg = "Error in $: name is too short: \
                    \expected at least " <> show walletNameMinLength <> " character"
            Aeson.parseEither parseJSON [aesonQQ|""|]
                `shouldBe` (Left @String @(ApiT WalletName) msg)

        it "ApiT WalletName (too long)" $ do
            let msg = "Error in $: name is too long: \
                    \expected at most " <> show walletNameMaxLength <> " characters"
            Aeson.parseEither parseJSON [aesonQQ|
                #{replicate (2*walletNameMaxLength) '*'}
            |] `shouldBe` (Left @String @(ApiT WalletName) msg)

        it "ApiMnemonicT '[12] (not enough words)" $ do
            let msg = "Error in $: Invalid number of words: 12 words\
                    \ are expected."
            Aeson.parseEither parseJSON [aesonQQ|
                ["toilet", "toilet", "toilet"]
            |] `shouldBe` (Left @String @(ApiMnemonicT '[12]) msg)


        it "ApiT DerivationIndex (too small)" $ do
            let message = unwords
                  [ "Error in $:"
                  , "A derivation index must be a natural number between"
                  , show (getIndex @'Soft minBound)
                  , "and"
                  , show (getIndex @'Soft maxBound)
                  , "with an optional 'H' suffix (e.g. '1815H' or '44')."
                  , "Indexes without suffixes are called 'Soft'"
                  , "Indexes with suffixes are called 'Hardened'."
                  ]

            let value = show $ pred $ toInteger $ getIndex @'Soft minBound
            Aeson.parseEither parseJSON [aesonQQ|#{value}|]
                `shouldBe` Left @String @(ApiT DerivationIndex) message

        it "ApiT DerivationIndex (too large)" $ do
            let message = unwords
                  [ "Error in $:"
                  , "A derivation index must be a natural number between"
                  , show (getIndex @'Soft minBound)
                  , "and"
                  , show (getIndex @'Soft maxBound)
                  , "with an optional 'H' suffix (e.g. '1815H' or '44')."
                  , "Indexes without suffixes are called 'Soft'"
                  , "Indexes with suffixes are called 'Hardened'."
                  ]

            let value = show $ succ $ toInteger $ getIndex @'Soft maxBound
            Aeson.parseEither parseJSON [aesonQQ|#{value}|]
                `shouldBe` Left @String @(ApiT DerivationIndex) message

        it "ApiT AddressPoolGap (too small)" $ do
            let msg = "Error in $: An address pool gap must be a natural number between "
                    <> show (getAddressPoolGap minBound)
                    <> " and "
                    <> show (getAddressPoolGap maxBound)
                    <> "."
            Aeson.parseEither parseJSON [aesonQQ|
                #{getAddressPoolGap minBound - 1}
            |] `shouldBe` (Left @String @(ApiT AddressPoolGap) msg)

        it "ApiT AddressPoolGap (too big)" $ do
            let msg = "Error in $: An address pool gap must be a natural number between "
                    <> show (getAddressPoolGap minBound)
                    <> " and "
                    <> show (getAddressPoolGap maxBound)
                    <> "."
            Aeson.parseEither parseJSON [aesonQQ|
                #{getAddressPoolGap maxBound + 1}
            |] `shouldBe` (Left @String @(ApiT AddressPoolGap) msg)

        it "ApiT AddressPoolGap (not a integer)" $ do
            let msg = "Error in $: parsing Integer failed, unexpected floating number\
                    \ 2.5"
            Aeson.parseEither parseJSON [aesonQQ|
                2.5
            |] `shouldBe` (Left @String @(ApiT AddressPoolGap) msg)

        it "ApiT (Hash \"Tx\")" $ do
            let msg = "Error in $: Invalid tx hash: \
                    \expecting a hex-encoded value that is 32 bytes in length."
            Aeson.parseEither parseJSON [aesonQQ|
                "-----"
            |] `shouldBe` (Left @String @(ApiT (Hash "Tx")) msg)

        it "ApiT WalletId" $ do
            let msg = "Error in $: wallet id should be a hex-encoded \
                    \string of 40 characters"
            Aeson.parseEither parseJSON [aesonQQ|
                "invalid-id"
            |] `shouldBe` (Left @String @(ApiT WalletId) msg)

        it "AddressAmount (too small)" $ do
            let msg = "Error in $.amount.quantity: \
                    \parsing AddressAmount failed, parsing Natural failed, \
                    \unexpected negative number -14"
            Aeson.parseEither parseJSON [aesonQQ|
                { "address": "<addr>"
                , "amount": {"unit":"lovelace","quantity":-14}
                }
            |] `shouldBe` (Left @String @(AddressAmount (ApiT Address, Proxy ('Testnet 0))) msg)

        it "AddressAmount (too big)" $ do
            let msg = "Error in $: parsing AddressAmount failed, \
                    \invalid coin value: value has to be lower \
                    \than or equal to " <> show (unCoin maxBound)
                    <> " lovelace."
            Aeson.parseEither parseJSON [aesonQQ|
                { "address": "<addr>"
                , "amount":
                    { "unit":"lovelace"
                    ,"quantity":#{unCoin maxBound + 1}
                    }
                }
            |] `shouldBe` (Left @String @(AddressAmount (ApiT Address, Proxy ('Testnet 0))) msg)

        it "ApiT PoolId" $ do
            let msg =
                    "Error in $: Invalid stake pool id: expecting a Bech32 \
                    \encoded value with human readable part of 'pool'."
            Aeson.parseEither parseJSON [aesonQQ|
                "invalid-id"
            |] `shouldBe` (Left @String @(ApiT PoolId) msg)

        it "ApiT PoolId" $ do
            let msg =
                    "Error in $: Invalid stake pool id: expecting a Bech32 \
                    \encoded value with human readable part of 'pool'."
            Aeson.parseEither parseJSON [aesonQQ|
                "4c43d68b21921034519c36d2475f5adba989bb4465ec"
            |] `shouldBe` (Left @String @(ApiT PoolId) msg)

        it "ApiT (Hash \"Genesis\")" $ do
            let msg = "Error in $: Invalid genesis hash: \
                    \expecting a hex-encoded value that is 32 bytes in length."
            Aeson.parseEither parseJSON [aesonQQ|
                "-----"
            |] `shouldBe` (Left @String @(ApiT (Hash "Genesis")) msg)

        describe "StakePoolMetadata" $ do
            let msg = "Error in $.ticker: stake pool ticker length must be \
                      \3-5 characters"

            let testInvalidTicker :: Text -> SpecWith ()
                testInvalidTicker txt =
                    it ("Invalid ticker length: " ++ show (T.length txt)) $ do
                        Aeson.parseEither parseJSON [aesonQQ|
                            {
                                "owner": "ed25519_pk1afhcpw2tg7nr2m3wr4x8jaa4dv7d09gnv27kwfxpjyvukwxs8qdqwg85xp",
                                "homepage": "https://12345",
                                "ticker": #{txt},
                                "pledge_address": "ed25519_pk15vz9yc5c3upgze8tg5kd7kkzxqgqfxk5a3kudp22hdg0l2za00sq2ufkk7",
                                "name": "invalid"
                            }
                        |] `shouldBe` (Left @String @(ApiT StakePoolMetadata) msg)

            forM_ ["too long", "sh", ""] testInvalidTicker

    describe "verify HttpApiData parsing failures too" $ do
        it "ApiT WalletId" $ do
            let msg = "wallet id should be a hex-encoded string of 40 characters"
            parseUrlPiece "invalid-id"
                `shouldBe` (Left @Text @(ApiT WalletId) msg)

        it "ApiT AddressState" $ do
            let msg = "Unable to decode the given text value.\
                    \ Please specify one of the following values: used, unused."
            parseUrlPiece "patate"
                `shouldBe` (Left @Text @(ApiT AddressState) msg)

    parallel $ describe "pointless tests to trigger coverage for record accessors" $ do
        it "ApiEpochInfo" $ property $ \x ->
            let
                x' = ApiEpochInfo
                    { epochNumber = epochNumber (x :: ApiEpochInfo)
                    , epochStartTime = epochStartTime (x :: ApiEpochInfo)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiSelectCoinsData" $ property $ \x ->
            let
                x' = ApiSelectCoinsPayments
                    { payments = payments (x :: ApiSelectCoinsPayments ('Testnet 0))
                    , withdrawal = withdrawal (x :: ApiSelectCoinsPayments ('Testnet 0))
                    , metadata = metadata (x :: ApiSelectCoinsPayments ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiCoinSelection" $ property $ \x ->
            let
                x' = ApiCoinSelection
                    { inputs = inputs
                        (x :: ApiCoinSelection ('Testnet 0))
                    , outputs = outputs
                        (x :: ApiCoinSelection ('Testnet 0))
                    , change = change
                        (x :: ApiCoinSelection ('Testnet 0))
                    , withdrawals = withdrawals
                        (x :: ApiCoinSelection ('Testnet 0))
                    , certificates = certificates
                        (x :: ApiCoinSelection ('Testnet 0))
                    , deposits = deposits
                        (x :: ApiCoinSelection ('Testnet 0))
                    , metadata = metadata
                        (x :: ApiCoinSelection ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiCoinSelectionChange" $ property $ \x ->
            let
                x' = ApiCoinSelectionChange
                    { address = address
                        (x :: ApiCoinSelectionChange ('Testnet 0))
                    , amount = amount
                        (x :: ApiCoinSelectionChange ('Testnet 0))
                    , assets = assets
                        (x :: ApiCoinSelectionChange ('Testnet 0))
                    , derivationPath = derivationPath
                        (x :: ApiCoinSelectionChange ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiCoinSelectionInput" $ property $ \x ->
            let
                x' = ApiCoinSelectionInput
                    { id = id
                        (x :: ApiCoinSelectionInput ('Testnet 0))
                    , index = index
                        (x :: ApiCoinSelectionInput ('Testnet 0))
                    , address = address
                        (x :: ApiCoinSelectionInput ('Testnet 0))
                    , amount = amount
                        (x :: ApiCoinSelectionInput ('Testnet 0))
                    , assets = assets
                        (x :: ApiCoinSelectionInput ('Testnet 0))
                    , derivationPath = derivationPath
                        (x :: ApiCoinSelectionInput ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiCoinSelectionOutput" $ property $ \x ->
            let
                x' = ApiCoinSelectionOutput
                    { address = address
                        (x :: ApiCoinSelectionOutput ('Testnet 0))
                    , amount = amount
                        (x :: ApiCoinSelectionOutput ('Testnet 0))
                    , assets = assets
                        (x :: ApiCoinSelectionOutput ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiWallet" $ property $ \x ->
            let
                x' = ApiWallet
                    { id = id (x :: ApiWallet)
                    , addressPoolGap = addressPoolGap (x :: ApiWallet)
                    , balance = balance (x :: ApiWallet)
                    , assets = assets (x :: ApiWallet)
                    , delegation = delegation (x :: ApiWallet)
                    , name = name (x :: ApiWallet)
                    , passphrase = passphrase (x :: ApiWallet)
                    , state = state (x :: ApiWallet)
                    , tip = tip (x :: ApiWallet)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiByronWallet" $ property $ \x ->
            let
                x' = ApiByronWallet
                    { id = id (x :: ApiByronWallet)
                    , balance = balance (x :: ApiByronWallet)
                    , assets = assets (x :: ApiByronWallet)
                    , name = name (x :: ApiByronWallet)
                    , passphrase = passphrase (x :: ApiByronWallet)
                    , state = state (x :: ApiByronWallet)
                    , tip = tip (x :: ApiByronWallet)
                    , discovery = discovery (x :: ApiByronWallet)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiWalletMigrationInfo" $ property $ \x ->
            let
                x' = ApiWalletMigrationInfo
                    { migrationCost =
                        migrationCost (x :: ApiWalletMigrationInfo)
                    , leftovers =
                        leftovers (x :: ApiWalletMigrationInfo)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiWalletMigrationPostData lenient" $ property $ \x ->
            let
                x' = ApiWalletMigrationPostData
                    { passphrase =
                        passphrase (x :: ApiWalletMigrationPostData ('Testnet 0) "lenient")
                    , addresses =
                        addresses (x :: ApiWalletMigrationPostData ('Testnet 0) "lenient")
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiWalletMigrationPostData raw" $ property $ \x ->
            let
                x' = ApiWalletMigrationPostData
                    { passphrase =
                        passphrase (x :: ApiWalletMigrationPostData ('Testnet 0) "raw")
                    , addresses =
                        addresses (x :: ApiWalletMigrationPostData ('Testnet 0) "raw")
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiWalletPassphrase" $ property $ \x ->
            let
                x' = ApiWalletPassphrase
                    { passphrase =
                        passphrase (x :: ApiWalletPassphrase)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiFee" $ property $ \x ->
            let
                x' = ApiFee
                    { estimatedMin = estimatedMin (x :: ApiFee)
                    , estimatedMax = estimatedMax (x :: ApiFee)
                    , minimumCoins = minimumCoins (x :: ApiFee)
                    , deposit = deposit (x :: ApiFee)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiTxId" $ property $ \x ->
            let
                x' = ApiTxId
                    { id = id (x :: ApiTxId)
                    }
            in
                x' === x .&&. show x' === show x
        it "WalletPostData" $ property $ \x ->
            let
                x' = WalletPostData
                    { addressPoolGap = addressPoolGap (x :: WalletPostData)
                    , mnemonicSentence = mnemonicSentence (x :: WalletPostData)
                    , mnemonicSecondFactor = mnemonicSecondFactor (x :: WalletPostData)
                    , name = name (x :: WalletPostData)
                    , passphrase = passphrase (x :: WalletPostData)
                    }
            in
                x' === x .&&. show x' === show x
        it "WalletPutData" $ property $ \x ->
            let
                x' = WalletPutData
                    { name = name (x :: WalletPutData)
                    }
            in
                x' === x .&&. show x' === show x
        it "SettingsPutData" $ property $ \x ->
            let
                x' = SettingsPutData
                    { settings = settings (x :: SettingsPutData)
                    }
            in
                x' === x .&&. show x' === show x
        it "WalletPutPassphraseData" $ property $ \x ->
            let
                x' = WalletPutPassphraseData
                    { oldPassphrase = oldPassphrase (x :: WalletPutPassphraseData)
                    , newPassphrase = newPassphrase (x :: WalletPutPassphraseData)
                    }
            in
                x' === x .&&. show x' === show x
        it "ByronWalletPutPassphraseData" $ property $ \x ->
            let
                x' = ByronWalletPutPassphraseData
                    { oldPassphrase = oldPassphrase (x :: ByronWalletPutPassphraseData)
                    , newPassphrase = newPassphrase (x :: ByronWalletPutPassphraseData)
                    }
            in
                x' === x .&&. show x' === show x
        it "PostTransactionData" $ property $ \x ->
            let
                x' = PostTransactionData
                    { payments = payments (x :: PostTransactionData ('Testnet 0))
                    , passphrase = passphrase (x :: PostTransactionData ('Testnet 0))
                    , withdrawal = withdrawal (x :: PostTransactionData ('Testnet 0))
                    , metadata = metadata (x :: PostTransactionData ('Testnet 0))
                    , timeToLive = timeToLive (x :: PostTransactionData ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "PostTransactionFeeData" $ property $ \x ->
            let
                x' = PostTransactionFeeData
                    { payments = payments (x :: PostTransactionFeeData ('Testnet 0))
                    , withdrawal = withdrawal (x :: PostTransactionFeeData ('Testnet 0))
                    , metadata = metadata (x :: PostTransactionFeeData ('Testnet 0))
                    , timeToLive = timeToLive (x :: PostTransactionFeeData ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "PostExternalTransactionData" $ property $ \x ->
            let
                x' = PostExternalTransactionData
                    { payload = payload (x :: PostExternalTransactionData)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiTransaction" $ property $ \x ->
            let
                x' = ApiTransaction
                    { id = id (x :: ApiTransaction ('Testnet 0))
                    , amount = amount (x :: ApiTransaction ('Testnet 0))
                    , fee = fee (x :: ApiTransaction ('Testnet 0))
                    , deposit = deposit (x :: ApiTransaction ('Testnet 0))
                    , insertedAt = insertedAt (x :: ApiTransaction ('Testnet 0))
                    , pendingSince = pendingSince (x :: ApiTransaction ('Testnet 0))
                    , expiresAt = expiresAt (x :: ApiTransaction ('Testnet 0))
                    , depth = depth (x :: ApiTransaction ('Testnet 0))
                    , direction = direction (x :: ApiTransaction ('Testnet 0))
                    , inputs = inputs (x :: ApiTransaction ('Testnet 0))
                    , outputs = outputs (x :: ApiTransaction ('Testnet 0))
                    , status = status (x :: ApiTransaction ('Testnet 0))
                    , withdrawals = withdrawals (x :: ApiTransaction ('Testnet 0))
                    , mint = mint (x :: ApiTransaction ('Testnet 0))
                    , metadata = metadata (x :: ApiTransaction ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiPutAddressesData" $ property $ \x ->
            let
                x' = ApiPutAddressesData
                    { addresses = addresses (x :: ApiPutAddressesData ('Testnet 0))
                    }
            in
                x' === x .&&. show x' === show x
        it "AddressAmount" $ property $ \x ->
            let
                x' = AddressAmount
                    { address = address (x :: AddressAmount (ApiT Address, Proxy ('Testnet 0)))
                    , amount = amount (x :: AddressAmount (ApiT Address, Proxy ('Testnet 0)))
                    , assets = assets (x :: AddressAmount (ApiT Address, Proxy ('Testnet 0)))
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiBlockReference" $ property $ \x ->
            let
                x' = ApiBlockReference
                    { absoluteSlotNumber = absoluteSlotNumber (x :: ApiBlockReference)
                    , slotId = slotId (x :: ApiBlockReference)
                    , time = time (x :: ApiBlockReference)
                    , block = block (x :: ApiBlockReference)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiSlotReference" $ property $ \x ->
            let
                x' = ApiSlotReference
                    { absoluteSlotNumber = absoluteSlotNumber (x :: ApiSlotReference)
                    , slotId = slotId (x :: ApiSlotReference)
                    , time = time (x :: ApiSlotReference)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiNetworkInformation" $ property $ \x ->
            let
                x' = ApiNetworkInformation
                    { syncProgress = syncProgress (x :: ApiNetworkInformation)
                    , nextEpoch = nextEpoch (x :: ApiNetworkInformation)
                    , nodeTip = nodeTip (x :: ApiNetworkInformation)
                    , networkTip = networkTip (x :: ApiNetworkInformation)
                    , nodeEra = nodeEra (x :: ApiNetworkInformation)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiNetworkClock" $ property $ \x ->
            let
                x' = ApiNetworkClock
                    { ntpStatus = ntpStatus (x :: ApiNetworkClock)
                    }
            in
                x' === x .&&. show x' === show x
        it "ApiNetworkParameters" $ property $ \x ->
            let x' = ApiNetworkParameters
                    { genesisBlockHash =
                        genesisBlockHash (x :: ApiNetworkParameters)
                    , blockchainStartTime =
                        blockchainStartTime (x :: ApiNetworkParameters)
                    , slotLength =
                        slotLength (x :: ApiNetworkParameters)
                    , epochLength =
                        epochLength (x :: ApiNetworkParameters)
                    , securityParameter =
                        securityParameter (x :: ApiNetworkParameters)
                    , activeSlotCoefficient =
                        activeSlotCoefficient (x :: ApiNetworkParameters)
                    , decentralizationLevel =
                        decentralizationLevel (x :: ApiNetworkParameters)
                    , desiredPoolNumber =
                        desiredPoolNumber (x :: ApiNetworkParameters)
                    , minimumUtxoValue =
                        minimumUtxoValue (x :: ApiNetworkParameters)
                    , eras =
                        eras (x :: ApiNetworkParameters)
                    }
            in
            x' === x .&&. show x' === show x

    describe "Api Errors" $ do
        it "Every constructor from ApiErrorCode has a corresponding type in the schema" $
            let res = fromJSON @SchemaApiErrorCode specification
                errStr = case res of
                    Error s -> s
                    _ -> ""
            in counterexample errStr $ res == Success SchemaApiErrorCode

{-------------------------------------------------------------------------------
                              Error type Encoding
-------------------------------------------------------------------------------}

-- | We use this empty data type to define a custom
-- JSON instance that checks ApiErrorCode has corresponding
-- constructors in the schema file.
data SchemaApiErrorCode = SchemaApiErrorCode
    deriving (Show, Eq)

instance FromJSON SchemaApiErrorCode where
    parseJSON = withObject "SchemaApiErrorCode" $ \o -> do
        vals <- forM (fmap showConstr $ dataTypeConstrs $ dataTypeOf NoSuchWallet)
            $ \n -> do
                (r :: Maybe Yaml.Value) <- o .:? T.pack (toSchemaName n)
                pure $ maybe (Left n) Right r
        case lefts vals of
            [] -> pure SchemaApiErrorCode
            xs -> fail ("Missing ApiErrorCode constructors for: "
                <> show xs
                <> "\nEach of these need a corresponding swagger type of the form: "
                <> "x-errConstructorName")
      where
        toSchemaName :: String -> String
        toSchemaName [] = []
        toSchemaName xs = "x-err" <> xs

{-------------------------------------------------------------------------------
                              Address Encoding
-------------------------------------------------------------------------------}

-- Dummy instances
instance EncodeAddress ('Testnet 0) where
    encodeAddress = const "<addr>"

instance DecodeAddress ('Testnet 0) where
    decodeAddress "<addr>" = Right $ Address "<addr>"
    decodeAddress _ = Left $ TextDecodingError "invalid address"

-- Dummy instances
instance EncodeStakeAddress ('Testnet 0) where
    encodeStakeAddress = const "<stake-addr>"

instance DecodeStakeAddress ('Testnet 0) where
    decodeStakeAddress "<stake-addr>" = Right $ RewardAccount "<stake-addr>"
    decodeStakeAddress _ = Left $ TextDecodingError "invalid stake address"


{-------------------------------------------------------------------------------
                              Arbitrary Instances
-------------------------------------------------------------------------------}

instance Arbitrary (Proxy (n :: NetworkDiscriminant)) where
    shrink _ = []
    arbitrary = pure (Proxy @n)

instance Arbitrary (ApiAddress t) where
    shrink _ = []
    arbitrary = ApiAddress
        <$> fmap (, Proxy @t) arbitrary
        <*> arbitrary

instance Arbitrary ApiEpochInfo where
    arbitrary = ApiEpochInfo <$> arbitrary <*> genUniformTime
    shrink _ = []

instance Arbitrary (Script KeyHash) where
    arbitrary = do
        keyHashes <- vectorOf 10 arbitrary
        genScript keyHashes

instance Arbitrary KeyHash where
    arbitrary = KeyHash . BS.pack <$> vectorOf 28 arbitrary

instance Arbitrary ApiCredential where
    arbitrary = do
        pubKey <- BS.pack <$> replicateM 32 arbitrary
        oneof [ pure $ CredentialPubKey pubKey, CredentialScript <$> arbitrary ]

instance Arbitrary ValidationLevel where
    arbitrary =
        elements [RequiredValidation, RecommendedValidation]

instance Arbitrary ApiAddressData where
    arbitrary = do
        validation' <- oneof [pure Nothing, Just <$> arbitrary]
        credential1 <- arbitrary
        credential2 <- arbitrary
        addr <- elements
            [ AddrEnterprise credential1
            , AddrRewardAccount credential2
            , AddrBase credential1 credential2
            ]
        pure $ ApiAddressData addr validation'

instance Arbitrary AnyAddress where
    arbitrary = do
        payload' <- BS.pack <$> replicateM 32 arbitrary
        network' <- choose (0,1)
        addrType <- arbitraryBoundedEnum
        pure $ AnyAddress payload' addrType network'

instance Arbitrary (ApiSelectCoinsPayments n) where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiDelegationAction where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiSelectCoinsAction where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (ApiSelectCoinsData n) where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiCertificate where
    arbitrary =
        oneof [ JoinPool <$> arbitraryRewardAccountPath <*> arbitrary
            , QuitPool <$> arbitraryRewardAccountPath
            , RegisterRewardAccount <$> arbitraryRewardAccountPath
            ]
      where
        arbitraryRewardAccountPath :: Gen (NonEmpty (ApiT DerivationIndex))
        arbitraryRewardAccountPath = NE.fromList <$> vectorOf 5 arbitrary
    shrink = genericShrink

instance Arbitrary (ApiCoinSelection n) where
    arbitrary = ApiCoinSelection
        <$> reasonablySized arbitrary
        <*> reasonablySized arbitrary
        <*> reasonablySized arbitrary
        <*> reasonablySized arbitrary
        <*> reasonablySized arbitrary
        <*> reasonablySized arbitrary
        <*> arbitrary
    shrink = genericShrink

instance Arbitrary (ApiCoinSelectionChange n) where
    arbitrary = ApiCoinSelectionChange
        <$> fmap (, Proxy @n) arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary
    shrink _ = []

instance Arbitrary (ApiCoinSelectionInput n) where
    arbitrary = ApiCoinSelectionInput
        <$> arbitrary
        <*> arbitrary
        <*> fmap (, Proxy @n) arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary
    shrink _ = []

instance Arbitrary (ApiCoinSelectionOutput n) where
    arbitrary = applyArbitrary3 ApiCoinSelectionOutput
    shrink _ = []

instance Arbitrary (ApiCoinSelectionWithdrawal n) where
    arbitrary = ApiCoinSelectionWithdrawal
        <$> fmap (, Proxy @n) arbitrary
        <*> reasonablySized arbitrary
        <*> arbitrary

instance Arbitrary ApiRawMetadata where
    arbitrary = ApiRawMetadata . BS.pack <$> (choose(1, 10) >>= vector)

instance Arbitrary AddressState where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary Address where
    arbitrary = pure $ Address "<addr>"

instance Arbitrary (Quantity "lovelace" Natural) where
    shrink (Quantity 0) = []
    shrink _ = [Quantity 0]
    arbitrary = Quantity . fromIntegral <$> (arbitrary @Word8)

instance Arbitrary (Quantity "percent" Percentage) where
    shrink (Quantity p) = Quantity <$> shrinkPercentage p
    arbitrary = Quantity <$> genPercentage

instance Arbitrary ApiWallet where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiByronWallet where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiWalletDiscovery where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiByronWalletBalance where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiWalletMigrationInfo where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (Passphrase purpose) =>
         Arbitrary (ApiWalletMigrationPostData n purpose) where
    arbitrary = do
        n <- choose (1,255)
        pwd <- arbitrary
        addr <- vector n
        pure $ ApiWalletMigrationPostData pwd ((, Proxy @n) <$> addr)

instance Arbitrary ApiWalletPassphrase where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiFee where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiTxId where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary AddressPoolGap where
    arbitrary = arbitraryBoundedEnum

instance Arbitrary NominalDiffTime where
    arbitrary = fmap utcTimeToPOSIXSeconds genUniformTime

instance Arbitrary Iso8601Time where
    arbitrary = Iso8601Time <$> genUniformTime

instance Arbitrary PoolMetadataGCStatus where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary SortOrder where
    arbitrary = arbitraryBoundedEnum
    shrink = genericShrink

instance Arbitrary WalletOrAccountPostData where
    arbitrary = do
        let walletPostDataGen = arbitrary :: Gen WalletPostData
        let accountPostDataGen = arbitrary :: Gen AccountPostData
        oneof [ WalletOrAccountPostData . Left <$> walletPostDataGen
              , WalletOrAccountPostData . Right <$> accountPostDataGen ]

instance Arbitrary AccountPostData where
    arbitrary = do
        wName <- ApiT <$> arbitrary
        seed <- SomeMnemonic <$> genMnemonic @15
        let rootXPrv = generateKeyFromSeed (seed, Nothing) mempty
        let accXPub = publicKey $ deriveAccountPrivateKey mempty rootXPrv minBound
        pure $ AccountPostData wName (ApiAccountPublicKey $ ApiT $ getKey accXPub) Nothing

instance Arbitrary WalletPostData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ByronWalletFromXPrvPostData where
    arbitrary = do
        n <- arbitrary
        rootXPrv <- ApiT . unsafeXPrv . BS.pack <$> vector 128
        bytesNumber <- choose (64,100)
        h <- ApiT . Hash . B8.pack <$> replicateM bytesNumber arbitrary
        pure $ ByronWalletFromXPrvPostData n rootXPrv h

instance Arbitrary SomeByronWalletPostData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (ByronWalletPostData '[12]) where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (ByronWalletPostData '[15]) where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (ByronWalletPostData '[12,15,18,21,24]) where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary WalletPutData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary PoolMetadataSource where
    shrink = genericShrink
    arbitrary = genericArbitrary

instance Arbitrary SmashServer where
    shrink = genericShrink
    arbitrary = genericArbitrary

instance Arbitrary URI where
    arbitrary = elements
        [fromJust (parseURI "https://my.little.friend")
        ,fromJust (parseURI "http://its-friday.com:8000")]

instance Arbitrary Settings where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary SettingsPutData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary WalletPutPassphraseData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ByronWalletPutPassphraseData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiWalletBalance where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiWalletAssetsBalance where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary WalletDelegationStatus where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiWalletDelegationStatus where
    arbitrary = genericArbitrary

instance Arbitrary ApiWalletDelegationNext where
    arbitrary = oneof
        [ ApiWalletDelegationNext Api.Delegating
            <$> fmap Just arbitrary
            <*> fmap Just arbitrary
        , ApiWalletDelegationNext Api.NotDelegating
            Nothing . Just <$> arbitrary
        ]

instance Arbitrary (Passphrase "lenient") where
    arbitrary = do
        n <- choose (passphraseMinLength p, passphraseMaxLength p)
        bytes <- T.encodeUtf8 . T.pack <$> replicateM n arbitraryPrintableChar
        return $ Passphrase $ BA.convert bytes
      where p = Proxy :: Proxy "lenient"

    shrink (Passphrase bytes)
        | BA.length bytes <= passphraseMinLength p = []
        | otherwise =
            [ Passphrase
            $ BA.convert
            $ B8.take (passphraseMinLength p)
            $ BA.convert bytes
            ]
      where p = Proxy :: Proxy "lenient"

instance Arbitrary ApiWalletDelegation where
    arbitrary = ApiWalletDelegation
        <$> fmap (\x -> x { changesAt = Nothing }) arbitrary
        <*> oneof [ vector i | i <- [0..2 ] ]

instance Arbitrary PoolId where
    arbitrary = do
        InfiniteList bytes _ <- arbitrary
        return $ PoolId $ BS.pack $ take 28 bytes

instance Arbitrary ApiStakePool where
    arbitrary = ApiStakePool
        <$> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary

instance Arbitrary ApiStakePoolMetrics where
    arbitrary = ApiStakePoolMetrics
        <$> (Quantity . fromIntegral <$> choose (1::Integer, 1_000_000_000_000))
        <*> arbitrary
        <*> (choose (0.0, 5.0))
        <*> (Quantity . fromIntegral <$> choose (1::Integer, 22_600_000))

instance Arbitrary ApiStakePoolFlag where
    shrink = genericShrink
    arbitrary = genericArbitrary

instance Arbitrary StakePoolMetadata where
    arbitrary = StakePoolMetadata
        <$> arbitrary
        <*> arbitraryText 50
        <*> arbitraryMaybeText 255
        <*> arbitraryText 100
      where
        arbitraryText maxLen = do
            len <- choose (1, maxLen)
            T.pack <$> vector len
        arbitraryMaybeText maxLen = frequency
            [ (9, Just <$> arbitraryText maxLen)
            , (1, pure Nothing) ]

instance Arbitrary StakePoolTicker where
    arbitrary = unsafeFromText . T.pack <$> do
        len <- choose (3, 5)
        replicateM len arbitrary

instance Arbitrary ApiWalletSignData where
    arbitrary = ApiWalletSignData <$> arbitrary <*> arbitrary
    shrink = genericShrink

instance Arbitrary PoolOwner where
    arbitrary = PoolOwner . BS.pack <$> vector 32

instance Arbitrary WalletId where
    arbitrary = do
        bytes <- BS.pack <$> replicateM 16 arbitrary
        return $ WalletId (hash bytes)

instance Arbitrary WalletName where
    arbitrary = do
        nameLength <- choose (walletNameMinLength, walletNameMaxLength)
        WalletName . T.pack <$> replicateM nameLength arbitraryPrintableChar
    shrink (WalletName t)
        | T.length t <= walletNameMinLength = []
        | otherwise = [WalletName $ T.take walletNameMinLength t]

instance Arbitrary ApiWalletPassphraseInfo where
    arbitrary = ApiWalletPassphraseInfo <$> genUniformTime

instance Arbitrary ApiMaintenanceAction where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiMaintenanceActionPostData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary SyncProgress where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary a => Arbitrary (ApiT a) where
    arbitrary = ApiT <$> arbitrary
    shrink = fmap ApiT . shrink . getApiT

instance Arbitrary a => Arbitrary (NonEmpty a) where
    arbitrary = genericArbitrary
    shrink = genericShrink

-- | The initial seed has to be vector or length multiple of 4 bytes and shorter
-- than 64 bytes. Note that this is good for testing or examples, but probably
-- not for generating truly random Mnemonic words.
instance
    ( ValidEntropySize n
    , ValidChecksumSize n csz
    ) => Arbitrary (Entropy n) where
    arbitrary =
        let
            size = fromIntegral $ natVal @n Proxy
            entropy =
                mkEntropy  @n . BA.convert . B8.pack <$> vector (size `quot` 8)
        in
            either (error . show . UnexpectedEntropyError) Prelude.id <$> entropy

instance {-# OVERLAPS #-}
    ( n ~ EntropySize mw
    , csz ~ CheckSumBits n
    , ConsistentEntropy n mw csz
    )
    => Arbitrary (ApiMnemonicT (mw ': '[]))
  where
    arbitrary = do
        ent <- arbitrary @(Entropy n)
        return
            . ApiMnemonicT
            . SomeMnemonic
            $ entropyToMnemonic ent

instance
    ( n ~ EntropySize mw
    , csz ~ CheckSumBits n
    , ConsistentEntropy n mw csz
    , Arbitrary (ApiMnemonicT rest)
    )
    => Arbitrary (ApiMnemonicT (mw ': rest))
  where
    arbitrary = do
        ApiMnemonicT x <- arbitrary @(ApiMnemonicT '[mw])
        ApiMnemonicT y <- arbitrary @(ApiMnemonicT rest)
        -- NOTE
        -- If we were to "naively" combine previous generators without weights,
        -- we would be tilting probabilities towards the leftmost element, so
        -- that every element would be twice as likely to appear as its right-
        -- hand neighbour, with an exponential decrease. (After the 7th element,
        -- subsequent elements would have less than 1 percent chance of
        -- appearing.) By tweaking the weights a bit as we have done below, we
        -- make it possible for every element to have at least 10% chance of
        -- appearing, for lists up to 10 elements.
        frequency
            [ (1, pure $ ApiMnemonicT x)
            , (5, pure $ ApiMnemonicT y)
            ]

instance Arbitrary ApiBlockReference where
    arbitrary = ApiBlockReference
        <$> arbitrary <*> arbitrary <*> genUniformTime <*> arbitrary
    shrink (ApiBlockReference sln sli t bh) =
        [ ApiBlockReference sln' sli' t bh'
        | (sln', sli', bh') <- shrink (sln, sli, bh) ]

instance Arbitrary ApiBlockInfo where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiSlotReference where
    arbitrary = ApiSlotReference <$> arbitrary <*> arbitrary <*> genUniformTime
    shrink (ApiSlotReference sln sli t) =
        [ ApiSlotReference sln' sli' t
        | (sln', sli') <- shrink (sln, sli) ]

instance Arbitrary ApiSlotId where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiNetworkInformation where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiNtpStatus where
    arbitrary = do
        o <- Quantity <$> (arbitrary @Integer)
        elements
            [ ApiNtpStatus NtpSyncingStatusUnavailable Nothing
            , ApiNtpStatus NtpSyncingStatusPending Nothing
            , ApiNtpStatus NtpSyncingStatusAvailable (Just o)
            ]

instance Arbitrary ApiNetworkClock where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (Quantity "block" Word32) where
    shrink (Quantity 0) = []
    shrink _ = [Quantity 0]
    arbitrary = Quantity . fromIntegral <$> (arbitrary @Word32)

instance Arbitrary (Quantity "slot" Word32) where
    shrink (Quantity 0) = []
    shrink _ = [Quantity 0]
    arbitrary = Quantity . fromIntegral <$> (arbitrary @Word32)

instance Arbitrary SlotNo where
    shrink = fmap SlotNo . shrink . unSlotNo
    arbitrary = SlotNo <$> arbitrary

instance Arbitrary (Hash "Genesis") where
    arbitrary = Hash . B8.pack <$> replicateM 32 arbitrary

instance Arbitrary StartTime where
    arbitrary = StartTime <$> genUniformTime

instance Arbitrary (Quantity "second" NominalDiffTime) where
    shrink (Quantity 0.0) = []
    shrink _ = [Quantity 0.0]
    arbitrary = Quantity . fromInteger <$> choose (0, 10_000)

instance Arbitrary (Quantity "percent" Double) where
    shrink (Quantity 0.0) = []
    shrink _ = [Quantity 0.0]
    arbitrary = Quantity <$> choose (0,100)

instance Arbitrary ApiVerificationKey where
    arbitrary =
        fmap ApiVerificationKey . (,)
            <$> fmap B8.pack (replicateM 32 arbitrary)
            <*> elements [UtxoExternal, MutableAccount, MultisigScript]

instance ToSchema ApiVerificationKey where
    declareNamedSchema _ = declareSchemaForDefinition "ApiVerificationKey"

instance Arbitrary Api.MaintenanceAction where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance ToSchema Api.ApiMaintenanceAction where
    declareNamedSchema _ = declareSchemaForDefinition "ApiMaintenanceAction"

instance ToSchema Api.ApiMaintenanceActionPostData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiMaintenanceActionPostData"

instance Arbitrary ApiNetworkParameters where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiEra where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiEraInfo where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary SlotId where
    arbitrary = applyArbitrary2 SlotId
    shrink = genericShrink

instance Arbitrary SlotInEpoch where
    shrink (SlotInEpoch x) = SlotInEpoch <$> shrink x
    arbitrary = SlotInEpoch <$> arbitrary

instance Arbitrary EpochNo where
    shrink (EpochNo x) = EpochNo <$> shrink x
    arbitrary = EpochNo <$> arbitrary

instance Arbitrary Word31 where
    arbitrary = arbitrarySizedBoundedIntegral
    shrink = shrinkIntegral

instance Arbitrary ApiAsset where
    arbitrary = toApiAsset Nothing <$> genAssetIdSmallRange

instance Arbitrary a => Arbitrary (AddressAmount a) where
    arbitrary = applyArbitrary3 AddressAmount
    shrink _ = []

instance Arbitrary (PostTransactionData t) where
    arbitrary = PostTransactionData
        <$> arbitrary
        <*> arbitrary
        <*> elements [Just SelfWithdrawal, Nothing]
        <*> arbitrary
        <*> arbitrary

instance Arbitrary ApiWithdrawalPostData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (ApiPutAddressesData t) where
    arbitrary = do
        n <- choose (1,255)
        addrs <- vector n
        pure $ ApiPutAddressesData ((, Proxy @t) <$> addrs)

instance Arbitrary (PostTransactionFeeData t) where
    arbitrary = PostTransactionFeeData
        <$> arbitrary
        <*> elements [Just SelfWithdrawal, Nothing]
        <*> arbitrary
        <*> arbitrary

instance Arbitrary PostExternalTransactionData where
    arbitrary = do
        count <- choose (0, 32)
        bytes <- BS.pack <$> replicateM count arbitrary
        return $ PostExternalTransactionData bytes
    shrink (PostExternalTransactionData bytes) =
        PostExternalTransactionData . BS.pack <$> shrink (BS.unpack bytes)

instance Arbitrary TxMetadata where
    arbitrary = genTxMetadata
    shrink = shrinkTxMetadata

instance Arbitrary ApiTxMetadata where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (ApiTransaction t) where
    shrink = genericShrink
    arbitrary = do
        txStatus <- arbitrary
        txInsertedAt <- case txStatus of
            ApiT Pending -> pure Nothing
            ApiT InLedger -> arbitrary
            ApiT Expired -> pure Nothing
        txPendingSince <- case txStatus of
            ApiT Pending -> arbitrary
            ApiT InLedger -> pure Nothing
            ApiT Expired -> arbitrary
        txExpiresAt <- case txStatus of
            ApiT Pending -> arbitrary
            ApiT InLedger -> pure Nothing
            ApiT Expired -> Just <$> arbitrary

        ApiTransaction
            <$> arbitrary
            <*> arbitrary
            <*> arbitrary
            <*> arbitrary
            <*> pure txInsertedAt
            <*> pure txPendingSince
            <*> pure txExpiresAt
            <*> arbitrary
            <*> arbitrary
            <*> genInputs
            <*> genOutputs
            <*> genWithdrawals
            <*> arbitrary
            <*> pure txStatus
            <*> arbitrary
      where
        genInputs =
            Test.QuickCheck.scale (`mod` 3) arbitrary
        genOutputs =
            Test.QuickCheck.scale (`mod` 3) arbitrary
        genWithdrawals =
            Test.QuickCheck.scale (`mod` 3) arbitrary

instance Arbitrary (ApiWithdrawal (t :: NetworkDiscriminant)) where
    arbitrary = ApiWithdrawal
        <$> fmap (, Proxy @t) arbitrary
        <*> arbitrary

instance Arbitrary RewardAccount where
    arbitrary = RewardAccount . BS.pack <$> vector 28

instance Arbitrary Coin where
    -- No Shrinking
    arbitrary = genCoinLargePositive

instance Arbitrary UTxO where
    shrink (UTxO utxo) = UTxO <$> shrink utxo
    arbitrary = do
        n <- choose (0, 10)
        utxo <- zip
            <$> vector n
            <*> vector n
        return $ UTxO $ Map.fromList utxo

instance Arbitrary TokenBundle where
    shrink = shrinkTokenBundleSmallRange
    arbitrary = genTokenBundleSmallRange

instance Arbitrary TokenMap where
    shrink = shrinkTokenMapSmallRange
    arbitrary = genTokenMapSmallRange

instance Arbitrary TxOut where
    -- Shrink token bundle but not address
    shrink (TxOut a t) = TxOut a <$> shrink t
    arbitrary = TxOut <$> arbitrary <*> arbitrary

instance Arbitrary TxIn where
    -- No Shrinking
    arbitrary = TxIn
        <$> arbitrary
        -- NOTE: No need for a crazy high indexes
        <*> Test.QuickCheck.scale (`mod` 3) arbitrary

instance Arbitrary ApiUtxoStatistics where
    arbitrary = do
        utxos <- arbitrary
        let (UTxOStatistics histoBars stakes bType) =
                computeUtxoStatistics log10 utxos
        let boundCountMap =
                Map.fromList $ map (\(HistogramBar k v)-> (k,v)) histoBars
        return $ ApiUtxoStatistics
            (Quantity $ fromIntegral stakes)
            (ApiT bType)
            boundCountMap

instance Arbitrary (ApiTxInput t) where
    shrink _ = []
    arbitrary = applyArbitrary2 ApiTxInput

instance Arbitrary (Quantity "slot" Natural) where
    shrink (Quantity 0) = []
    shrink _ = [Quantity 0]
    arbitrary = Quantity . fromIntegral <$> (arbitrary @Word8)

instance Arbitrary (Hash "Tx") where
    arbitrary = Hash . B8.pack <$> replicateM 32 arbitrary

instance Arbitrary Direction where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary TxStatus where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary (Quantity "block" Natural) where
    arbitrary = fmap (Quantity . fromIntegral) (arbitrary @Word32)

instance Arbitrary ApiPostRandomAddressData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiAddressInspect where
    arbitrary = do
        style <- elements [ "Byron", "Icarus", "Shelley" ]
        stake <- elements [ "none", "by value", "by pointer" ]
        pure $ ApiAddressInspect $ Aeson.object
            [ "address_style" .= Aeson.String style
            , "stake_reference" .= Aeson.String stake
            ]

instance Arbitrary HealthCheckSMASH where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiHealthCheck where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary ApiPostAccountKeyData where
    arbitrary = genericArbitrary
    shrink = genericShrink

instance Arbitrary TokenFingerprint where
    arbitrary = do
        AssetId policy aName <- genAssetIdSmallRange
        pure $ mkTokenFingerprint policy aName
    shrink _ = []

instance Arbitrary ApiAccountKey where
    arbitrary = do
        xpubKey <- BS.pack <$> replicateM 64 arbitrary
        pubKey <- BS.pack <$> replicateM 32 arbitrary
        oneof [ pure $ ApiAccountKey pubKey False
              , pure $ ApiAccountKey xpubKey True ]

instance Arbitrary Natural where
    shrink = shrinkIntegral
    arbitrary = genNatural

{-------------------------------------------------------------------------------
                   Specification / Servant-Swagger Machinery

  Below is a bit of complicated API-Level stuff in order to achieve two things:

  1/ Verify that every response from the API that actually has a JSON content
     type returns a JSON instance that matches the JSON format described by the
     specification (field names should be the same, and constraints on values as
     well).
     For this, we need three things:
         - ToJSON instances on all those types, it's a given with the above
         - Arbitrary instances on all those types, that reflect as much as
           possible, all possible values of those types. Also given by using
           'genericArbitrary' whenever possible.
         - ToSchema instances which tells how do a given type should be
           represented.
     The trick is for the later point. In a "classic" scenario, we would have
     defined the `ToSchema` instances directly in Haskell on our types, which
     eventually becomes a real pain to maintain. Instead, we have written the
     spec by hand, and we want to check that our implementation matches it.
     So, we "emulate" the 'ToSchema' instance by:
         - Parsing the specification file (which is embedded at compile-time)
         - Creating missing 'ToSchema' by doing lookups in that global schema

  2/ The above verification is rather weak, because it just controls the return
     types of endpoints, but not that those endpoints are somewhat valid. Thus,
     we've also built another check 'validateEveryPath' which crawls our servant
     API type, and checks whether every path we have in our API appears in the
     specification. It does it by defining a few recursive type-classes to
     crawl the API, and for each endpoint:
         - construct the corresponding path (with verb)
         - build an HSpec scenario which checks whether the path is present
    This seemingly means that the identifiers we use in our servant paths (in
    particular, those for path parameters) should exactly match the specs.

-------------------------------------------------------------------------------}

-- | Specification file, embedded at compile-time and decoded right away
specification :: Aeson.Value
specification =
    unsafeDecode bytes
  where
    bytes = $(
        let swaggerYaml = "./specifications/api/swagger.yaml"
        in liftIO (lookupEnv "SWAGGER_YAML") >>=
        maybe (makeRelativeToProject swaggerYaml) pure >>=
        embedFile
        )
    unsafeDecode =
        either (error . (msg <>) . show) Prelude.id . Yaml.decodeEither'
    msg = "Whoops! Failed to parse or find the api specification document: "

instance ToSchema (ApiAddress t) where
    declareNamedSchema _ = declareSchemaForDefinition "ApiAddress"

instance ToSchema ApiAddressInspect where
    declareNamedSchema _ = declareSchemaForDefinition "ApiAddressInspect"

instance ToSchema (ApiPutAddressesData t) where
    declareNamedSchema _ = declareSchemaForDefinition "ApiPutAddressesData"

instance ToSchema (ApiSelectCoinsData n) where
    declareNamedSchema _ = do
        addDefinition =<< declareSchemaForDefinition "TransactionMetadataValue"
        declareSchemaForDefinition "ApiSelectCoinsData"

instance ToSchema (ApiT SmashServer) where
    declareNamedSchema _ = declareSchemaForDefinition "ApiSmashServer"

instance ToSchema ApiHealthCheck where
    declareNamedSchema _ = declareSchemaForDefinition "ApiHealthCheck"

instance ToSchema (ApiCoinSelection n) where
    declareNamedSchema _ = declareSchemaForDefinition "ApiCoinSelection"

instance ToSchema ApiWallet where
    declareNamedSchema _ = declareSchemaForDefinition "ApiWallet"

instance ToSchema ApiByronWallet where
    declareNamedSchema _ = declareSchemaForDefinition "ApiByronWallet"

instance ToSchema ApiWalletMigrationInfo where
    declareNamedSchema _ =
        declareSchemaForDefinition "ApiWalletMigrationInfo"

instance ToSchema (ApiWalletMigrationPostData t "lenient") where
    declareNamedSchema _ =
        declareSchemaForDefinition "ApiByronWalletMigrationPostData"

instance ToSchema (ApiWalletMigrationPostData t "raw") where
    declareNamedSchema _ =
        declareSchemaForDefinition "ApiShelleyWalletMigrationPostData"

instance ToSchema ApiWalletPassphrase where
    declareNamedSchema _ =
        declareSchemaForDefinition "ApiWalletPassphrase"

instance ToSchema ApiStakePool where
    declareNamedSchema _ = declareSchemaForDefinition "ApiStakePool"

instance ToSchema ApiStakePoolMetrics where
    declareNamedSchema _ = declareSchemaForDefinition "ApiStakePoolMetrics"

instance ToSchema ApiFee where
    declareNamedSchema _ = declareSchemaForDefinition "ApiFee"

instance ToSchema ApiAsset where
    declareNamedSchema _ = declareSchemaForDefinition "ApiAsset"

instance ToSchema ApiTxId where
    declareNamedSchema _ = declareSchemaForDefinition "ApiTxId"

instance ToSchema WalletPostData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiWalletPostData"

instance ToSchema AccountPostData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiAccountPostData"

instance ToSchema WalletOrAccountPostData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiWalletOrAccountPostData"

instance ToSchema (ByronWalletPostData '[12]) where
    declareNamedSchema _ = declareSchemaForDefinition "ApiByronWalletRandomPostData"

instance ToSchema (ByronWalletPostData '[15]) where
    declareNamedSchema _ = declareSchemaForDefinition "ApiByronWalletIcarusPostData"

instance ToSchema (ByronWalletPostData '[12,15,18,21,24]) where
    -- NOTE ApiByronWalletLedgerPostData works too. Only the description differs.
    declareNamedSchema _ = declareSchemaForDefinition "ApiByronWalletTrezorPostData"

instance ToSchema ByronWalletFromXPrvPostData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiByronWalletRandomXPrvPostData"

instance ToSchema SomeByronWalletPostData where
    declareNamedSchema _ = declareSchemaForDefinition "SomeByronWalletPostData"

instance ToSchema WalletPutData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiWalletPutData"

instance ToSchema SettingsPutData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiSettingsPutData"

instance ToSchema (ApiT Settings) where
    declareNamedSchema _ = declareSchemaForDefinition "ApiGetSettings"

instance ToSchema WalletPutPassphraseData where
    declareNamedSchema _ =
        declareSchemaForDefinition "ApiWalletPutPassphraseData"

instance ToSchema ByronWalletPutPassphraseData where
    declareNamedSchema _ =
        declareSchemaForDefinition "ApiByronWalletPutPassphraseData"

instance ToSchema ApiTxMetadata where
    declareNamedSchema _ = declareSchemaForDefinition "TransactionMetadataValue"

instance ToSchema (PostTransactionData t) where
    declareNamedSchema _ = do
        addDefinition =<< declareSchemaForDefinition "TransactionMetadataValue"
        declareSchemaForDefinition "ApiPostTransactionData"

instance ToSchema (PostTransactionFeeData t) where
    declareNamedSchema _ = do
        addDefinition =<< declareSchemaForDefinition "TransactionMetadataValue"
        declareSchemaForDefinition "ApiPostTransactionFeeData"

instance ToSchema (ApiTransaction t) where
    declareNamedSchema _ = do
        addDefinition =<< declareSchemaForDefinition "TransactionMetadataValue"
        declareSchemaForDefinition "ApiTransaction"

instance ToSchema ApiUtxoStatistics where
    declareNamedSchema _ = declareSchemaForDefinition "ApiWalletUTxOsStatistics"

instance ToSchema ApiNetworkInformation where
    declareNamedSchema _ = declareSchemaForDefinition "ApiNetworkInformation"

instance ToSchema ApiNetworkClock where
    declareNamedSchema _ = declareSchemaForDefinition "ApiNetworkClock"

data ApiScript
instance ToSchema ApiScript where
    declareNamedSchema _ = declareSchemaForDefinition "ApiScript"

data ApiPubKey
instance ToSchema ApiPubKey where
    declareNamedSchema _ = declareSchemaForDefinition "ApiPubKey"

instance ToSchema ApiAddressData where
    declareNamedSchema _ = do
        addDefinition =<< declareSchemaForDefinition "ScriptValue"
        addDefinition =<< declareSchemaForDefinition "CredentialValue"
        declareSchemaForDefinition "ApiAddressData"

instance ToSchema ApiCredential where
    declareNamedSchema _ = do
        addDefinition =<< declareSchemaForDefinition "ScriptValue"
        declareSchemaForDefinition "ApiCredential"

instance ToSchema AnyAddress where
    declareNamedSchema _ = declareSchemaForDefinition "AnyAddress"

instance ToSchema ApiNetworkParameters where
    declareNamedSchema _ = declareSchemaForDefinition "ApiNetworkParameters"

instance ToSchema ApiEra where
    declareNamedSchema _ = declareSchemaForDefinition "ApiEra"

instance ToSchema ApiEraInfo where
    declareNamedSchema _ = declareSchemaForDefinition "ApiEraInfo"

instance ToSchema ApiSlotReference where
    declareNamedSchema _ = declareSchemaForDefinition "ApiSlotReference"

instance ToSchema ApiBlockReference where
    declareNamedSchema _ = declareSchemaForDefinition "ApiBlockReference"

instance ToSchema ApiWalletDelegationStatus where
    declareNamedSchema _ = declareSchemaForDefinition "ApiWalletDelegationStatus"

instance ToSchema ApiWalletDelegationNext where
    declareNamedSchema _ = declareSchemaForDefinition "ApiWalletDelegationNext"

instance ToSchema ApiWalletDelegation where
    declareNamedSchema _ = declareSchemaForDefinition "ApiWalletDelegation"

instance ToSchema ApiPostRandomAddressData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiPostRandomAddressData"

instance ToSchema ApiWalletSignData where
    declareNamedSchema _ = do
        addDefinition =<< declareSchemaForDefinition "TransactionMetadataValue"
        declareSchemaForDefinition "ApiWalletSignData"

instance ToSchema ApiPostAccountKeyData where
    declareNamedSchema _ = declareSchemaForDefinition "ApiPostAccountKeyData"

instance ToSchema ApiAccountKey where
    declareNamedSchema _ = declareSchemaForDefinition "ApiAccountKey"

-- | Utility function to provide an ad-hoc 'ToSchema' instance for a definition:
-- we simply look it up within the Swagger specification.
declareSchemaForDefinition :: Text -> Declare (Definitions Schema) NamedSchema
declareSchemaForDefinition ref = do
    let json = foldl' unsafeLookupKey specification ["components","schemas",ref]
    case Aeson.eitherDecode' $ Aeson.encode json of
        Left err -> error $
            "unable to decode schema for definition '" <> T.unpack ref <> "': " <> show err
        Right schema ->
            return $ NamedSchema (Just ref) schema

-- | Add a known definition to the set of definitions, this may be necessary
-- when we can't inline a definition because it is recursive or, when a
-- definition is only used in an existing schema but has no top-level type for
-- which to define a 'ToSchema' instance.
addDefinition :: NamedSchema -> Declare (Definitions Schema) ()
addDefinition (NamedSchema Nothing _) =
    error "Trying to add definition for an unnamed NamedSchema!"
addDefinition (NamedSchema (Just k) s) = do
    defs <- look
    declare $ defs & at k ?~ s

unsafeLookupKey :: Aeson.Value -> Text -> Aeson.Value
unsafeLookupKey json k = case json of
    Aeson.Object m -> fromMaybe bombMissing (HM.lookup k m)
    m -> bombNotObject m
  where
    bombNotObject m =
        error $ "given JSON value is NOT an object: " <> show m
    bombMissing =
        error $ "no value found in map for key: " <> T.unpack k

-- | Verify that all servant endpoints are present and match the specification
class ValidateEveryPath api where
    validateEveryPath :: Proxy api -> Spec

instance {-# OVERLAPS #-} HasPath a => ValidateEveryPath a where
    validateEveryPath proxy = do
        let (verb, path) = getPath proxy
        let verbStr = toLower <$> show verb
        it (verbStr <> " " <> path <> " exists in specification") $ do
            case foldl' unsafeLookupKey specification ["paths", T.pack path] of
                Aeson.Object m -> case HM.lookup (T.pack verbStr) m of
                    Just{}  -> return @IO ()
                    Nothing -> fail "couldn't find path in specification"
                _ -> fail "couldn't find path in specification"

instance (ValidateEveryPath a, ValidateEveryPath b) => ValidateEveryPath (a :<|> b) where
    validateEveryPath _ = do
        validateEveryPath (Proxy @a)
        validateEveryPath (Proxy @b)

-- | Extract the path of a given endpoint, in a format that is swagger-friendly
class HasPath api where
    getPath :: Proxy api -> (StdMethod, String)

instance (Method m) => HasPath (Verb m s ct a) where
    getPath _ = (method (Proxy @m), "")

instance (Method m) => HasPath (NoContentVerb m) where
    getPath _ = (method (Proxy @m), "")

instance (KnownSymbol path, HasPath sub) => HasPath (path :> sub) where
    getPath _ =
        let (verb, sub) = getPath (Proxy @sub)
        in (verb, "/" <> symbolVal (Proxy :: Proxy path) <> sub)

instance (KnownSymbol param, HasPath sub) => HasPath (Capture param t :> sub)
  where
    getPath _ =
        let (verb, sub) = getPath (Proxy @sub)
        in case symbolVal (Proxy :: Proxy param) of
            sym | sym == "*" -> (verb, "/" <> sym <> sub)
            sym -> (verb, "/{" <> sym <> "}" <> sub)

instance HasPath sub => HasPath (ReqBody a b :> sub) where
    getPath _ = getPath (Proxy @sub)

instance HasPath sub => HasPath (QueryParam a b :> sub) where
    getPath _ = getPath (Proxy @sub)

instance HasPath sub => HasPath (QueryFlag sym :> sub) where
    getPath _ = getPath (Proxy @sub)

instance HasPath sub => HasPath (Header' opts name ty :> sub) where
    getPath _ = getPath (Proxy @sub)

-- A way to demote 'StdMethod' back to the world of values. Servant provides a
-- 'reflectMethod' that does just that, but demote types to raw 'ByteString' for
-- an unknown reason :/
instance Method 'GET where method _ = GET
instance Method 'POST where method _ = POST
instance Method 'PUT where method _ = PUT
instance Method 'DELETE where method _ = DELETE
instance Method 'PATCH where method _ = PATCH
class Method (m :: StdMethod) where
    method :: Proxy m -> StdMethod

{-------------------------------------------------------------------------------
            Generating Golden Test Vectors For Address Encoding
-------------------------------------------------------------------------------}

-- SPENDINGKEY=$(jcli key generate --type Ed25519Extended | jcli key to-public)
-- DELEGATIONKEY=$(jcli key generate --type Ed25519Extended | jcli key to-public)
--
-- SPENDINGKEYBYTES=$(echo $SPENDINGKEY | jcli key to-bytes)
-- DELEGATIONKEYBYTES=$(echo $DELEGATIONKEY | jcli key to-bytes)
--
-- MAINNETSINGLE=$(jcli address single $SPENDINGKEY --prefix addr)
-- TESTNETSINGLE=$(jcli address single $SPENDINGKEY --testing --prefix addr)
--
-- MAINNETGROUPED=$(jcli address single $SPENDINGKEY $DELEGATIONKEY --prefix addr)
-- TESTNETGROUPED=$(jcli address single $SPENDINGKEY $DELEGATIONKEY --testing --prefix addr)
--
-- TESTVECTOR=test_vector_$(date +%s)
-- touch $TESTVECTOR
-- echo "spending key:        $SPENDINGKEYBYTES" >> $TESTVECTOR
-- echo "\ndelegation key:    $DELEGATIONKEYBYTES" >> $TESTVECTOR
-- echo "\nsingle (mainnet):  $MAINNETSINGLE" >> $TESTVECTOR
-- echo "\ngrouped (mainnet): $MAINNETGROUPED" >> $TESTVECTOR
-- echo "\nsingle (testnet):  $TESTNETSINGLE" >> $TESTVECTOR
-- echo "\ngrouped (testnet): $TESTNETGROUPED" >> $TESTVECTOR
--
-- echo -e $(cat $TESTVECTOR)
-- echo "Saved as $TESTVECTOR."
