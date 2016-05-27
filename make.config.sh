#!/bin/bash

javac="javac"
java="java"
fregejar="/home/markus/Downloads/frege/fregec.jar"
alex="/home/markus/.cabal/bin/alex"

frege_compiler_options="-hints -O"

frege="$java -Xss16m -Xmx2g -cp $fregejar:../build:./build"
fregec="$java -Xss16m -Xmx2g -jar $fregejar $frege_compiler_options"

bold=$(tput bold)
red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

function step() {
    echo "$bold*** $1 ***$normal"
}

function success() {
    if [ $2 -eq 0 ]; then
        echo "$green $1 ok $normal"
    else
        echo "$red*** $1 process exited with $2, aborting $normal"
        exit $2
    fi
}
