-----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.Token
-- Copyright   :  (c) Fontaine 2008
-- License     :  BSD
-- 
-- Maintainer  :  Fontaine@cs.uni-duesseldorf.de
-- Stability   :  provisional
-- Portability :  GHC-only
--
-- This module contains the data type Tokens and some helper functions


module Language.CSPM.Token
where

import Language.CSPM.TokenClasses

import Data.Data
--import Data.Ix TODO?

{-# derive DataTypeable #-}
data TokenId = TokenId {unTokenId :: Int}
derive Show TokenId
derive Eq TokenId
derive Ord TokenId

mkTokenId :: Int -> TokenId
mkTokenId = TokenId

{-# derive DataTypeable #-}
data AlexPosn = ! AlexPn {
   alexPos :: Int
  ,alexLine   :: Int 
  ,alexCol    :: Int
  }
derive Eq AlexPosn
derive Ord AlexPosn
derive Show AlexPosn

pprintAlexPosn :: AlexPosn -> String
pprintAlexPosn (AlexPn _p l c) = "Line: "++show l++" Col: "++show c

alexStartPos :: AlexPosn
alexStartPos = AlexPn 0 1 1

alexMove :: AlexPosn -> Char -> AlexPosn
alexMove (AlexPn a l _c) '\n' = AlexPn (a+1) (l+1)   1
alexMove (AlexPn a l c) _    = AlexPn (a+1)  l     (c+1)

{-# derive DataTypeable #-}
data LexError = ! LexError {
   lexEPos :: AlexPosn
  ,lexEMsg :: String
  }
derive Show LexError

data LexErrorException = pure native frege.language.CSPM.LexErrorException where
    pure native new new         :: LexError -> LexErrorException
    pure native get getLexError :: LexErrorException -> LexError
derive Exceptional LexErrorException

{-# derive DataTypeable #-}
data Token = Token
  { tokenId     :: TokenId
  , tokenStart  :: AlexPosn
  , tokenLen    :: Int
  , tokenClass  :: PrimToken
  , tokenString :: String
  }
derive Show Token
derive Eq Token
derive Ord Token

tokenSentinel :: Token
tokenSentinel = Token
  { tokenId = mkTokenId (- 1)
  , tokenStart = AlexPn 0 0 0
  , tokenLen = 0
  , tokenClass  = error "CSPLexer.x illegal access tokenSentinel"
  , tokenString = error "CSPLexer.x illegal access tokenSentinel"}

showPosn :: AlexPosn -> String
showPosn (AlexPn _ line col) = show line ++ ":" ++ show col

showToken :: Token -> String
showToken Token {tokenString = str} = "'" ++ str ++ "'"

-- Code generated by DataDeriver
tc_TokenId :: TyCon
tc_TokenId = mkTyCon3 "Language.CSPM" "Token" "TokenId"
instance Typeable (TokenId ) where
    typeOf _ = mkTyConApp tc_TokenId []
con_TokenId_TokenId :: Constr
con_TokenId_TokenId = mkConstr ty_TokenId "con_TokenId_TokenId" [] Prefix
ty_TokenId :: DataType
ty_TokenId = mkDataType "Language.CSPM.Token.TokenId" [con_TokenId_TokenId]
instance Data (TokenId ) where
    toConstr (TokenId _) = con_TokenId_TokenId
    dataTypeOf _ = ty_TokenId
    gunfold k z c = case constrIndex c of
                         1 -> k (z TokenId)
                         _ -> error "gunfold(TokenId)"
    gfoldl f z x = case x of
                         (TokenId a1) -> (z TokenId) `f` a1

tc_AlexPosn :: TyCon
tc_AlexPosn = mkTyCon3 "Language.CSPM" "Token" "AlexPosn"
instance Typeable (AlexPosn ) where
    typeOf _ = mkTyConApp tc_AlexPosn []
con_AlexPosn_AlexPn :: Constr
con_AlexPosn_AlexPn = mkConstr ty_AlexPosn "con_AlexPosn_AlexPn" [] Prefix
ty_AlexPosn :: DataType
ty_AlexPosn = mkDataType "Language.CSPM.Token.AlexPosn" [con_AlexPosn_AlexPn]
instance Data (AlexPosn ) where
    toConstr (AlexPn _ _ _) = con_AlexPosn_AlexPn
    dataTypeOf _ = ty_AlexPosn
    gunfold k z c = case constrIndex c of
                         1 -> k (k (k (z AlexPn)))
                         _ -> error "gunfold(AlexPosn)"
    gfoldl f z x = case x of
                         (AlexPn a1 a2 a3) -> (((z AlexPn) `f` a1) `f` a2) `f` a3

tc_LexError :: TyCon
tc_LexError = mkTyCon3 "Language.CSPM" "Token" "LexError"
instance Typeable (LexError ) where
    typeOf _ = mkTyConApp tc_LexError []
con_LexError_LexError :: Constr
con_LexError_LexError = mkConstr ty_LexError "con_LexError_LexError" [] Prefix
ty_LexError :: DataType
ty_LexError = mkDataType "Language.CSPM.Token.LexError" [con_LexError_LexError]
instance Data (LexError ) where
    toConstr (LexError _ _) = con_LexError_LexError
    dataTypeOf _ = ty_LexError
    gunfold k z c = case constrIndex c of
                         1 -> k (k (z LexError))
                         _ -> error "gunfold(LexError)"
    gfoldl f z x = case x of
                         (LexError a1 a2) -> ((z LexError) `f` a1) `f` a2

tc_Token :: TyCon
tc_Token = mkTyCon3 "Language.CSPM" "Token" "Token"
instance Typeable (Token ) where
    typeOf _ = mkTyConApp tc_Token []
con_Token_Token :: Constr
con_Token_Token = mkConstr ty_Token "con_Token_Token" [] Prefix
ty_Token :: DataType
ty_Token = mkDataType "Language.CSPM.Token.Token" [con_Token_Token]
instance Data (Token ) where
    toConstr (Token _ _ _ _ _) = con_Token_Token
    dataTypeOf _ = ty_Token
    gunfold k z c = case constrIndex c of
                         1 -> k (k (k (k (k (z Token)))))
                         _ -> error "gunfold(Token)"
    gfoldl f z x = case x of
                         (Token a1 a2 a3 a4 a5) -> (((((z Token) `f` a1) `f` a2) `f` a3) `f` a4) `f` a5
