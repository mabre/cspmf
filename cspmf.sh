#!/bin/bash

java -Xss16m -Xmx2g -jar dist/frege.jar -cp dist frege.main.Main "$@"
