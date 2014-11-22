#set -x

function install
{
    installed=0
    out=${1/.zip/}
    rm -Rf $out/* && unzip -q -d $out $1
    if [ -d $out/Release/*.kext ]; then
        echo sudo cp $out/Release/*.kext /System/Library/Extensions
        installed=1
    fi
    if [ -d $out/*.kext ]; then
        echo sudo cp $out/*.kext /System/Library/Extensions
        installed=1
    fi
    if [ -d $out/Release/*.app ]; then
        echo sudo cp $out/Release/*.app /Applications
        installed=1
    fi
    if [ -d $out/*.app ]; then
        echo sudo cp $out/*.app /Applications
        installed=1
    fi
    if [ $installed -eq 0 ]; then
        echo sudo cp $out/* /usr/bin
    fi
}

if [ "$(id -u)" != "0" ]; then
    echo "This script requires superuser access to install"
fi

# unzip/install kexts
if [ -d ./downloads/kexts ]; then
    echo kexts...
    cd ./downloads/kexts
    for kext in *.zip; do
        install $kext
    done
    cd ../..
fi
# force cache rebuild with output
echo sudo touch /System/Library/Extensions
echo sudo kextcache -u /

# unzip/install tools
if [ -d ./downloads/tools ]; then
    echo tools...
    cd ./downloads/tools
    for tool in *.zip; do
        install $tool
    done
    cd ../..
fi