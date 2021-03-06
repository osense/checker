module Types.Tree where


-- Just a general tree structure, a.k.a. Multi-way or Rose tree.
data Tree a = Node a [Tree a] | Jump a
  deriving (Show)

instance Functor Tree where
  fmap f (Node x ns) = Node (f x) (map (fmap f) ns)
  fmap f (Jump x )   = Jump (f x)

instance Foldable Tree where
  foldMap f (Node x ns) = (f x) `mappend` (mconcat $ map (foldMap f) ns)
  foldMap f (Jump x)    = (f x)

instance Traversable Tree where
  traverse f (Node x ns) = Node <$> f x <*> (sequenceA $ map (traverse f) ns)
  traverse f (Jump x)    = Jump <$> f x
