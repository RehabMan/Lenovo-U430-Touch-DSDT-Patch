## Lenovo Haswell U430 DSDT patches by RehabMan

This set of patches/makefile can be used to patch your Lenovo U430 Touch DSDT/SSDTs.  It relies heavily on already existing laptop DSDT patches at github here: https://github.com/RehabMan/Laptop-DSDT-Patch

In fact, you will need to copy/clone that github repository to use this one.  Sorry, many of the laptop patches are generic and there are only a few specific to this laptop and I did not want to end up maintaining two copies of them.  There is already enough of that with the Laptop and ProBook repositories.

Because the ACPI files for this computer are highly dependentent on one another, I have taken a more "developer" approach, opting to use shell scripts and a makefile to process the files automatically.  I generally test out new ideas with MaciASL, but once I determine the final method, I integrate it into the makefile for automatic patching/building/installing.

Note: These patches are for BIOS version 7ccn35ww.

Note: Read this entire README before starting.


### Installation

Refer to this guide for creating your USB and performing the initial installation of Yosemite or Mavericks.

http://www.tonymacx86.com/yosemite-laptop-support/148093-guide-booting-os-x-installer-laptops-clover-uefi.html


### Post-Install Setup:

What you'll need:
- this repo: https://github.com/RehabMan/HP-Lenovo-U430-Touch-DSDT-Patch
- laptop repo: https://github.com/RehabMan/Laptop-DSDT-Patch
- patchmatic: https://github.com/RehabMan/OS-X-MaciASL-patchmatic
- MaciASL: https://github.com/RehabMan/OS-X-MaciASL-patchmatic (always useful, even in this case)
- iasl: https://bitbucket.org/RehabMan/acpica/downloads
- Xcode developer tools
- optional: git

You can get Xcode for free by registering as a developer at developer.apple.com. Or, I think the command line tools will be installed automatically if you attempt to use them (eg. type 'make' in Terminal, and follow the prompts for downloading).

Install the patchmatic and iasl binaries to your path.  I install mine to /usr/bin.  This way they are accessible to the scripts and shell script.  Install/obtain the Xcode developer tools.

I like to use git to setup the directory structure.  The two projects must be setup as siblings. For example:

    mkdir ~/Projects
    cd ~/Projects
    git clone https://github.com/RehabMan/Laptop-DSDT-Patch laptop.git
    git clone https://github.com/RehabMan/Lenovo-U430-Touch-DSDT-Patch u430.git

Now you have the following directory structure:

    ~Projects/laptop.git
    ~Projects/u430.git


### How to use:

In order to create your patched DSDT, you must extract the DSDT and all SSDTs from Linux.  These are available directly in the file system under /sys/firmware/acpi/tables.  Make sure to get the entire directory structure including the /sys/firmware/acpi/tables/dynamic directory.

My files break down as follows (NN = not necessary):
- ssdt1: PTID (NN)
- ssdt2, ssdt3: PM related (NN)
- ssdt4: graphics (will be patching this one)
- ssdt5: ??? (NN)
- ssdt6: IAOE (needed for sleep)
- ssdt7, ssdt8, ssdt9: PM related (NN)

After gathering these files from Linux, place them in the native_linux subdirectory of this project.

Note: You can also extract your native files in OS X using 'patchmatic -extract'.  In fact, if disassemble.sh finds no files in native_linux, it will do this automatically to native_patchmatic.

Now you are ready to disassemble the files we need to patch.  The current code disassembles them all, even though we are only patching two of them (you may be patching more).  To disassemble them, type (in Terminal)

    ./disassemble.sh

After it runs, all disassembled files will be in the current directory (flattened... no more dynamic directory).  You can then inspect them with MaciASL, try to compile them, even patch them by hand to test things out if you want.

At this point you will need to have the laptop repo handy as well.  The makefile assumes that the laptop patches are in a sibling directory to this project: ../laptop.git.  If you didn't use my name for the directory, you'll have to change the makefile as appropriate.

If your files are similar enough to mine, you can probably attempt to patch them now.  To do so, type (in Terminal):

    make patch


This will run 'make' which uses 'makefile' to run 'patchmatic' on the two files that need patching: dsdt.dsl and ssdt4.dsl.  The patched files are placed in the 'patched' subdirectory.

