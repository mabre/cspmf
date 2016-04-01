#!/bin/bash

mv test_ast.log test_ast.log~
for f in $(ls cspm/*.csp cspm/*.fdr2); do
    STARTTIME=$(date +%s)
    java -Xss16m -Xmx2g -cp ../src/Language/CSPM/build/:../../../fregec.jar UtilsTest $f
    ENDTIME=$(date +%s)
    S=$(date +%s)
    ./UtilsTest $f
    E=$(date +%s)
    out=`echo $f | sed s/cspm/ast_fr/`.ast
    ref=out
    mv out_fr $out
    echo $(($ENDTIME - $STARTTIME)) $(($E - $S)) $f | tee -a test_ast.log
    cp $out out_fr
#     cp $ref out
    bash compare.bash | tee -a test_ast.log
    echo | tee -a test_ast.log
#     exit 42
done
