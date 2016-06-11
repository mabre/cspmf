#!/bin/bash

# Modifies the given Haskell output file from Alex such that it can 
# be compiled with Frege. The file modification date of the frege 
# file will be the modification date of the corresponding x-file.
# $1: Haskell file
# $2: Frege command, including classpath

outfile="${1%.*}.fr"
xfile="${1%.*}.x"

grep -v "^#" $1                             | # remove cpp includes starting with #
    sed "s/\t/        /"                    | # alex generates tabs!?
    grep -vE "^(\(|scanner|\))$"            | # remove export lines
    sed "s/^import qualified /import /"     | # remove qualified keyword (not needed)
    grep -v "(unsafeAt)"                    | # remove unneeded imports
    grep -v "import Array"                  |
    sed "s/^where$/where\nimport frege.Prelude hiding (Byte)/" | # AlexWrapper.Byte shadows Lang.Byte
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
    sed "s/_ -> alex_/else alex_/" > $outfile

# split long arrays to prevent "code too large" message from JVM
for array in "alex_table" "alex_check"; do
    line=`grep "$array = " $outfile`
    name=`echo "$line" | cut -d " " -f2`
    ints=`echo "$line" | sed -E "s/.*\[(.*)\].*/\1/"`
    splitted=`$2 ArraySplitter $name $ints`
    if [ $? -ne 0 ]; then
        exit 1
    fi
    splitted=`echo "$splitted" | sed "s/\"//g"`
    newlines=`echo "$line" | cut -d " " -f1-5`" $ $splitted"
    esc_line=`echo "$line" | sed -e 's/[][]/\\\\&/g'`
    esc_newlines=`echo "$newlines" | sed -e 's/[][]/\\\\&/g'`
    sed -i "s/$esc_line/$esc_newlines/" $outfile
done

touch -r $xfile $outfile
