#!/bin/bash
#set -x

EXCEPTIONS=
ESSENTIAL="FakePCIID_AR9280_as_AR946x.kext AppleALC.kext"
HDA=ALC283

# include subroutines
DIR=$(dirname ${BASH_SOURCE[0]})
source "$DIR/tools/_install_subs.sh"

warn_about_superuser

# install tools
install_tools

# remove old kexts
remove_deprecated_kexts
# EHCI is disabled, so no need for FakePCIID_XHCIMux.kext
remove_kext FakePCIID_XHCIMux.kext
# USBXHC_u430 is not used anymore
remove_kext USBXHC_u430.kext

# using AppleALC.kext, remove patched zml.zlib files
sudo rm -f /System/Library/Extensions/AppleHDA.kext/Contents/Resources/*.zml.zlib

# install required kexts
install_download_kexts
install_brcmpatchram_kexts
install_backlight_kexts

# install special download kexts
install_kext _downloads/kexts/RehabMan-FakePCIID*/Release/FakePCIID_AR9280_as_AR946x.kext

# all kexts are now installed, so rebuild cache
rebuild_kernel_cache

# update kexts on EFI/CLOVER/kexts/Other
update_efi_kexts

# VoodooPS2Daemon is deprecated
remove_voodoops2daemon

#EOF
