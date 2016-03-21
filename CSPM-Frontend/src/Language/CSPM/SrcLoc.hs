{-# OPTIONS_GHC -fno-warn-warnings-deprecations #-}
-- {-# LANGUAGE DeriveDataTypeable #-}
-- DeriveGeneric
-----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.SrcLoc
-- Copyright   :  (c) Fontaine 2008
-- License     :  BSD
-- 
-- Maintainer  :  Fontaine@cs.uni-duesseldorf.de
-- Stability   :  provisional
-- Portability :  GHC-only
--
-- This module contains the datatype for sourcelocations and some utility functions.

module SrcLoc
where

import Token --as Token

import Data.List
-- import Data.Typeable (Typeable)
-- import Data.Generics.Basics (Data)
-- import GHC.Generics (Generic)
-- import Data.Generics.Instances ()

{-  todo : simplify this -}
data SrcLoc
  = TokIdPos TokenId
  | TokIdSpan TokenId TokenId
  | TokSpan Token Token -- the spans are closed intervals
                        -- single token with token x :: TokSpan x x
  | TokPos Token
  | NoLocation
  | ! FixedLoc {
      fixedStartLine   :: Int
     ,fixedStartCol    :: Int
     ,fixedStartOffset :: Int
     ,fixedLen         :: Int
     ,fixedEndLine     :: Int
     ,fixedEndCol      :: Int
     ,fixedEndOffset   :: Int
   }
derive Show SrcLoc
derive Eq SrcLoc
derive Ord SrcLoc

mkTokSpan :: Token -> Token -> SrcLoc
mkTokSpan = TokSpan

mkTokPos :: Token -> SrcLoc
mkTokPos = TokPos

type SrcLine = Int
type SrcCol  = Int
type SrcOffset  = Int

getStartLine :: SrcLoc -> SrcLine
getStartLine x = case x of
  TokSpan s _e  -> s.tokenStart.alexLine
  TokPos t      -> t.tokenStart.alexLine
  FixedLoc {}   -> x.fixedStartLine
  _ -> error "no SrcLine Availabel"

getStartCol :: SrcLoc -> SrcCol
getStartCol x = case x of
  TokSpan s _e  -> s.tokenStart.alexCol
  TokPos t      -> t.tokenStart.alexCol
  FixedLoc {}   -> x.fixedStartCol
  _ -> error "no SrcCol Availabel"

getStartOffset :: SrcLoc -> SrcOffset
getStartOffset x = case x of
  TokSpan s _e  -> s.tokenStart.alexPos
  TokPos t      -> t.tokenStart.alexPos
  FixedLoc {}   -> x.fixedStartOffset
  _ ->  error "no SrcOffset available"

getTokenLen :: SrcLoc -> SrcOffset
getTokenLen x = case x of
  TokPos t -> t.tokenLen
  TokSpan s e   -> (e.tokenStart.alexPos) - (s.tokenStart.alexPos) + e.tokenLen
  FixedLoc {}  -> x.fixedLen
  _ -> error "getTokenLen : info not available"

getEndLine :: SrcLoc -> SrcLine
getEndLine x = case x of
  TokSpan _s e  -> AlexPosn.alexLine $ computeEndPos e
  TokPos t -> AlexPosn.alexLine $ computeEndPos t
  FixedLoc {}  -> SrcLoc.fixedEndLine x
  _ ->   error "no SrcLine available"

getEndCol :: SrcLoc -> SrcCol
getEndCol x = case x of
  TokSpan _s e  -> AlexPosn.alexCol $ computeEndPos e
  TokPos t -> AlexPosn.alexCol $ computeEndPos t
  FixedLoc {}  -> SrcLoc.fixedEndCol x
  _ ->  error "no SrcCol available"

getEndOffset :: SrcLoc -> SrcOffset
getEndOffset x = case x of
  TokSpan _s e  -> (e.tokenStart.alexPos) + e.tokenLen
  TokPos t -> (t.tokenStart.alexPos) + t.tokenLen
  FixedLoc {}  -> x.fixedEndOffset
  _ ->  error "no SrcOffset available"

getStartTokenId :: SrcLoc -> TokenId
getStartTokenId s = case s of
  TokIdPos x -> x
  TokIdSpan x _ -> x
  TokSpan x _   -> Token.tokenId x
  TokPos x -> Token.tokenId x
  _ -> error "no startTokenId available"

getEndTokenId :: SrcLoc -> TokenId
getEndTokenId s = case s of
  TokIdPos x -> x
  TokIdSpan _ x -> x
  TokSpan _ x   -> Token.tokenId x
  TokPos x -> Token.tokenId x
  _ -> error "no endTokenId available"

getStartToken :: SrcLoc -> Token
getStartToken s = case s of
  TokSpan x _   -> x
  TokPos x -> x
  _ -> error "SrcLoc: no startToken available"

getEndToken :: SrcLoc -> Token
getEndToken s = case s of
  TokSpan _ x   -> x
  TokPos x -> x
  _ -> error "SrcLoc: no endToken available"


computeEndPos :: Token -> AlexPosn
computeEndPos t = foldl' alexMove (t.tokenStart) (unpacked (t.tokenString)) -- TODO string performance?


{-# DEPRECATED srcLocFromTo "sourceLoc arithmetics is not reliable" #-}
-- this is the closed Interval between s and e
srcLocFromTo :: SrcLoc -> SrcLoc -> SrcLoc
srcLocFromTo NoLocation _ = NoLocation
srcLocFromTo _ NoLocation = NoLocation
srcLocFromTo (TokSpan s _) (TokSpan _ e) = TokSpan s e
srcLocFromTo s e = FixedLoc {
   fixedStartLine   = getStartLine s
  ,fixedStartCol    = getStartCol s
  ,fixedStartOffset = getStartOffset s
  ,fixedLen         = getEndOffset e - getStartOffset s
  ,fixedEndLine     = getEndLine e
  ,fixedEndCol      = getEndCol e
  ,fixedEndOffset   = getEndOffset e
   }

{-# DEPRECATED srcLocBetween "sourceLoc arithmetics is not reliable" #-}
-- this is the open Interval between s and e
srcLocBetween :: SrcLoc -> SrcLoc -> SrcLoc
srcLocBetween NoLocation _ = NoLocation
srcLocBetween _ NoLocation = NoLocation
srcLocBetween s e = FixedLoc {
   fixedStartLine   = getEndLine s
  ,fixedStartCol    = getEndCol s + 1     -- maybe wrong when token at end of Line
  ,fixedStartOffset = getStartOffset s + getTokenLen s
  ,fixedLen         = getEndOffset e - getStartOffset s
  ,fixedEndLine     = getStartLine e
  ,fixedEndCol      = getStartCol e -1    -- maybe wrong when startCol = 0
  ,fixedEndOffset   = getStartOffset e
   }
