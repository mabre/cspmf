#!/bin/bash

java -Xss16m -Xmx2g -cp dist:dist/frege.jar:dist/commons-cli.jar frege.main.Main "$@"
