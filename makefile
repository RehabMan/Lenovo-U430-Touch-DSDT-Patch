# makefile

#
# Patches/Installs/Builds DSDT patches for Lenovo u430
#
# Created by RehabMan 
#

# PATCHMATIC=1 will assume files in native_patchmatic come from 'patchmatic -extract'
# Use PATCHMATIC=0 if using files from Linux at ./native_linux
ifneq "$(wildcard native_patchmatic)" ""
PATCHMATIC=1
else
PATCHMATIC=0
endif

# Note: SSDT6/IAOE has disassapeared in the new BIOS 7ccn35ww

ifeq "$(PATCHMATIC)" "1"
GFXSSDT=ssdt-3
IAOESSDT=ssdt-5
else
GFXSSDT=ssdt4
IAOESSDT=ssdt6
endif

EFIDIR=/Volumes/EFI
EFIVOL=/dev/disk0s1
LAPTOPGIT=../laptop.git
DEBUGGIT=../debug.git
EXTRADIR=/Extra
BUILDDIR=./build
PATCHED=./patched
UNPATCHED=./unpatched
#PRODUCTS=$(BUILDDIR)/dsdt.aml $(BUILDDIR)/$(GFXSSDT).aml $(BUILDDIR)/$(IAOESSDT).aml
PRODUCTS=$(BUILDDIR)/dsdt.aml $(BUILDDIR)/$(GFXSSDT).aml

IASLFLAGS=-vr -w1
IASL=iasl

.PHONY: all
all: $(PRODUCTS)

$(BUILDDIR)/dsdt.aml: $(PATCHED)/dsdt.dsl
	$(IASL) $(IASLFLAGS) -p $@ $<
	
$(BUILDDIR)/$(GFXSSDT).aml: $(PATCHED)/$(GFXSSDT).dsl
	$(IASL) $(IASLFLAGS) -p $@ $<
	
#$(BUILDDIR)/$(IAOESSDT).aml: $(PATCHED)/$(IAOESSDT).dsl
#	$(IASL) $(IASLFLAGS) -p $@ $<

.PHONY: clean
clean:
	rm $(PRODUCTS)

# Chameleon Install
.PHONY: install_extra
install_extra: $(PRODUCTS)
	-rm $(EXTRADIR)/ssdt-*.aml
	cp $(BUILDDIR)/dsdt.aml $(EXTRADIR)/dsdt.aml
	cp $(BUILDDIR)/$(GFXSSDT).aml $(EXTRADIR)/ssdt-1.aml
	#cp $(BUILDDIR)/$(IAOESSDT).aml $(EXTRADIR)/ssdt-2.aml


# Clover Install
.PHONY: install
install: $(PRODUCTS)
	if [ ! -d $(EFIDIR) ]; then mkdir $(EFIDIR) && diskutil mount -mountPoint /Volumes/EFI $(EFIVOL); fi
	cp $(BUILDDIR)/dsdt.aml $(EFIDIR)/EFI/CLOVER/ACPI/patched
	cp $(BUILDDIR)/$(GFXSSDT).aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/ssdt-4.aml
	#cp $(BUILDDIR)/$(IAOESSDT).aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/ssdt-6.aml
	diskutil unmount $(EFIDIR)
	if [ -d "/Volumes/EFI" ]; then rmdir /Volumes/EFI; fi


# Patch with 'patchmatic'
.PHONY: patch
patch:
	#cp $(UNPATCHED)/dsdt.dsl $(UNPATCHED)/$(GFXSSDT).dsl $(UNPATCHED)/$(IAOESSDT).dsl $(PATCHED)
	cp $(UNPATCHED)/dsdt.dsl $(UNPATCHED)/$(GFXSSDT).dsl $(PATCHED)
	patchmatic $(PATCHED)/dsdt.dsl patches/syntax_dsdt.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/cleanup.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/remove_wmi.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl patches/cleanup.txt $(PATCHED)/$(GFXSSDT).dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/iaoe.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/keyboard.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/audio.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/sensors.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_IRQ.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt $(PATCHED)/$(GFXSSDT).dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl $(LAPTOPGIT)/graphics/graphics_PNLF_haswell.txt $(PATCHED)/$(GFXSSDT).dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl patches/hdmi_audio.txt $(PATCHED)/$(GFXSSDT).dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl patches/graphics.txt $(PATCHED)/$(GFXSSDT).dsl
	#patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/usb/usb_7-series.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/usb.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_WAK2.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_OSYS.txt $(PATCHED)/dsdt.dsl
	#patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_MCHC.txt $(PATCHED)/dsdt.dsl
	#patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_HPET.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_RTC.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_SMBUS.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_Mutex.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_PNOT.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_IMEI.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/battery/battery_Lenovo-Ux10-Z580.txt $(PATCHED)/dsdt.dsl
	#patchmatic $(PATCHED)/$(IAOESSDT).dsl $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt $(PATCHED)/$(IAOESSDT).dsl
	#patchmatic $(PATCHED)/dsdt.dsl patches/ar92xx_wifi.txt $(PATCHED)/dsdt.dsl


.PHONY: patch_debug
patch_debug:
	make patch
	patchmatic $(PATCHED)/dsdt.dsl $(DEBUGGIT)/debug.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/debug.txt $(PATCHED)/dsdt.dsl
	#patchmatic $(PATCHED)/dsdt.dsl patches/debug1.txt $(PATCHED)/dsdt.dsl

# native correlations (linux)
# ssdt1 - PTID
# ssdt2 - PM related
# ssdt3 - PM related
# ssdt4 - graphics
# ssdt5 - not sure
# ssdt6 - was IAOE in early versions, now gone...
# ssdt6, ssdt7, ssdt8 - loaded dynamically (PM related)
