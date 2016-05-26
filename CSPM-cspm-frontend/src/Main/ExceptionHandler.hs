----------------------------------------------------------------------------
-- |
-- Module      :  Main.ExceptionHandler
-- Copyright   :  (c) Fontaine 2011
-- License     :  BSD3
--
-- Maintainer  :  Fontaine@cs.uni-duesseldorf.de
-- Stability   :  experimental
-- Portability :  GHC-only
--
-- ExceptionHandler for the command line interface
----------------------------------------------------------------------------

module Main.ExceptionHandler

where

import Language.CSPM.Parser (ParseError, ParseErrorException)
import Language.CSPM.Token (LexError, LexErrorException)
import Language.CSPM.Rename (RenameError, RenameErrorException)
-- import Language.CSPM.Frontend (LexError, ParseError, RenameError) TODO
import Language.CSPM.Token (pprintAlexPosn, Token)
import frege.system.Exit

-- | The top-level exception handler.
handleException :: IO () -> IO ()
handleException x
  = x `catch` lexError
      `catch` parseError
      `catch` renameError
      `catch` someExc
  where
    lexError :: LexErrorException -> IO ()
    lexError lexError = do
      stderr.println "lexError"
      stderr.println $ pprintAlexPosn lexError.get.lexEPos
      stderr.println lexError.get.lexEMsg
      exitFailure
    parseError :: ParseErrorException -> IO ()
    parseError parseError  = do
      stderr.println "parseError"
      stderr.println parseError.get.parseErrorMsg
      stderr.println $ pprintAlexPosn parseError.get.parseErrorPos
      stderr.println $ "at token : " ++ (show parseError.get.parseErrorToken.tokenString)
      exitFailure
    renameError :: RenameErrorException -> IO ()
    renameError renameError = do
      stderr.println "renameError"
      stderr.println renameError.get.renameErrorMsg
      stderr.println $ show renameError.get.renameErrorLoc
      exitFailure
    someExc :: Exception -> IO ()
    someExc err = do
      stderr.println err.getMessage
      exitFailure
