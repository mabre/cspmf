#!/bin/bash

java -Xss16m -Xmx2g -cp frege.jar:build:Libraries/commons-cli-1.3.1.jar frege.main.Main "$@"
