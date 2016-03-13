----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.AlexWrapper
-- 
-- Stability   :  experimental
-- Portability :  GHC-only
--
-- Wrapper functions for Alex

{-# LANGUAGE RecordWildCards, CPP #-}
module AlexWrapper
where

import Token
import TokenClasses

import Data.Char
-- import Data.Word (Word8)
import Data.Bits
import Data.List

-- #if __GLASGOW_HASKELL__ >= 710
-- import qualified Control.Monad (ap)
-- #endif

type AlexInput = (AlexPosn,     -- current position,
                  Char,         -- previous char
                  [Int],       -- pending bytes on current char
                  String)       -- current input string

type Byte = Int

data AlexState = AlexState {
   alex_input :: AlexInput
  ,!alex_scd :: Int 	-- the current startcode
  ,!alex_cnt :: Int 	-- number of tokens
  }

runAlex :: String -> Alex a -> Either LexError a
runAlex input (Alex f) 
  = case f initState of
     Left msg -> Left msg
     Right ( _, a ) -> Right a
  where
    initState
      = AlexState {
       alex_input = initAlexInput
      ,alex_scd = 0
      ,alex_cnt = 0
      }
    initAlexInput = (alexStartPos,'\n',[],input)

data Alex a = Alex { unAlex :: AlexState -> Either LexError (AlexState, a) }

-- #if __GLASGOW_HASKELL__ >= 710
-- instance Functor Alex where
--   fmap f m = do x <- m; return (f x)
-- 
-- instance Applicative Alex where
--   pure = return
--   (<*>) = Control.Monad.ap
-- #endif

instance Monad Alex where
  m >>= k  = Alex $ \s -> case Alex.unAlex m s of
                            Left msg -> Left msg
                            Right (s',a) -> Alex.unAlex (k a) s'
  return a = Alex $ \s -> Right (s,a)

alexGetInput :: Alex AlexInput
alexGetInput
  = Alex $ \s-> Right (s, s.alex_input)

alexSetInput :: AlexInput -> Alex ()
alexSetInput input
   = Alex $ \state -> case state.{alex_input=input} of
            (s@(AlexState{})) -> Right (s, ())

alexError :: String -> Alex a
alexError message = Alex $ \st -> let (pos,_a,_b,_c) = (st.alex_input) in
                                      Left $ LexError {lexEPos = pos, lexEMsg = message}

alexGetStartCode :: Alex Int
alexGetStartCode = Alex $ \(s@AlexState{alex_scd=sc}) -> Right (s, sc)

alexSetStartCode :: Int -> Alex ()
alexSetStartCode sc = Alex $ \s -> Right (s.{alex_scd=sc}, ())

-- increase token counter and return tokenCount
alexCountToken :: Alex Int
alexCountToken
  = Alex $ \s -> Right (s.{alex_cnt = succ $ s.alex_cnt}, s.alex_cnt)

-- taken from original Alex-Wrapper
alexGetByte :: AlexInput -> Maybe (Byte,AlexInput)
alexGetByte (p,c,(b:bs),s) = Just (b,(p,c,bs,s))
alexGetByte (_,_,[],"") = Nothing
alexGetByte (p,_,[],(cs))   = let (c,s) = (head cs, tail cs)
                                  p' = alexMove p c 
                                  (b:bs) = utf8Encode c
                              in p' `seq`  Just (b, (p', c, bs, s))

utf8Encode :: Char -> [Int]
utf8Encode = map fromIntegral . go . ord
 where
  go oc
   | oc <= 0x7f       = [oc]

   | oc <= 0x7ff      = [ 0xc0 + (shiftR oc 6)
                        , 0x80 + oc .&. 0x3f
                        ]

   | oc <= 0xffff     = [ 0xe0 + (shiftR oc 12)
                        , 0x80 + ((shiftR oc 6) .&. 0x3f)
                        , 0x80 + oc .&. 0x3f
                        ]
   | otherwise        = [ 0xf0 + (shiftR oc 18)
                        , 0x80 + ((shiftR oc 12) .&. 0x3f)
                        , 0x80 + ((shiftR oc 6) .&. 0x3f)
                        , 0x80 + oc .&. 0x3f
                        ]


-- Useful token actions
type AlexAction result = AlexInput -> Int -> result

