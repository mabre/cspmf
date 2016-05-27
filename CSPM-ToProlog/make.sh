#!/bin/bash

build_dir="../build"

source ../make.config.sh

mkdir $build_dir 2> /dev/null

step "Compiling CSPM-ToProlog"
$fregec -d $build_dir -make src/Language/CSPM/CompileAstToProlog.fr src/Language/CSPM/TranslateTest.fr src/Language/CSPM/TranslateToProlog.fr src/Language/Prolog/PrettyPrint/Direct.fr
success fregec $?
