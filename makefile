# makefile

#
# Patches/Installs/Builds DSDT patches for Lenovo u430
#
# Created by RehabMan 
#

# Note: SSDT6/IAOE has disassapeared in the new BIOS 7ccn35ww

EFIDIR=/Volumes/EFI
EFIVOL=/dev/disk0s1
LAPTOPGIT=../laptop.git
DEBUGGIT=../debug.git
EXTRADIR=/Extra
BUILDDIR=./build
PATCHED=./patched
UNPATCHED=./unpatched

# DSDT is easy to find...
DSDT=DSDT

# Name(_ADR,0x0002000) identifies IGPU SSDT
IGPU=$(shell grep -l Name.*_ADR.*0x00020000 $(UNPATCHED)/SSDT*.dsl)
IGPU:=$(subst $(UNPATCHED)/,,$(subst .dsl,,$(IGPU)))

# OperationRegion SGOP is defined in optimus SSDT
PEGP=$(shell grep -l OperationRegion.*SGOP $(UNPATCHED)/SSDT*.dsl)
PEGP:=$(subst $(UNPATCHED)/,,$(subst .dsl,,$(PEGP)))

# Device(IAOE) identifies SSDT with IAOE
IAOE=$(shell grep -l Device.*IAOE $(UNPATCHED)/SSDT*.dsl)
IAOE:=$(subst $(UNPATCHED)/,,$(subst .dsl,,$(IAOE)))

# Determine build products
PRODUCTS=$(BUILDDIR)/$(DSDT).aml $(BUILDDIR)/$(IGPU).aml
ifneq "$(PEGP)" ""
	PRODUCTS:=$(PRODUCTS) $(BUILDDIR)/$(PEGP).aml
endif
ifneq "$(IAOE)" ""
	PRODUCTS:=$(PRODUCTS) $(BUILDDIR)/$(IAOE).aml
endif

IASLFLAGS=-ve
IASL=iasl

.PHONY: all
all: $(PRODUCTS)


$(BUILDDIR)/DSDT.aml: $(PATCHED)/$(DSDT).dsl
	$(IASL) $(IASLFLAGS) -p $@ $<
	
$(BUILDDIR)/$(IGPU).aml: $(PATCHED)/$(IGPU).dsl
	$(IASL) $(IASLFLAGS) -p $@ $<

ifneq "$(PEGP)" ""
$(BUILDDIR)/$(PEGP).aml: $(PATCHED)/$(PEGP).dsl
	$(IASL) $(IASLFLAGS) -p $@ $<
endif

ifneq "$(IAOE)" ""
$(BUILDDIR)/$(IAOE).aml: $(PATCHED)/$(IAOE).dsl
	$(IASL) $(IASLFLAGS) -p $@ $<
endif


.PHONY: clean
clean:
	rm -f $(PATCHED)/*.dsl
	rm -f $(BUILDDIR)/*.dsl $(BUILDDIR)/*.aml

.PHONY: cleanall
cleanall:
	make clean
	rm -f $(UNPATCHED)/*.dsl
	rm -f native_patchmatic/*.aml


# Clover Install
.PHONY: install
install: $(PRODUCTS)
	if [ ! -d $(EFIDIR) ]; then mkdir $(EFIDIR) && diskutil mount -mountPoint /Volumes/EFI $(EFIVOL); fi
	cp $(BUILDDIR)/$(DSDT).aml $(EFIDIR)/EFI/CLOVER/ACPI/patched
	cp $(BUILDDIR)/$(IGPU).aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-4.aml
ifneq "$(PEGP)" ""
	cp $(BUILDDIR)/$(PEGP).aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-5.aml
endif
ifneq "$(IAOE)" ""
	cp $(BUILDDIR)/$(IAOE).aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-7.aml
endif
	diskutil unmount $(EFIDIR)
	if [ -d "/Volumes/EFI" ]; then rmdir /Volumes/EFI; fi


# Patch with 'patchmatic'

$(PATCHED)/$(DSDT).dsl: $(UNPATCHED)/$(DSDT).dsl
	cp $(UNPATCHED)/$(DSDT).dsl $(PATCHED)
	patchmatic $@ patches/syntax_dsdt.txt
	patchmatic $@ patches/cleanup.txt
	patchmatic $@ patches/remove_wmi.txt
	patchmatic $@ patches/iaoe.txt
	patchmatic $@ patches/keyboard.txt
	patchmatic $@ patches/audio.txt
	patchmatic $@ patches/sensors.txt
	patchmatic $@ $(LAPTOPGIT)/system/system_IRQ.txt
	patchmatic $@ $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt
	#patchmatic $@ $(LAPTOPGIT)/usb/usb_7-series.txt
	patchmatic $@ patches/usb.txt
	patchmatic $@ $(LAPTOPGIT)/system/system_WAK2.txt
	patchmatic $@ $(LAPTOPGIT)/system/system_OSYS.txt
	#patchmatic $@ $(LAPTOPGIT)/system/system_MCHC.txt
	#patchmatic $@ $(LAPTOPGIT)/system/system_HPET.txt
	patchmatic $@ $(LAPTOPGIT)/system/system_RTC.txt
	patchmatic $@ $(LAPTOPGIT)/system/system_SMBUS.txt
	patchmatic $@ $(LAPTOPGIT)/system/system_Mutex.txt
	patchmatic $@ $(LAPTOPGIT)/system/system_PNOT.txt
	patchmatic $@ $(LAPTOPGIT)/system/system_IMEI.txt
	patchmatic $@ $(LAPTOPGIT)/battery/battery_Lenovo-Ux10-Z580.txt
	#patchmatic $@ patches/ar92xx_wifi.txt
ifeq "$(DEBUG)" "1"
	patchmatic $@ $(DEBUGGIT)/debug.txt
	#patchmatic $@ patches/debug.txt
	#patchmatic $@ patches/debug1.txt
endif

$(PATCHED)/$(IGPU).dsl: $(UNPATCHED)/$(DSDT).dsl
	cp $(UNPATCHED)/$(IGPU).dsl $(PATCHED)
	patchmatic $@ patches/cleanup.txt
	patchmatic $@ $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt
	patchmatic $@ $(LAPTOPGIT)/graphics/graphics_PNLF_haswell.txt
	patchmatic $@ patches/hdmi_audio.txt
	patchmatic $@ patches/graphics.txt
ifeq "$(DEBUG)" "1"
	patchmatic $@ $(DEBUGGIT)/debug_extern.txt
endif

ifneq "$(IAOE)" ""
$(PATCHED)/$(IAOE).dsl: $(UNPATCHED)/$(IAOE).dsl
	cp $(UNPATCHED)/$(IAOE).dsl $(PATCHED)
	patchmatic $@ $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt
endif

ifneq "$(PEGP)" ""
$(PATCHED)/$(PEGP).dsl: $(UNPATCHED)/$(PEGP).dsl
	cp $(UNPATCHED)/$(PEGP).dsl $(PATCHED)
	patchmatic $@ patches/nvidia_off.txt
	patchmatic $@ $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt
ifeq "$(DEBUG)" "1"
	patchmatic $@ $(DEBUGGIT)/debug_extern.txt
endif
endif


# native correlations (linux, non-optimus)
# ssdt1 - PTID
# ssdt2 - PM related
# ssdt3 - PM related
# ssdt4 - graphics
# ssdt5 - not sure
# ssdt6 - was IAOE in early versions, now gone...
# ssdt6, ssdt7, ssdt8 - loaded dynamically (PM related)
