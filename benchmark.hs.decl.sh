#!/bin/bash

repetitions=$1
filename=$2
declaration=$3

loopStart=`date +%s%N`
for ((i=0; i<$repetitions; i++)); do
    start=`date +%s%N`
    cspmf translate --declarationToPrologTerm="$declaration" $filename
    end=`date +%s%N`
    runtimes[$i]=$(($end-$start))
done
loopEnd=`date +%s%N`

runtimesSum=0
runtimesSumHalf=0
half=$(($repetitions/2))
for ((i=0; i<$repetitions; i++)); do
  let runtimesSum+=${runtimes[$i]}
  if [ $i -gt $(($repetitions-$half)) ]; then
    let runtimesSumHalf+=${runtimes[$i]}
  fi
done

echo total time: $runtimesSum
echo average time: $(($runtimesSum/$repetitions))
echo average time for second half: $(($runtimesSumHalf/$half))
echo benchmark wallclock time: $(($loopEnd-$loopStart))
