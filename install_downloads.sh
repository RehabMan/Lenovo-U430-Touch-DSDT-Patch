#set -x

function install
{
    installed=0
    out=${1/.zip/}
    rm -Rf $out/* && unzip -q -d $out $1
    if [ -d $out/Release/*.kext ]; then
        echo installing $out/Release/*.kext to /System/Library/Extensions
        for kext in $out/Release/*.kext; do
            sudo rm -Rf /System/Library/Extensions/`basename $kext`
        done
        sudo cp -Rf $out/Release/*.kext /System/Library/Extensions
        installed=1
    fi
    if [ -d $out/*.kext ]; then
        echo installing $out/*.kext to /System/Library/Extensions
        for kext in $out/*.kext; do
            sudo rm -Rf /System/Library/Extensions/`basename $kext`
        done
        sudo cp -Rf $out/*.kext /System/Library/Extensions
        installed=1
    fi
    if [ -d $out/Release/*.app ]; then
        echo installing $out/Release/*.app to /Applications
        for app in $out/Release/*.app; do
            sudo rm -Rf /Applications/`basename $app`
        done
        sudo cp -Rf $out/Release/*.app /Applications
        installed=1
    fi
    if [ -d $out/*.app ]; then
        echo installing $out/*.app to /Applications
        for app in $out/*.app; do
            sudo rm -Rf /Applications/`basename $app`
        done
        sudo cp -Rf $out/*.app /Applications
        installed=1
    fi
    if [ $installed -eq 0 ]; then
        echo installing $out/* to /usr/bin
        for tool in $out/*; do
            sudo rm /usr/bin/`basename $tool`
        done
        sudo cp -f $out/* /usr/bin
    fi
}

if [ "$(id -u)" != "0" ]; then
    echo "This script requires superuser access to install"
fi

# unzip/install kexts
if [ -d ./downloads/kexts ]; then
    echo Installing kexts...
    cd ./downloads/kexts
    for kext in *.zip; do
        install $kext
    done
    cd ../..
fi
# force cache rebuild with output
sudo touch /System/Library/Extensions
sudo kextcache -u /

# unzip/install tools
if [ -d ./downloads/tools ]; then
    echo Installing tools...
    cd ./downloads/tools
    for tool in *.zip; do
        install $tool
    done
    cd ../..
fi