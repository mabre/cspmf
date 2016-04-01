-----------------------------------------------------------------------------
-- |
-- Module      :  Language.CSPM.Utils
-- Copyright   :  (c) Fontaine 2008
-- License     :  BSD
-- 
-- Maintainer  :  fontaine@cs.uni-duesseldorf.de
-- Stability   :  experimental
-- Portability :  GHC-only
--
-- Some Utilities

module UtilsTest

where

import Utils

main _ = do parseFile "/home/markus/Downloads/frege/cspmf/CSPM-Frontend/test/cspm/abp.csp"
            putStrLn "ok"

