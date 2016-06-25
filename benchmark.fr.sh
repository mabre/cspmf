#!/bin/bash

source ./make.config.sh

$java -Xss16m -Xmx2g -XX:MaxJavaStackTraceDepth=1000000 -cp $fregejar:build:Libraries/commons-cli-1.3.1.jar frege.main.Benchmark "$@"
