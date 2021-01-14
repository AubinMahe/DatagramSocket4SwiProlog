#!/bin/bash

SCRIPT_DIR=$(dirname $0)

cd ${SCRIPT_DIR}
make
ant jar
ant run &
${SCRIPT_DIR}/src/elevatorMain.pl -- --start
