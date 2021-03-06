module Semantics where

import           Data.Function.Unicode
import           Data.List             (find, partition)
import           Data.Maybe            (fromJust)
import           Types


successors ∷ State → Tree State
successors = reachableWith stateNext

predecessors ∷ State → Tree State
predecessors = reachableWith statePrev

reachableWith ∷ (State → [State]) → State → Tree State
reachableWith f = reachableWith' f []

-- `col` keeps track of the states already collected on the path between
-- the current node and the root of the tree. In other words, states may
-- be duplicated in the tree, but on any given path from the root to a leaf,
-- every state is unique. This guarantees finitness.
reachableWith' ∷ (State → [State]) → [State] → State → Tree State
reachableWith' f col x = Node x $ (map Jump leaves) ++ (map (reachableWith' f col') nodes)
  where
    col'            = x : col
    (nodes, leaves) = partition (not ∘ (`elem` col')) (f x)


-- Unsafe.
getStateById ∷ Model → StateId → State
getStateById m s = fromJust $ lookupStateById m s

lookupStateById ∷ Model → StateId → Maybe State
lookupStateById (Model m) s = find ((== s) ∘ getStateId) m
