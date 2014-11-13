#!/bin/bash

# disassemble.sh
#
# Creates DSL files from raw Linux extract
#
# Part of DSDT paching process for Haswell Lenovo u430 Touch
#
# Created by RehabMan
#

set -x

if [ ! -d "tmp" ]; then
    mkdir ./tmp
fi
if [ -e tmp/* ]; then
    rm ./tmp/*
fi

cp ./linux_native/DSDT ./linux_native/SSDT* ./linux_native/dynamic/SSDT* ./tmp
chmod +w ./tmp/*
cd ./tmp
list=`echo *`

for aml in $list; do
    iasl -p ../unpatched/$aml.dsl -e ${list//$aml/} -d -dl $aml
done

cd ..
rm -R tmp