-- perform an action for this token, and set the start code to a new value
andBegin :: (t -> t1 -> Alex b) -> Int -> t -> t1 -> Alex b
andBegin action code input len = do alexSetStartCode code; action input len

mkL :: PrimToken -> AlexInput -> Int -> Alex Token
mkL c (pos, _, _, str) len = do
  cnt <- alexCountToken
  return $ Token {
    tokenId     = mkTokenId cnt
  , tokenStart  = pos
  , tokenLen    = len
  , tokenClass  = c
  , tokenString = take len str
  }

block_comment :: AlexInput -> Int -> Alex Token
block_comment (startPos, _ ,[], input') 2 = do
    let input = tail $ tail input'
    if (head input' /= '{' && head (tail input') /= '-')
    then error "internal Error : block_comment called with bad args"
    else case go 1 "-{" input of
      Nothing -> Alex $ \_-> Left $ LexError {
        lexEPos = startPos
        ,lexEMsg = "Unclosed Blockcomment"
        }
      Just (acc, rest) -> do
       cnt <- alexCountToken
       let
        tokenId = mkTokenId cnt
        tokenString = reverse' acc
        tokenLen = length tokenString
        tokenStart = startPos
        tokenClass = case (tokenString, toList acc) of
            ('{':'-':'#':_, '}':'-':'#':_) ->  L_Pragma
            ('{':'-':_    , '}':'-':_    ) ->  L_BComment
            _ -> error "internal Error: cannot determine variant of block_comment"
       alexSetInput (foldl' alexMove startPos tokenString, '\125', [],rest)
       return $ Token {tokenId=tokenId, tokenStart=tokenStart, tokenLen=tokenLen, tokenClass=tokenClass, tokenString = packed tokenString}
  where
    go :: Int -> String -> String -> Maybe (String,String)
    go 0 acc rest = Just (acc, rest)
    go nested acc rest =case toList rest of
      '-' : '}' : r2 -> go (pred nested) ("}-" ++ acc) (packed r2)
      '{' : '-'  : r2 -> go (succ nested) ("-{" ++ acc) (packed r2)
      h:r2 -> go nested (ctos h ++ acc) (packed r2)
      [] -> Nothing
    reverse' :: String -> [Char]
    reverse' = reverse . toList

block_comment _ _ = error "internal Error : block_comment called with bad args"

stringchars :: AlexInput -> Int -> Alex Token
stringchars (startPos, _, [], input') 1 = do
    let input = tail input'
    case go 1 "\"" input of
      Nothing -> Alex $ \_-> Left $ LexError {
         lexEPos = startPos
        ,lexEMsg = "Unclosed String"
        }
      Just (acc, rest) -> do
        cnt <- alexCountToken
        let
          tokenId = mkTokenId cnt
          tokenString = reverse' acc
          tokenLen = length tokenString
          tokenStart = startPos
          tokenClass = case (head tokenString, head acc) of
               ('\"', '\"') ->  L_String
               _ -> error "internal Error: cannot determine variant of string"
        alexSetInput (foldl' alexMove startPos tokenString, '\"', [],rest)
        return $ Token {tokenId=tokenId, tokenStart=tokenStart, tokenLen=tokenLen, tokenClass=tokenClass, tokenString = packed tokenString}
  where
    go :: Int -> String -> String -> Maybe (String,String)
    go 0 acc rest = Just (acc, rest)
    go nested acc rest = case toList rest of
      '\"' : r2 -> go (pred nested) ("\"" ++ acc) (packed r2)
      '\"' : r2 -> go (succ nested) ("\"" ++ acc) (packed r2)
      h:r2 -> go nested (ctos h ++ acc) (packed r2)
      [] -> Nothing
    reverse' :: String -> [Char]
    reverse' = reverse . toList

lexError :: String -> Alex a
lexError s = do
  (_p, _c,_, input) <- alexGetInput
  let
    pos = if not $ null input
            then " at " ++ (reportChar $ head input)
            else " at end of file"
  alexError $ s ++ pos
 where
    reportChar c =
     if isPrint c
       then show c
       else "charcode " ++ (show $ ord c)

alexEOF :: Alex Token
alexEOF = return (Token (mkTokenId 0) (AlexPn 0 0 0) 0 L_EOF "")

alexInputPrevChar :: AlexInput -> Char
alexInputPrevChar (_p, _c, _,_s) = error "alex-input-prev-char not supported ??!"
