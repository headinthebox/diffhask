{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE ConstraintKinds         #-}
{-# LANGUAGE DataKinds               #-}
{-# LANGUAGE FlexibleContexts        #-}
{-# LANGUAGE FlexibleInstances       #-}
{-# LANGUAGE FunctionalDependencies  #-}
{-# LANGUAGE InstanceSigs            #-}
{-# LANGUAGE MultiParamTypeClasses   #-}
{-# LANGUAGE NoImplicitPrelude       #-}
{-# LANGUAGE OverloadedLists         #-}
{-# LANGUAGE Rank2Types              #-}
{-# LANGUAGE TypeFamilies            #-}
{-# LANGUAGE TypeFamilyDependencies  #-}
{-# LANGUAGE TypeInType              #-}
{-# LANGUAGE UndecidableInstances    #-}
{-# LANGUAGE UndecidableSuperClasses #-}
{-# OPTIONS_GHC -freduction-depth=10000 #-}
-- | A magma heirarchy for addition. The basic magma structure is repeated and prefixed with 'Additive-'.
module Internal.NumHask.Algebra.Additive
  ( -- AdditiveMagma(..)
  -- , AdditiveUnital(..)
  -- , AdditiveAssociative
  -- , AdditiveCommutative
  AdditiveInvertible(..)
  -- , AdditiveIdempotent
  -- , sum
  -- , Additive(..)
  -- , AdditiveRightCancellative(..)
  -- , AdditiveLeftCancellative(..)
  , AdditiveGroup(..)
  , AdditiveGroupModule(..)
  , AdditiveBasis(..)
  , AdditiveModule(..)
  , Additive(..)
  , Add(..)
  , Negate(..)
  ) where
import           Internal.Internal
import qualified Numeric.Dimensions as Dim
import           NumHask.Array      ()
import           NumHask.Prelude    (Show, ($))
import qualified NumHask.Prelude    as P

data Negate = Negate deriving Show


class (Operable c '[] t, P.Monad m, SameMonad a b m) =>
      Additive m c a b t | a -> t, b -> t, a b -> t, a b -> c where
  (+) :: a -> b -> ComputationT c t m (D c '[] t)

instance (Operable c '[] t, P.Monad m) =>
         Additive m c (D c '[] t) (D c '[] t) t where
  (+) a b = binOp Add a b

instance (Operable c '[] t, P.Monad m) =>
         Additive m c (ComputationT c t m (D c '[] t)) (D c '[] t) t where
  (+) ::
       ComputationT c t m (D c '[] t)
    -> (D c '[] t)
    -> ComputationT c t m (D c '[] t)
  (+) a b = do
    ca <- a
    binOp Add ca b

instance (Operable c '[] t, P.Monad m) =>
         Additive m c (D c '[] t) (ComputationT c t m (D c '[] t)) t where
  (+) ::
       D c '[] t
    -> ComputationT c t m (D c '[] t)
    -> ComputationT c t m (D c '[] t)
  (+) a b = do
    cb <- b
    binOp Add a cb

instance (Operable c '[] t, P.Monad m) =>
         Additive m c (ComputationT c t m (D c '[] t)) (ComputationT c t m (D c '[] t)) t where
  (+) ::
       ComputationT c t m (D c '[] t)
    -> ComputationT c t m (D c '[] t)
    -> ComputationT c t m (D c '[] t)
  (+) a b = do
    ca <- a
    cb <- b
    binOp Add ca cb


class ( Operable c '[] t
      , P.Monad m
      , MonCalcShape '[] ~ '[]
      , IsMonOp Negate c '[] t
      , SameMonad a b m
      ) =>
      AdditiveGroup m c a b t | a -> t, b -> t, a b -> t, a b -> c where
  (-) :: a -> b -> ComputationT c t m (D c '[] t)

instance ( Operable c '[] t
         , P.Monad m
         , MonCalcShape '[] ~ '[]
         , P.AdditiveInvertible t,IsMonOp Negate c '[] t
         ) =>
         AdditiveGroup m c (D c '[] t) (D c '[] t) t where

  (-) a b = do
    nb <- negate b
    binOp Add a nb

instance ( Operable c '[] t
         , P.Monad m
         , MonCalcShape '[] ~ '[]
         , P.AdditiveInvertible t,IsMonOp Negate c '[] t
         ) =>
         AdditiveGroup m c (ComputationT c t m (D c '[] t)) (D c '[] t) t where
  (-) ::
       ComputationT c t m (D c '[] t)
    -> D c '[] t
    -> ComputationT c t m (D c '[] t)
  (-) a b = do
    nb <- negate b
    ca <- a
    binOp Add ca nb

instance ( Operable c '[] t
         , P.Monad m
         , MonCalcShape '[] ~ '[]
         , P.AdditiveInvertible t,IsMonOp Negate c '[] t
         ) =>
         AdditiveGroup m c (D c '[] t) (ComputationT c t m (D c '[] t)) t where
  (-) ::
       D c '[] t
    -> ComputationT c t m (D c '[] t)
    -> ComputationT c t m (D c '[] t)
  (-) a b = do
    cb <- negate b
    binOp Add a cb

instance ( Operable c '[] t
         , P.Monad m
         , MonCalcShape '[] ~ '[]

         , P.AdditiveInvertible t,IsMonOp Negate c '[] t

         ) =>
         AdditiveGroup m c (ComputationT c t m (D c '[] t)) (ComputationT c t m (D c '[] t)) t where
  (-) ::
       ComputationT c t m (D c '[] t)
    -> ComputationT c t m (D c '[] t)
    -> ComputationT c t m (D c '[] t)
  (-) a b = do
    ca <- a
    cb <- negate b
    binOp Add ca cb

instance (IsMonOp Negate s r a) => MonOp s Negate r a where
  {-# INLINE fd #-}
  fd _ a = monOp Negate a
  {-# INLINE df #-}
  df _ _ _ at = monOp Negate at


class (P.Monad m, P.AdditiveInvertible t, IsMonOp Negate c r t, SameMonad a a m) =>
      AdditiveInvertible m c r a t | a -> t, a -> r, a -> c where
  negate :: a -> ComputationT c t m (D c (MonCalcShape r) t)


instance (P.Monad m, P.AdditiveInvertible t, IsMonOp Negate c r t) =>
         AdditiveInvertible m c r (ComputationT c t m (D c r t)) t where
  negate ::
       ComputationT c t m (D c r t)
    -> ComputationT c t m (D c r t)
  negate a = do
    ca <- a
    monOp Negate ca

instance (P.Monad m, P.AdditiveInvertible t, IsMonOp Negate c s t) =>
         AdditiveInvertible m c s (D c s t) t where
  negate a = monOp Negate a


instance (P.Additive t, P.AdditiveInvertible t, Dim.Dimensions ar) => MonBaseOp Negate ar t where
  type MonCalcShape ar = ar
  baseOpMon _ (D v)  = D $ P.negate v
  baseOpMon _ (Dm v) = Dm $ P.negate v

instance (Operable c r a) => Trace c Negate r a

class (P.Monad m, IsBinOp c Add (GetShape a) (GetShape b) t, GetShape b ~ '[]) =>
      AdditiveModule m c a b t | a -> t, b -> t, a b -> t, a b -> c where
  infixl 6 .+
  (.+) ::  a -> b -> ComputationT c t m (D c (BinCalcShape (GetShape a) (GetShape b)) t)
  infixl 6 +.
  (+.) :: b -> a -> ComputationT c t m (D c (BinCalcShape  (GetShape a) (GetShape b)) t)

instance (P.Monad m, IsBinOp c Add ar '[] t) =>
         AdditiveModule m c (ComputationT c t m (D c ar t)) (D c '[] t) t where
  (.+) ::
       (ComputationT c t m (D c ar t))
    -> (D c '[] t)
    -> ComputationT c t m (D c (BinCalcShape ar '[]) t)
  (.+) a b = do
    ca <- a
    binOp Add ca b
  (+.) ::
       (D c '[] t)
    -> (ComputationT c t m (D c ar t))
    -> ComputationT c t m (D c (BinCalcShape ar '[]) t)
  (+.) b a = do
    ca <- a
    binOp Add ca b

instance (P.Monad m, IsBinOp c Add ar '[] t) =>
         AdditiveModule m c (ComputationT c t m (D c ar t)) (ComputationT c t m (D c '[] t)) t where
  (.+) ::
       (ComputationT c t m (D c ar t))
    -> (ComputationT c t m (D c '[] t))
    -> ComputationT c t m (D c (BinCalcShape ar '[]) t)
  (.+) a b = do
    ca <- a
    cb <- b
    binOp Add ca cb
  (+.) ::
       (ComputationT c t m (D c '[] t))
    -> (ComputationT c t m (D c ar t))
    -> ComputationT c t m (D c (BinCalcShape '[] ar) t)
  (+.) a b = do
    ca <- a
    cb <- b
    binOp Add cb ca

instance (P.Monad m, IsBinOp c Add ar '[] t) =>
         AdditiveModule m c (D c ar t) (D c '[] t) t where
  (.+) a b = binOp Add a b
  (+.) a b = binOp Add b a

instance (P.Monad m, IsBinOp c Add ar '[] t) =>
         AdditiveModule m c (D c ar t) (ComputationT c t m (D c '[] t)) t where
  (.+) ::
       (D c ar t)
    -> (ComputationT c t m (D c '[] t))
    -> ComputationT c t m (D c (BinCalcShape ar '[]) t)
  (.+) a b = do
    cb <- b
    binOp Add a cb
  (+.) ::
       (ComputationT c t m (D c '[] t))
    -> (D c ar t)
    -> ComputationT c t m (D c (BinCalcShape ar '[]) t)
  (+.) b a = do
    cb <- b
    binOp Add a cb

class ( AdditiveModule m c a b t
      , AdditiveInvertible m c (GetShape a) a t
      , AdditiveInvertible m c (GetShape b) b t
      , GetShape b ~ '[]
      , SameMonad a b m
      ) =>
      AdditiveGroupModule m c a b t | a -> t, b -> t, a b -> t, a b -> c where
  infixl 6 .-
  (.-) ::
       a
    -> b
    -> ComputationT c t m (D c (BinCalcShape (GetShape a) (MonCalcShape (GetShape b))) t)
  infixl 6 -.
  (-.) ::
       b
    -> a
    -> ComputationT c t m (D c (BinCalcShape (GetShape a) (MonCalcShape (GetShape b))) t)


instance ( P.Monad m
         , IsMonOp Negate c ar t
         , IsMonOp Negate c '[] t
         , IsBinOp c Add ar '[] t
         , P.AdditiveInvertible t,MonCalcShape '[] ~ '[]
         ) =>
         AdditiveGroupModule m c (D c ar t) (D c '[] t) t where
  (.-) a b = do
    cb <- monOp Negate b
    binOp Add a cb
  (-.) a b = do
    cb <- monOp Negate b
    binOp Add a cb

instance ( P.Monad m
         , IsMonOp Negate c ar t
         , IsMonOp Negate c '[] t
         , IsBinOp c Add ar '[] t
         , P.AdditiveInvertible t,MonCalcShape '[] ~ '[]
         ) =>
         AdditiveGroupModule m c (D c ar t) (ComputationT c t m (D c '[] t)) t where
  (.-) ::
       D c ar t
    -> (ComputationT c t m (D c '[] t))
    -> ComputationT c t m (D c (BinCalcShape ar (MonCalcShape '[])) t)
  (.-) a cb = do
    b <- cb
    nb <- monOp Negate b
    binOp Add a nb
  (-.) ::
       (ComputationT c t m (D c '[] t))
    -> D c ar t
    -> ComputationT c t m (D c (BinCalcShape ar (MonCalcShape '[])) t)
  (-.) cb a = do
    b <- cb
    nb <- monOp Negate b
    binOp Add a nb

instance ( P.Monad m
         , IsMonOp Negate c ar t
         , IsMonOp Negate c '[] t
         , IsBinOp c Add ar '[] t
         , P.AdditiveInvertible t,MonCalcShape '[] ~ '[]
         ) =>
         AdditiveGroupModule m c (ComputationT c t m (D c ar t)) (D c '[] t) t where
  (.-) ::
       (ComputationT c t m (D c ar t))
    -> D c '[] t
    -> ComputationT c t m (D c (BinCalcShape ar (MonCalcShape '[])) t)
  (.-) a b = do
    ca <- a
    cb <- monOp Negate b
    binOp Add ca cb
  (-.) ::
       D c '[] t
    -> (ComputationT c t m (D c ar t))
    -> ComputationT c t m (D c (BinCalcShape ar (MonCalcShape '[])) t)
  (-.) b a = do
    ca <- a
    cb <- monOp Negate b
    binOp Add ca cb

instance ( P.Monad m
         , IsMonOp Negate c ar t
         , IsMonOp Negate c '[] t
         , IsBinOp c Add ar '[] t
         , P.AdditiveInvertible t,MonCalcShape '[] ~ '[]
         ) =>
         AdditiveGroupModule m c (ComputationT c t m (D c ar t)) (ComputationT c t m (D c '[] t)) t where
  (.-) ::
       (ComputationT c t m (D c ar t))
    -> (ComputationT c t m (D c '[] t))
    -> ComputationT c t m (D c (BinCalcShape ar (MonCalcShape '[])) t)
  (.-) a cb = do
    ca <- a
    b <- cb
    nb <- monOp Negate b
    binOp Add ca nb
  (-.) ::
       (ComputationT c t m (D c '[] t))
    -> (ComputationT c t m (D c ar t))
    -> ComputationT c t m (D c (BinCalcShape ar (MonCalcShape '[])) t)
  (-.) cb a = do
    ca <- a
    b <- cb
    nb <- monOp Negate b
    binOp Add ca nb

class (SameMonad a b m) => 
      AdditiveBasis m c r a b t | a b -> r, a b -> t, a b -> c where
  infixl 7 .+.
  (.+.) :: a -> b -> ComputationT c t m (D c r t)

instance (P.Monad m, IsBinOp c Add s s t) =>
         AdditiveBasis m c s (D c s t) (D c s t) t where
  (.+.) a b =
    binOp Add a b


instance (P.Monad m, IsBinOp c Add s s t) =>
         AdditiveBasis m c s (D c s t) (ComputationT c t m (D c s t)) t where
  (.+.) ::
       (D c s t) -> ComputationT c t m (D c s t) -> ComputationT c t m (D c s t)
  (.+.) a b = do
    cb <- b
    binOp Add a cb


instance (P.Monad m, IsBinOp c Add s s t) =>
         AdditiveBasis m c s (ComputationT c t m (D c s t)) (D c s t) t where
  (.+.) ::
       ComputationT c t m (D c s t) -> (D c s t) -> ComputationT c t m (D c s t)
  (.+.) a b = do
    ca <- a
    binOp Add ca b


instance (P.Monad m, IsBinOp c Add s s t) =>
         AdditiveBasis m c s (ComputationT c t m (D c s t)) (ComputationT c t m (D c s t)) t where
  (.+.) ::
       ComputationT c t m (D c s t)
    -> ComputationT c t m (D c s t)
    -> ComputationT c t m (D c s t)
  (.+.) a b = do
    ca <- a
    cb <- b
    binOp Add ca cb




-- | element by element subtraction
--
-- > a .-. a = singleton zero
class ( P.Monad m
      , IsBinOp c Add r r t
      , IsMonOp Negate c r t
      , r ~ BinCalcShape (GetShape a) (GetShape b)
      , GetShape a ~ MonCalcShape (GetShape a)
      , r ~ MonCalcShape r
      , GetShape a ~ GetShape b
      , SameMonad a b m
      , AdditiveInvertible m c r b t
      )=>
      AdditiveGroupBasis m c r a b t | a b -> r, a b -> t, a b -> c where
  infixl 6 .-.
  (.-.) :: a -> b -> ComputationT c t m (D c r t)

instance ( P.Monad m
         , IsBinOp c Add s s t
         , P.AdditiveInvertible t,IsMonOp Negate c s t
         , s ~ MonCalcShape s
         ) =>
         AdditiveGroupBasis m c s (D c s t) (D c s t) t where
  (.-.) a b = do
    cb <- monOp Negate b
    binOp Add a cb


instance ( P.Monad m
         , IsBinOp c Add s s t
         , IsMonOp Negate c s t
         , s ~ MonCalcShape s
         
         , AdditiveInvertible m c s (ComputationT c t m (D c s t)) t
         ) =>
         AdditiveGroupBasis m c s (D c s t) (ComputationT c t m (D c s t)) t where
  (.-.) ::
       (D c s t)
    -> ComputationT c t m (D c s t)
    -> ComputationT c t m (D c s t)
  (.-.) a cb = do
    b <- cb
    nb <- monOp Negate b
    binOp Add a nb


instance ( P.Monad m
         , P.AdditiveInvertible t
         , IsBinOp c Add s s t
         , IsMonOp Negate c s t
         , s ~ MonCalcShape s
         , AdditiveBasis m c s (D c s t) ((ComputationT c t m (D c s t))) t
         , AdditiveBasis m c s ((ComputationT c t m (D c s t))) (D c s t) t
         ) =>
         AdditiveGroupBasis m c s (ComputationT c t m (D c s t)) (D c s t) t where
  (.-.) ::
       ComputationT c t m (D c s t) -> (D c s t) -> ComputationT c t m (D c s t)
  (.-.) a b = do
    ca <- a
    cb <- monOp Negate b
    binOp Add ca cb


instance ( P.Monad m
         , IsBinOp c Add s s t
         , IsMonOp Negate c s t
         , s ~ MonCalcShape s
         , AdditiveInvertible m c s (ComputationT c t m (D c s t)) t
         , AdditiveBasis m c s (D c s t) ((ComputationT c t m (D c s t))) t
         , AdditiveBasis m c s ((ComputationT c t m (D c s t))) (D c s t) t
         ) =>
         AdditiveGroupBasis m c s (ComputationT c t m (D c s t)) (ComputationT c t m (D c s t)) t where
  (.-.) ::
       ComputationT c t m (D c s t)
    -> ComputationT c t m (D c s t)
    -> ComputationT c t m (D c s t)
  (.-.) a cb = do
    ca <- a
    b <- cb
    nb <- monOp Negate b
    binOp Add ca nb

-- sum ::
--      ( Additive m c a b t
--      , P.Foldable f
--      )
--   => f (D c s t)
--   -> (ComputationT c t m (D c s t))
-- sum = P.foldr (.+.) zeros

-- tmp = compute $ grad' (\x -> negate ((D 1.0 :: D [] '[] P.Float) +. x)) ([0..] :: D [] '[3,4,5] P.Float)
