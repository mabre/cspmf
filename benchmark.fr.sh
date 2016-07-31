#!/bin/bash

# 50 runs of --prologOut for a file
# $ ./benchmark.fr.sh prologOut 50 CSPM-Frontend/test/cspm/very_simple.csp
# 50 runs of --translateDecl for a file
# TODO do we reuse the ast for each run?
# $ ./benchmark.fr.sh translateDecl 50 CSPM-Frontend/test/cspm/very_simple.csp "N=42"
java -Xss16m -Xmx2g -XX:MaxJavaStackTraceDepth=1000000 -cp cspmf.jar frege.main.Benchmark "$@"
