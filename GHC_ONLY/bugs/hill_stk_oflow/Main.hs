{- Without strictness analysis, this program runs in constants
   space, giving non-termination.
   With strictness analysis, the recursive call to final is not
   a tail call, so stack overflow results.
-}

module Main where

main = print (final nums)

nums :: [Int]
nums = fromn 1

fromn :: Int -> [Int]
fromn n = n : fromn (n+1)

final :: [Int] -> Int
final (a:l) = seq (force a) (final l)

force :: Int -> Int
force a | a == a = a

seq :: Int -> Int -> Int
seq a b | a == a = b
