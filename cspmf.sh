#!/bin/bash

source ./make.config.sh

$java -Xss16m -Xmx2g -cp $fregejar:build:Libraries/commons-cli-1.3.1.jar Main "$@"
