#!/bin/bash

java -Xss16m -Xmx2g -cp ../frege3.24.100.jar:build324:Libraries/commons-cli-1.3.1.jar frege.main.Main "$@"
