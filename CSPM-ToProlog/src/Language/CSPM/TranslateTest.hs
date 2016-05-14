module TranslateTest where

import Language.CSPM.TranslateToProlog

-- main = translateExpToPrologTerm Nothing "1+2"
-- '+'('int'(1),'int'(1)).

main = translateToProlog "/home/markus/Downloads/frege/cspmf/CSPM-Frontend/test/cspm/peterson.csp" "/tmp/peterson.frege.pl"
