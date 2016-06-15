#!/bin/bash

java -Xss16m -Xmx2g -cp dist frege.main.Main "$@"
