{-# LANGUAGE UnicodeSyntax #-}
module Monad.ModelCheck where

import           Control.Distributed.Process
import           Control.Monad.Trans.Class   (lift)
import           Control.Monad.Trans.State   hiding (State, get, put)
import           Data.Function.Unicode
import qualified Data.HashTable.IO           as H
import           Data.Maybe                  (fromJust)
import           Prelude                     hiding (lookup)
import           Types


-- Assignment of a truth value to a formula at a state.
type Assignment = (State, Form, Bool)

-- The model checking monad allows access to & modification of truth values of formulae in the model.
-- Access is performed by a direct lookup in a hashtable assigned to this process.
-- Modification implies sending the new update to all other model checking processes.
type HashTable = H.BasicHashTable (State, Form) Bool

data ModelCheckState = ModelCheckState {
    checkPeers ∷ [ProcessId]
  , checkState ∷ HashTable
  }

type ModelCheck = StateT ModelCheckState Process

-- Put a single assignment into the store.
put ∷ Assignment → ModelCheck ()
put a = putMany [a]

-- Or, put many.
putMany ∷ [Assignment] → ModelCheck ()
putMany as = do
  broadcastMany as
  insertMany as

-- Broadcast the new assgiments to all the other model-checking processes.
broadcastMany ∷ [Assignment] → ModelCheck ()
broadcastMany a = withPeers $ mapM_ (`send` a)

-- Blockingly performs lookup in the assignment store. If the assignment we're looking for is not present,
-- we keep processing incoming assignments from other processes until it arrives.
get ∷ State → Form → ModelCheck Bool
get s ϕ = do
  x ← lookup s ϕ
  case x of
    Just a  → return a
    Nothing → do
      processInput
      get s ϕ

-- To process input, we first block until at least one input is available.
-- Then we process all the remaining input in the inbox.
processInput = processOneInput >> processRemainingInput

processOneInput ∷ ModelCheck ()
processOneInput = do
  a ← lift $ expect
  insertMany a

processRemainingInput ∷ ModelCheck ()
processRemainingInput = do
  a ← lift $ expectTimeout 0
  case a of
    Just a' → do
      insertMany a'
      processRemainingInput
    Nothing → return ()

-- Convenience wrappers.
withPeers ∷ ([ProcessId] → Process ()) → ModelCheck ()
withPeers f = gets checkPeers >>= lift ∘ f

withTable ∷ (HashTable → IO α) → ModelCheck α
withTable f = gets checkState >>= liftIO ∘ f

-- Direct operations on the assignment store.
lookup ∷ State → Form → ModelCheck (Maybe Bool)
lookup s ϕ = withTable $ \t → H.lookup t (s, ϕ)

insert ∷ Assignment → ModelCheck ()
insert (s, ϕ, v) = withTable $ \t → H.insert t (s, ϕ) v

insertMany ∷ [Assignment] → ModelCheck ()
insertMany = mapM_ insert