After you have successfully patched the files, they must be built into AML before you can use them.  Normally, you would do this with MaciASL, but in this case you can use make:

    make

This will use iasl to build the files, placing the results in the 'build' subdirectory.  If all went well, there were no errors.  If you have errors, your DSDT/SSDT is slightly different than mine, so you'll have to test the patches out by hand with MaciASL to determine what might need to change.

Assuming you have a valid set of AML files in subdirectory 'build', you can install them with:

    make install


make install: mounts the EFI partition and copies the files to EFI/CLOVER/ACPI/patched (dsdt.aml, ssdt-4.aml, ssdt6.aml)

Note: I do not recommend Chameleon or Chimera.  Save yourself some frustration and use Clover.


Note: All the patching/building/installing could be done with MaciASL, Patch, File Save As, etc.  Refer to the makefile to see what patches from the laptop repo I'm using.  Patches specific to this laptop are located in the 'patches' subdirectory.


### Clover config.plist

There is a config.plist for Clover UEFI configuration.


### Kexts required

These are the kexts I use for this build:

- FakeSMC: https://github.com/RehabMan/OS-X-FakeSMC-kozlek
- VoodooPS2Controller: https://github.com/RehabMan/OS-X-Voodoo-PS2-Controller
- RealtekRTL8111: https://github.com/RehabMan/OS-X-Realtek-Network
- ACPIBacklight: https://github.com/RehabMan/OS-X-ACPI-Backlight
- ACPIBatteryManager: https://github.com/RehabMan/OS-X-ACPI-Battery-Driver
- CodecCommander: https://github.com/RehabMan/EAPD-Codec-Commander
- FakePCIID: https://github.com/RehabMan/OS-X-Fake-PCI-ID
- ACPIDebug (for debugging DSDT/SSDTs only): https://github.com/RehabMan/OS-X-ACPI-Debug

The current version of all kexts can be downloaded with the provided download.sh script:

```
./download.sh
```

The latest version of all files (kexts and tools) will be placed in ./downloads

You can install them automatically with the provided install_downloads.sh:

```
./install_downloads.sh
```


### CPU power management

You should generate a custom SSDT for your CPU.  Use ssdtPRgen.sh script here: https://github.com/Piker-Alpha/ssdtPRGen.sh.


### Audio

The script patch_hda.sh is provided to create an AppleHDA injector for the Realtek ALC283.  You should have vanilla AppleHDA installed in order to run it.  Output from the script is AppleHDA_ALC283.kext which, in conjuction with the config.plist patches, will enable onboard audio.

The output of the script, AppleHDA_ALC283.kext is also checked into the repository.


### WiFi

The Lenovo U430 implemenets a BIOS whitelist.  None of the WiFi cards on the whitelist are compatible with OS X.  But one of the cards that is allowed, an AR946x (168c:0034) is close enough.  

In order to make native WiFi work we use a rebranded AR9280:
- rebrand an AR5BHB92 (AR9280) as 168c:0034 17aa:3114, which are the IDs for the Lenovo WB222 (AR946x).
- use an injector to load the native kext for AR9280
- use FakePCIID.kext to fake the original PCIID

Note: The last two requirements are provided by the single kext FakePCIID_AR9280_as_AR946x.kext from the FakePCIID project.


### Feedback:

Please use this thread on tonymacx86.com for feedback, questions, and help:

Development thread: http://www.tonymacx86.com/laptop-compatibility/121632-lenovo-ideapad-u430-mavericks.html

A mini guide is at post #422: http://www.tonymacx86.com/laptop-compatibility/121632-lenovo-ideapad-u430-mavericks-43.html#post928795

***
New Guide thread: http://www.tonymacx86.com/yosemite-laptop-support/155106-guide-lenovo-ideapad-u330-u430-u530-using-clover-uefi.html


### Known Issues

- The headphone port does not work correctly (issue is in the patched AppleHDA xml files)


### Change Log:

2015-01-08

- using OEM provided CPU power management SSDTs
- using FakePCIID for HD4400 and WiFi (instead of binary patching)

2014-11-12

- Updated for AppleUSBXHCI.kext
- rebranded native WiFi
- and updated patches/config.plist

2014-03-23 Initial Release

