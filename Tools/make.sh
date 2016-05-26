#!/bin/bash

build_dir="../build"

source ../make.config.sh

mkdir $build_dir 2> /dev/null

step "Compiling Tools"
$fregec -d $build_dir -make src/ArraySplitter/Main.fr src/DataDeriver/AST.fr src/DataDeriver/Deriver.fr src/DataDeriver/Main.fr src/DataDeriver/Parser.fr src/DataDeriver/Preprocessor.fr
success fregec $?
