#!/bin/bash

if [ ! $# -eq  2 ]; then
    echo "Usage: ./compareRecords.bash file1 file2"
    echo
    echo "Sloppy comparison of printed records from Haskell and Frege given in file1 and file2 by removing record labels, brackets, braces, parenthesis and standardize boolean constants."
    exit 0
fi

cat $1 | tr "{}" "()" | sed -Ee "s/([ \(])[A-Za-z]* = /\1/g" | sed -e "s/\}//g" | sed -Ee "s/  +/ /g" | sed "s/false/False/g" | sed "s/true/True/g" > /tmp/out_hs
cat $2 | tr "{}" "()" | sed -Ee "s/([ \(])[A-Za-z]* = /\1/g" | sed -e "s/\}//g" | sed -Ee "s/  +/ /g" | sed "s/false/False/g" | sed "s/true/True/g" > /tmp/out_fr

cat /tmp/out_hs | tr "()[]," " " | sed -Ee "s/ +/\n/g" > /tmp/out_hs_
cat /tmp/out_fr | tr "()[]," " " | sed -Ee "s/ +/\n/g" > /tmp/out_fr_

diff /tmp/out_hs_ /tmp/out_fr_
