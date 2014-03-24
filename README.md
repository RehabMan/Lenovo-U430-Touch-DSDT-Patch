## Haswell HP Envy DSDT patches by RehabMan

This set of patches/makefile can be used to patch your Haswell HP Envy DSDT/SSDTs.  It relies heavily on already existing laptop DSDT patches at github here: https://github.com/RehabMan/Laptop-DSDT-Patch

In fact, you will need to copy/clone that github repository to use this one.  Sorry, many of the laptop patches are generic and there are only a few specific to this laptop and I did not want to end up maintaining two copies of them.  There is already enough of that with the Laptop and ProBook repositories.

Because the ACPI files for this computer are highly dependentent on one another, I have taken a more "developer" approach, opting to use shell scripts and a makefile to process the files automatically.  I generally test out new ideas with MaciASL, but once I determine the final method, I integrate it into the makefile for automatic patching/building/installing.


### Setup:

What you'll need:
- this repo: https://github.com/RehabMan/HP-Envy-DSDT-Patch
- laptop repo: https://github.com/RehabMan/Laptop-DSDT-Patch
- patchmatic: https://github.com/RehabMan/OS-X-MaciASL-patchmatic
- MaciASL: https://github.com/RehabMan/OS-X-MaciASL-patchmatic (always useful, even in this case)
- Xcode developer tools
- iasl: http://www.tonymacx86.com/attachments/laptop-compatibility/75686d1386006623-would-my-dell-inspiron-17-7000-hackintosh-able-iasl.zip
- optional: git

You can get Xcode for free by registering as a developer at developer.apple.com.  It is free.  Or, I think the command line tools will be installed automatically if you attempt to use them (eg. type 'make' in Terminal, and follow the prompts for downloading).

Install the patchmatic and iasl binaries to your path.  I install mine to /usr/bin.  This way they are accessible to the scripts and shell script.  Install/obtain the Xcode developer tools.

I like to use git to setup the directory structure.  The two projects must be setup as siblings. For example:

```
mkdir ~/Projects
cd ~/Projects
git clone https://github.com/RehabMan/Laptop-DSDT-Patch laptop.git
git clone https://github.com/RehabMan/HP-Envy-DSDT-Patch envy.git
```

Now you have the following directory structure:
Projects/laptop.git
Projects/envy.git


### How to use:

In order to create your patched DSDT, you must extract the DSDT and all SSDTs from Linux.  These are available directly in the file system under /sys/firmware/acpi/tables.  Make sure to get the entire directory structure including the /sys/firmware/acpi/tables/dynamic directory.

My files break down as follows (NN = not necessary):
- ssdt1: PTID (NN)
- ssdt2: PM related (NN)
- ssdt3: PM related (NN)
- ssdt4: graphics (will be patching this one)
- ssdt5: ??? (NN)
- dynamic/ssdt6, dynamic/ssdt7, dynamic/ssdt8: PM related (NN)

You will need to inspect your files, especially if your laptop is of a different configuration than mine.  For example, you may have two graphics SSDTs if your laptop has the nvidia chip.  Mine does not, so ssdt4 contains the graphics code for Intel HD4600.  If you have nvidia, you will probably want to patch the SSDT that contains the code for it, to disable it since it is useless in OS X.

After gathering these files from Linux, place them in the linux_native subdirectory of this project.  I have provided the linux_F24 subdirectory as a reference. The files there are my extracted linux_native files.  Do not use them for your own hack, they are just provided for reference... the case you want to compare them against your own, for example.

Now you are ready to disassemble the files we need to patch.  The current code disassembles them all, even though we are only patching two of them (you may be patching more).  To disassemble them, type (in Terminal)

```
./disassemble.sh
```

After it runs, all disassembled files will be in the current directory (flattened... no more dynamic directory).  You can then inspect them with MaciASL, try to compile them, even patch them by hand to test things out if you want.

At this point you will need to have the laptop repo handy as well.  The makefile assumes that the laptop patches are in a sibling directory to this project: ../laptop.git.  If you didn't use my name for the directory, you'll have to change the makefile as appropriate.

If your files are similar enough to mine, you can probably attempt to patch them now.  To do so, type (in Terminal):

```
make patch
```

This will run 'make' which uses 'makefile' to run 'patchmatic' on the two files that need patching: dsdt.dsl and ssdt4.dsl.  The patched files are placed in the 'patched' subdirectory.

After you have successfully patched the files, they must be built into AML before you can use them.  Normally, you would do this with MaciASL, but in this case you can use make:

```
make
```

This will use iasl to build the files, placing the results in the 'build' subdirectory.  If all went well, there were no errors.  If you have errors, your DSDT/SSDT is slightly different than mine, so you'll have to test the patches out by hand with MaciASL to determine what might need to change.

Assuming you have a valid set of AML files in subdirectory 'build', you can install them with:

```
make install
```

or

```
make install_extra
```

make install: mounts /dev/disk0s1 as EFI volume and copies the files to EFI/CLOVER/ACPI/patched (dsdt.aml, ssdt-4.aml)
make install_extra: copies to /Extra (dsdt.aml, ssdt-1.aml)

Obviously 'make install' is used for Clover, and 'make install_extra' is used for Chameleon.


Note: All the patching/building/installing could be done with MaciASL, Patch, File Save As, etc.  Refer to the makefile to see what patches from the laptop repo I'm using.  Patches specific to this laptop are located in the 'patches' subdirectory.



### Feedback:

Please use this thread on tonymacx86.com for feedback, questions, and help:

TBD



### Known issues:

- None yet.


### Change Log:

2014-01-14 Initial Release


