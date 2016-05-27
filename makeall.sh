#!/bin/bash

source ./make.config.sh

start=`date +%s`

cd Libraries
./make.sh
success Libraries $?
cd ..

cd Tools
./make.sh
success Tools $?
cd ..

cd CSPM-Frontend
./make.sh
success CSPM-Frontend $?
cd ..

cd CSPM-ToProlog
./make.sh
success CSPM-ToProlog $?
cd ..

cd CSPM-cspm-frontend
./make.sh
success CSPM-cspm-frontend $?
cd ..

end=`date +%s`

echo $((end-start)) wallclock seconds
