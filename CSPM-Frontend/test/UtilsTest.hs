#!/usr/bin/env runhaskell
{-
first argument is the name of cspm-file
read file, parse it and write the result to a File
-}

import Language.CSPM.Frontend

import System.Environment
import System.Cmd
import System.Exit
import System.IO
import Control.Monad

main
  = do
  args <- getArgs
  let fileName = head args
  ast <- parseFile $ head args
  writeFile "out" (show ast)
  return "ok"