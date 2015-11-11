## Lenovo Haswell U330/U430/U530 DSDT patches by RehabMan

This set of patches/makefile can be used to patch your Lenovo U330/U430/U530 Touch(and p) DSDT/SSDTs.  There are also post install scripts that can be used to create and install the kexts the are required for this laptop series.

Although older versions of the repo had scripts to automate patching of DSDT/SSDTs, the current version does it all via config.plist hotpatching and SSDT-HACK.

Please refer to this guide thread on tonymacx86.com for a step-by-step process, feedback, and questions:

http://www.tonymacx86.com/yosemite-laptop-guides/155106-guide-lenovo-ideapad-u330-u430-u530-using-clover-uefi.html


### Change Log:

2015-11-11

- removed FULLPATCH, now using only SSDT-HACK.dsl

- remove config_iris.plist, injections done (smartly) in SSDT-HACK

- disable EHCI#1 controller, use XHC only

2015-10-xx

- various updates for 10.11

- transition to SSDT-HACK and dynamic patching/injection

2015-04-20

- update AppleHDA script

- update AppleHDA_ALC283.kext to 10.10.3

- install VoodooPS2Daemon in install_downloads.sh

- remove extra line out from AppleHDA PathMaps

- simulate as Windows 2012 (Windows 8) instead of Windows 2006

2015-03-29

- add "gray" tagging to files installed to /S/L/E and /Applications

2015-03-26

- instead of deleting _PRW objects, add them back but with sleep state 0.  This eliminates the disrupting call to the associated _GPE event during the sleep process.

- use "Windows 2012" instead of "Windows 2006".  This makes USB2 devices connect to AppleUSBEHCI instead of AppleUSBEHCI.

2015-03-06

- add new WiFi+Bluetooth option BCM94352HMB

2015-02-23

- use "one-shot" PS2 notify methods to PS2K.  This eliminates a problem with F9.

2015-01-28

- update for Yosemite 10.10.2

2015-01-21

- add "9mb cursor bytes" patch.  Eliminates glitches with 1080p screens such as on the u530.

2015-01-08

- using OEM provided CPU power management SSDTs
- using FakePCIID for HD4400 and WiFi (instead of binary patching)

2014-11-12

- Updated for AppleUSBXHCI.kext
- rebranded native WiFi
- and updated patches/config.plist

2014-03-23 Initial Release

