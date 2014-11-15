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

if [ -d native_patchmatic ]; then
    cp ./native_patchmatic/*.aml ./tmp
else
    cp ./native_linux/DSDT ./native_linux/SSDT* ./native_linux/dynamic/SSDT* ./tmp
    chmod +w ./tmp/*
fi

cd ./tmp
list=`echo *`

rm ../unpatched/*.dsl
for aml in $list; do
    iasl -p ../unpatched/${aml//.aml/}.dsl -e ${list//$aml/} -d -dl $aml
done

cd ..
rm -R tmp
