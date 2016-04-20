module LexHelperTest where

import Language.CSPM.LexHelper
import Language.CSPM.Token
import Language.CSPM.TokenClasses

import Data.Ix
import Data.Array
import Language.CSPM.UnicodeSymbols

main' _ = print $ [minbound..maxBound] -- TODO NOTE strange

minbound :: PrimToken
minbound = PrimToken.minBound

-- table :: Array.Array PrimToken (Maybe (Char,String))
-- table = (Array.//)
--               (Array.listArray (minBound,maxBound) $ repeat Nothing) -- TODO NOTE Not lazy enough?
--               [(tok,Just (uni,ascii)) | (uni,tok,ascii) <- unicodeSymbols]

main _ = putStrLn $ unlines
  [ getAbsoluteIncludeFileName "../user/file.csp" "system/file.csp"
  , getAbsoluteIncludeFileName "/user/file.csp" "../file.csp"
  , unicodeTokenString $ Token (TokenId 42) (AlexPn 11 12 13) (2) (T_rhd) ("[>")
  , unicodeTokenString $ Token (TokenId 42) (AlexPn 11 12 13) (2) (T_eq) ("==")
  , unicodeTokenString $ Token (TokenId 42) (AlexPn 11 12 13) (1) (T_hash) ("#")
  , asciiTokenString $ Token (TokenId 42) (AlexPn 11 12 13) (1) (T_hash) ("#")
  , asciiTokenString $ Token (TokenId 42) (AlexPn 11 12 13) (1) (T_eq) ("====")]
