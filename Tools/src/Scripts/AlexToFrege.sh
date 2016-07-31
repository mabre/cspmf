#!/bin/bash

# Modifies the given Haskell output file from Alex such that it can 
# be compiled with Frege. The file modification date of the frege 
# file will be the modification date of the corresponding x-file.
# $1: Haskell file created by Alex 3.1.7

outfile="${1%.*}.fr"
xfile="${1%.*}.x"

grep -v "^#" $1                             | # remove cpp includes starting with #
    sed "s/^import qualified /import /"     | # remove qualified keyword (not needed)
    grep -v "(unsafeAt)"                    | # remove unneeded imports
    grep -v "import Array"                  |
    sed "s/!AlexInput/AlexInput/"           | # remove strictness flags
    sed "s/!Int/Int/"                       |
    sed "s/ ! / !! /"                       | # replace Array.! with Array.!!
    sed "s/| AlexError/| !AlexError/"       | # add strictness where supported by frege
    sed "s/| AlexSkip/| !AlexSkip/"         | # (mixed like AlexToken !AlexInput !Int is not supported)
    sed "s/tokenClass tok/tok.tokenClass/"  | # change record access syntax
    sed -E "s/^([a-z])/private \1/"         | # make everything private
    sed -E "s/private (module|where|import|scanner|data|instance|type)/\1/" |
    sed "s/case new_s of/if new_s == -1/"   | # workaround for frege bug #26 (Pattern support)
    sed "s/(-1) ->/then/"                   |
    sed -E 's/(alex_table|alex_check)(.*)\[(.*)\]/\1\2(unJust (parseJSON "\[\3\]"))/' | # prevent "code too large" message from JVM (#287)
    sed "s/_ -> alex_/else alex_/" > $outfile

# set modification date of frege file to date of x file
# (prevents unnecessary recompilations of this and depending modules)
touch -r $xfile $outfile
