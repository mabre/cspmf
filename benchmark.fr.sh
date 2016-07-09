#!/bin/bash
FREGEJAR=`grep ^FREGEJAR Makefile | sed "s/.* = *//"`
BUILD=`grep "^BUILD " Makefile | sed "s/.* = *//"`
JAVA=`grep "^JAVA " Makefile | sed "s/.* = *//"`

$JAVA -Xss16m -Xmx2g -XX:MaxJavaStackTraceDepth=1000000 -cp $FREGEJAR:$BUILD:Libraries/commons-cli-1.3.1.jar frege.main.Benchmark "$@"
