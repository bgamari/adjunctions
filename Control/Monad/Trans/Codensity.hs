{-# LANGUAGE Rank2Types #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Monad.Trans.CodensityT
-- Copyright   :  (C) 2008-2011 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  non-portable (rank-2 polymorphism)
--
----------------------------------------------------------------------------
module Control.Monad.Trans.CodensityT
  ( CodensityT(..)
  , lowerCodensityT
  , codensityTToAdjunction
  , adjunctionToCodensityT
  ) where

import Control.Applicative
import Control.Monad (ap)
import Data.Functor.Adjunction
import Data.Functor.Apply
import Control.Monad.Trans.Class

{-
type Codensity = CodensityT Identity
codensity :: (forall b. (a -> b) -> b) -> Codensity a
runCodensity :: Codensity a -> (a -> b) -> a
-}

newtype CodensityT m a = CodensityT { runCodensityT :: forall b. (a -> m b) -> m b }

instance Functor (CodensityT k) where
  fmap f (CodensityT m) = CodensityT (\k -> m (k . f))

instance Apply (CodensityT f) where
  (<.>) = ap

instance Applicative (CodensityT f) where
  pure x = CodensityT (\k -> k x)
  (<*>) = ap

instance Monad (CodensityT f) where
  return x = CodensityT (\k -> k x)
  m >>= k = CodensityT (\c -> runCodensityT m (\a -> runCodensityT (k a) c))

{-
instance MonadIO m => MonadIO (CodensityT m) where
  liftIO = liftCodensityT . liftIO 
-}

instance MonadTrans CodensityT where
  lift m = CodensityT (m >>=)

lowerCodensityT :: Monad m => CodensityT m a -> m a
lowerCodensityT a = runCodensityT a return

codensityTToAdjunction :: Adjunction f g => CodensityT g a -> g (f a)
codensityTToAdjunction r = runCodensityT r unit

adjunctionToCodensityT :: Adjunction f g => g (f a) -> CodensityT g a
adjunctionToCodensityT f = CodensityT (\a -> fmap (rightAdjunct a) f)