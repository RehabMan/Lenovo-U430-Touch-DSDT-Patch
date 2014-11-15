## Lenovo Haswell U430 DSDT patches by RehabMan

This set of patches/makefile can be used to patch your Lenovo U430 Touch DSDT/SSDTs.  It relies heavily on already existing laptop DSDT patches at github here: https://github.com/RehabMan/Laptop-DSDT-Patch

In fact, you will need to copy/clone that github repository to use this one.  Sorry, many of the laptop patches are generic and there are only a few specific to this laptop and I did not want to end up maintaining two copies of them.  There is already enough of that with the Laptop and ProBook repositories.

Because the ACPI files for this computer are highly dependentent on one another, I have taken a more "developer" approach, opting to use shell scripts and a makefile to process the files automatically.  I generally test out new ideas with MaciASL, but once I determine the final method, I integrate it into the makefile for automatic patching/building/installing.

Note: These patches are for BIOS version 7ccn35ww.


### Setup:

What you'll need:
- this repo: https://github.com/RehabMan/HP-Lenovo-U430-Touch-DSDT-Patch
- laptop repo: https://github.com/RehabMan/Laptop-DSDT-Patch
- patchmatic: https://github.com/RehabMan/OS-X-MaciASL-patchmatic
- MaciASL: https://github.com/RehabMan/OS-X-MaciASL-patchmatic (always useful, even in this case)
- Xcode developer tools
- iasl: https://bitbucket.org/RehabMan/acpica/downloads
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

You will need to inspect your files, especially if your laptop is of a different configuration than mine.  For example, you may have two graphics SSDTs if your laptop has the nvidia chip.  Mine does not, so ssdt4 contains the graphics code for Intel HD4600.  If you have nvidia, you will probably want to patch the SSDT that contains the code for it, to disable it since it is useless in OS X.

After gathering these files from Linux, place them in the native_linux subdirectory of this project.

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

or

    make install_extra


make install: mounts /dev/disk0s1 as EFI volume and copies the files to EFI/CLOVER/ACPI/patched (dsdt.aml, ssdt-4.aml, ssdt6.aml)
make install_extra: copies to /Extra (dsdt.aml, ssdt-1.aml)

Obviously 'make install' is used for Clover, and 'make install_extra' is used for Chameleon.

Note: I do not recommend Chimera or Chameleon.  Save yourself some frustration and use Clover.


Note: All the patching/building/installing could be done with MaciASL, Patch, File Save As, etc.  Refer to the makefile to see what patches from the laptop repo I'm using.  Patches specific to this laptop are located in the 'patches' subdirectory.


### Clover config.plist

There is a config.plist for Clover UEFI configuration.


### Audio

The script patch_hda.sh is provided to create an AppleHDA injector for the Realtek ALC283.  You should have vanilla AppleHDA installed in order to run it.  Output from the script is AppleHDA_ALC283.kext which, in conjuction with the config.plist patches, will enable onboard audio.

The output of the script, AppleHDA_ALC283.kext is also checked into the repository.


### WiFi

The Lenovo U430 implemenets a BIOS whitelist.  None of the WiFi cards on the whitelist are compatible with OS X.  But one of the cards that is allowed, an AR946x (168c:0034) is close enough.  

In order to make native WiFi work we use a rebranded AR9280:
- rebrand an AR5BHB92 (AR9280) as 168c:0034 17aa:3114, which are the IDs for the Lenovo WB222 (AR946x).
- use an injector to load the native kext for AR9280
- patch the kext (using Clover config.plist patches) to make the kext treat it as AR9280

The injector, AirPort_AR9280_as_AR946x.kext, is provided in this repository.  Due to the nature of the patches, they are in the provided config.plist, but disabled.  Unless you actually have an AR9280 branded as an AR946x installed, do not enable the patches.  If you do have the rebranded hardware installed, WiFi will not work until you enable the patches in your config.plist.


### Other Kexts required

These are the kexts I use for this build:

- FakeSMC: https://github.com/RehabMan/OS-X-FakeSMC-kozlek
- VoodooPS2Controller: https://github.com/RehabMan/OS-X-Voodoo-PS2-Controller
- RealtekRTL8111: https://github.com/RehabMan/OS-X-Realtek-Network
- ACPIBacklight: https://github.com/RehabMan/OS-X-ACPI-Backlight
- ACPIBatteryManager: https://github.com/RehabMan/OS-X-ACPI-Battery-Driver
- CodecCommander: https://github.com/RehabMan/EAPD-Codec-Commander
- ACPIDebug (for debugging DSDT/SSDTs only): https://github.com/RehabMan/OS-X-ACPI-Debug


### Other patching

Although HD4600 is supported by Yosemite, it is not supported by one of the OpenCL framework's dylib.

You can use patch_opencl.sh:

    ./patch_opencl.sh

Background: http://www.tonymacx86.com/yosemite-laptop-support/145427-fix-intel-hd4400-hd4600-mobile-yosemite.html

### CPU power management

You should generate a custom SSDT for your CPU.  Use ssdtPRgen.sh script here: https://github.com/Piker-Alpha/ssdtPRGen.sh

Note: I find the best results with both APSS/ACST injections via the ssdtPRgen.sh script and Clover's SSDT/Generate options.'


### Feedback:

Please use this thread on tonymacx86.com for feedback, questions, and help:

Development thread: http://www.tonymacx86.com/laptop-compatibility/121632-lenovo-ideapad-u430-mavericks.html

Guide thread: TBD


### Known Issues

- The headphone port does not work correctly (issue is in the 


### Change Log:

2014-11-12 Updated for AppleUSBXHCI.kext, rebranded native WiFi, and updated patches/config.plist

2014-03-23 Initial Release


