#!/usr/bin/env runhaskell

import Language.CSPM.Frontend

import System.Environment

--- The first argument is the name of a cspm file.
--- Reads the file, parses it, and writes the ast to out_hs.
main = do
    args <- getArgs
    ast <- parseFile $ head args
    writeFile "out_hs" (show ast)
    return "ok"
