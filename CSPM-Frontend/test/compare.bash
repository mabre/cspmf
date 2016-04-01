#!/bin/bash

cat out | tr "{}" "()" | sed -Ee "s/([ \(])[A-Za-z]* = /\1/g" | sed -e "s/\}//g" | sed -Ee "s/  +/ /g" | sed "s/false/False/g" | sed "s/true/True/g" > out_hs
cat out_fr | tr "{}" "()" | sed -Ee "s/([ \(])[A-Za-z]* = /\1/g" | sed -e "s/\}//g" | sed -Ee "s/  +/ /g" | sed "s/false/False/g" | sed "s/true/True/g" > out_fr-
mv out_fr- out_fr

cat out_hs | tr "()[]," " " | sed -Ee "s/ +/\n/g" > out_hs_
cat out_fr | tr "()[]," " " | sed -Ee "s/ +/\n/g" > out_fr_

diff out_hs_ out_fr_
