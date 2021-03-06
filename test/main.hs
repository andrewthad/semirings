{-# LANGUAGE CPP #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE DeriveFunctor #-}

import Control.Applicative (liftA2)
import Data.Complex
import Data.Fixed
import Data.Functor.Const
import Data.Functor.Identity
import Data.HashMap.Strict
import Data.HashSet
import Data.Hashable
import Data.Int
import Data.IntMap.Strict
import Data.IntSet
import Data.Map
import Data.Monoid
import Data.Ord (Down(..))
import Data.Orphans ()
import Data.Proxy (Proxy(..))
import Data.Ratio
import Data.Semigroup
import Data.Semiring
import Data.Sequence
import Data.Set
import Data.Vector hiding (generate)
import Data.Word
import GHC.Natural
import Prelude hiding (Num(..))
import System.IO.Unsafe
import Test.QuickCheck hiding (Fixed)
import Test.QuickCheck.Gen (suchThat)
import Test.QuickCheck.Instances ()
import Test.Tasty (defaultMain, testGroup, TestTree)
import Text.Show.Functions ()
import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Data.Vector.Storable as SV
import qualified Data.Vector.Unboxed as UV
import qualified GHC.Num as Num
import qualified Test.QuickCheck.Classes as QCC

type Laws = QCC.Laws

myLaws :: (Arbitrary a, Show a, Eq a, Semiring a) => Proxy a -> [Laws]
myLaws p = [QCC.semiringLaws p]

namedTests :: [(String, [Laws])]
namedTests =
  [ ("Bool", myLaws pBool)
--  , ("Double", myLaws pDouble) -- needs to be within some epsilon
--  , ("Float", myLaws pFloat)   -- needs to be within some epsilon
--  , ("Complex", myLaws pComplex) -- needs to be within some epsilon
  , ("Int", myLaws pInt)
  , ("Int8", myLaws pInt8)
  , ("Int16", myLaws pInt16)
  , ("Int32", myLaws pInt32)
  , ("Int64", myLaws pInt64)
  , ("Word", myLaws pWord)
  , ("Word8", myLaws pWord8)
  , ("Word16", myLaws pWord16)
  , ("Word32", myLaws pWord32)
  , ("Word64", myLaws pWord64)
  , ("()", myLaws pUnit)
  , ("[]", myLaws pList)
  , ("Maybe", myLaws pMaybe)
  , ("PosRatio", myLaws pPosRatio)
  , ("IO", myLaws pIO)
  , ("Fixed", myLaws pFixed)
  , ("Min", myLaws pMin)
  , ("Max", myLaws pMax)
  , ("Identity", myLaws pIdentity)
  , ("Dual", myLaws pDual)
  , ("(->)", myLaws pFunction)
  , ("Sum", myLaws pSum)
  , ("Product", myLaws pProduct)
  , ("Down", myLaws pDown)
  , ("Const", myLaws pConst)
--  , ("IntMap", myLaws pIntMap) -- needs newtypes
  , ("Set", myLaws pSet)
--  , ("IntSet", myLaws pIntSet) -- needs newtypes
  , ("HashSet", myLaws pHashSet)
  , ("HashMap", myLaws pHashMap)
  , ("Vector", myLaws pVector)
  , ("Storable Vector", myLaws pStorableVector)
  , ("Unboxed Vector", myLaws pUnboxedVector)
  , ("Map", myLaws pMap)
  , ("Predicate", myLaws pPredicate)
  , ("Equivalence", myLaws pEquivalence)
  , ("Op", myLaws pOp)
  , ("Ap", myLaws pAp)
  ]

#if !(MIN_VERSION_base(4,12,0))
newtype Ap f a = Ap { getAp :: f a }
  deriving (Eq, Functor, Applicative, Show)
instance (Semiring a, Applicative f) => Semiring (Ap f a) where
  zero = pure zero
  one = pure one
  plus = liftA2 plus
  times = liftA2 times
#endif
deriving instance (Arbitrary (f a)) => Arbitrary (Ap f a)

newtype Predicate a = Predicate (a -> Bool)
  deriving (Eq, Show)
deriving instance Semiring (Predicate a)
deriving instance Ring (Predicate a)
deriving instance (Arbitrary a, CoArbitrary a) => Arbitrary (Predicate a)

newtype Equivalence a = Equivalence (a -> a -> Bool)
  deriving (Eq, Show)
deriving instance Semiring a => Semiring (Equivalence a)
deriving instance Ring a => Ring (Equivalence a)
deriving instance (Arbitrary a, CoArbitrary a) => Arbitrary (Equivalence a)

newtype Op a b = Op (b -> a)
  deriving (Eq, Show)
deriving instance Semiring a => Semiring (Op a b)
deriving instance Ring a => Ring (Op a b)
deriving instance (Arbitrary a, CoArbitrary a, CoArbitrary b) => Arbitrary (Op a b)

pAp = p @(Ap Identity Int)
pPredicate = p @(Predicate Int)
pEquivalence = p @(Equivalence Int)
pOp = p @(Op Int Int)

deriving instance Arbitrary a => Arbitrary (Down a)

main :: IO ()
main = QCC.lawsCheckMany namedTests

-- | Rationals constrained to being positive
newtype PosRatio a = PosRatio { getPosRatio :: Ratio a }
  deriving (Eq, Show, Semiring)

instance (Arbitrary a, Integral a, Ord a) => Arbitrary (PosRatio a) where
  arbitrary =
    let nm = suchThat (arbitrary :: Gen a) (> 0)
        dm = suchThat (arbitrary :: Gen a) (> 0)
    in PosRatio <$> liftA2 (%) nm dm

p :: forall a. Proxy a
p = Proxy

instance (Arbitrary a, Eq b) => Eq (a -> b) where
  (==) f g =
    let x = generate arbitrary :: IO a
        x' = unsafePerformIO x
    in f x' == g x'

instance Show (Endo a) where
  show _ = "<<<Endo>>>"

deriving instance (Arbitrary a, Eq a) => Eq (Endo a)

-- no
instance Show (IO a) where
  show _ = "<<<IO action>>>"

-- no no
instance Eq a => Eq (IO a) where
  x == y = unsafePerformIO $ liftA2 (==) x y

-- this is fine
instance Arbitrary a => Arbitrary (IO a) where
  arbitrary = fmap pure (arbitrary :: Gen a)

deriving instance Hashable a => Hashable (Sum a)

pBool = p @Bool
pDouble = p @Double
pFloat = p @Float
pInt = p @Int
pInt8 = p @Int8
pInt16 = p @Int16
pInt32 = p @Int32
pInt64 = p @Int64
pInteger = p @Integer
pNatural = p @Natural
pWord = p @Word
pWord8 = p @Word8
pWord16 = p @Word16
pWord32 = p @Word32
pWord64 = p @Word64
pUnit = p @()
pList = p @([Int])
pMaybe = p @(Maybe Int)
pPosRatio = p @(PosRatio Int)
pIO = p @(IO Int)
pComplex = p @(Complex Double)
pFixed = p @(Fixed E0)
pMin = p @(Min Int)
pMax = p @(Max Int)
pIdentity = p @(Identity Int)
pDual = p @(Dual Int)
pEndo = p @(Endo (Sum Int))
pSum  = p @(Sum Int)
pProduct = p @(Product Int)
pDown = p @(Down Int)
pIntMap = p @(IntMap Int)
pSeq = p @(Seq Int)
pSet = p @(Set (Sum Int))
pIntSet = p @(IntSet)
pHashSet = p @(HashSet (Sum Int))
pFunction = p @(Int -> Int)
pVector = p @(Vector Int)
pStorableVector = p @(SV.Vector Int)
pUnboxedVector = p @(UV.Vector Int)
pMap = p @(Map (Sum Int) Int)
pHashMap = p @(HashMap (Sum Int) Int)
pConst = p @(Const Int Int)
pAlt = p @(Alt Maybe Int)

