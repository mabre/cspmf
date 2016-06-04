#!/bin/bash

build_dir="../build"

source ../make.config.sh

mkdir $build_dir 2> /dev/null

step "Compiling CSPM-cspm-frontend"
$fregec -d $build_dir -make -sp src/Main ExecCommand.fr ExceptionHandler.fr
success fregec $?
$javac -d $build_dir -cp $build_dir:$fregejar:../Libraries/commons-cli-1.3.1.jar src/Main/Main.java src/Main/Benchmark.java
success javac $?
