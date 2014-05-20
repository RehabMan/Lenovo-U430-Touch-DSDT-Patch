#!/bin/bash

#set -x

codec=ALC283
unpatched=/System/Library/Extensions

# AppleHDA patching function
function createAppleHDAInjector()
{
# create AppleHDA injector for Clover setup...
    echo -n "Creating AppleHDA injector for $1..."
    cp -R $unpatched/AppleHDA.kext/ AppleHDA_$1.kext
    rm -R AppleHDA_$1.kext/Contents/Resources/*
    rm -R AppleHDA_$1.kext/Contents/PlugIns
    rm -R AppleHDA_$1.kext/Contents/_CodeSignature
    rm -R AppleHDA_$1.kext/Contents/MacOS/AppleHDA
    rm AppleHDA_$1.kext/Contents/version.plist
    ln -s /System/Library/Extensions/AppleHDA.kext/Contents/MacOS/AppleHDA AppleHDA_$1.kext/Contents/MacOS/AppleHDA
    cp ./Resources/layout/*.zlib AppleHDA_$1.kext/Contents/Resources/
    plist=AppleHDA_$1.kext/Contents/Info.plist
    replace=`/usr/libexec/plistbuddy -c "Print :NSHumanReadableCopyright" $plist | perl -pi -e 's/(\d*\.\d*\.\d*)/900\1/g'`
    /usr/libexec/plistbuddy -c "Set :NSHumanReadableCopyright '$replace'" $plist
    replace=`/usr/libexec/plistbuddy -c "Print :CFBundleGetInfoString" $plist | perl -pi -e 's/(\d*\.\d*\.\d*)/900\1/g'`
    /usr/libexec/plistbuddy -c "Set :CFBundleGetInfoString '$replace'" $plist
    replace=`/usr/libexec/plistbuddy -c "Print :CFBundleVersion" $plist | perl -pi -e 's/(\d*\.\d*\.\d*)/900\1/g'`
    /usr/libexec/plistbuddy -c "Set :CFBundleVersion '$replace'" $plist
    replace=`/usr/libexec/plistbuddy -c "Print :CFBundleShortVersionString" $plist | perl -pi -e 's/(\d*\.\d*\.\d*)/900\1/g'`
    /usr/libexec/plistbuddy -c "Set :CFBundleShortVersionString '$replace'" $plist
    /usr/libexec/plistbuddy -c "Add ':HardwareConfigDriver_Temp' dict" $plist
    /usr/libexec/plistbuddy -c "Merge $unpatched/AppleHDA.kext/Contents/PlugIns/AppleHDAHardwareConfigDriver.kext/Contents/Info.plist ':HardwareConfigDriver_Temp'" $plist
    /usr/libexec/plistbuddy -c "Copy ':HardwareConfigDriver_Temp:IOKitPersonalities:HDA Hardware Config Resource' ':IOKitPersonalities:HDA Hardware Config Resource'" $plist
    /usr/libexec/plistbuddy -c "Delete ':HardwareConfigDriver_Temp'" $plist
    /usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:HDAConfigDefault'" $plist
    /usr/libexec/plistbuddy -c "Delete ':IOKitPersonalities:HDA Hardware Config Resource:PostConstructionInitialization'" $plist
    /usr/libexec/plistbuddy -c "Add ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' integer" $plist
    /usr/libexec/plistbuddy -c "Set ':IOKitPersonalities:HDA Hardware Config Resource:IOProbeScore' 2000" $plist
    /usr/libexec/plistbuddy -c "Merge ./Resources/ahhcd.plist ':IOKitPersonalities:HDA Hardware Config Resource'" $plist
    echo " Done."
}

rm -R AppleHDA_$codec.kext
createAppleHDAInjector "$codec"
