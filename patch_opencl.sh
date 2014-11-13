#!/bin/bash

# Yosemite 10.10

sudo perl -i.bak -pe 's|([\xFF\xFC\x3D])\x86\x80\x12\x04|$1\x86\x80\x16\x0A|sg' /System/Library/Frameworks/OpenCL.framework/Libraries/libCLVMIGILPlugin.dylib
