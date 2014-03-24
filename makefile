# makefile

#
# Patches/Installs/Builds DSDT patches for Haswell Envy 15
#
# Created by RehabMan 
#

GFXSSDT=ssdt4
EFIDIR=/Volumes/EFI
EFIVOL=/dev/disk0s2
LAPTOPGIT=../laptop.git
DEBUGGIT=../debug.git
EXTRADIR=/Extra
BUILDDIR=./build
PATCHED=./patched
UNPATCHED=./unpatched
PRODUCTS=$(BUILDDIR)/dsdt.aml $(BUILDDIR)/$(GFXSSDT).aml $(BUILDDIR)/ssdt6.aml

IASLFLAGS=-vr -w1
IASL=iasl

.PHONY: all
all: $(PRODUCTS)

$(BUILDDIR)/dsdt.aml: $(PATCHED)/dsdt.dsl
	$(IASL) $(IASLFLAGS) -p $@ $<
	
$(BUILDDIR)/$(GFXSSDT).aml: $(PATCHED)/$(GFXSSDT).dsl
	$(IASL) $(IASLFLAGS) -p $@ $<
	
$(BUILDDIR)/ssdt6.aml: $(PATCHED)/ssdt6.dsl
	$(IASL) $(IASLFLAGS) -p $@ $<

.PHONY: clean
clean:
	rm $(PRODUCTS)

# Chameleon Install
.PHONY: install_extra
install_extra: $(PRODUCTS)
	-rm $(EXTRADIR)/ssdt-*.aml
	cp $(BUILDDIR)/dsdt.aml $(EXTRADIR)/dsdt.aml
	cp $(BUILDDIR)/$(GFXSSDT).aml $(EXTRADIR)/ssdt-1.aml
	cp $(BUILDDIR)/ssdt6.aml $(EXTRADIR)/ssdt-2.aml
	#cp $(BUILDDIR)/ssdt5.aml $(EXTRADIR)/ssdt-3.aml


# Clover Install
.PHONY: install
install: $(PRODUCTS)
	if [ ! -d $(EFIDIR) ]; then mkdir $(EFIDIR) && diskutil mount -mountPoint /Volumes/EFI $(EFIVOL); fi
	cp $(BUILDDIR)/dsdt.aml $(EFIDIR)/EFI/CLOVER/ACPI/patched
	cp $(BUILDDIR)/$(GFXSSDT).aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/ssdt-4.aml
	cp $(BUILDDIR)/ssdt6.aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/ssdt-6.aml
	diskutil unmount $(EFIDIR)
	if [ -d "/Volumes/EFI" ]; then rmdir /Volumes/EFI; fi


# Patch with 'patchmatic'
.PHONY: patch
patch:
	cp $(UNPATCHED)/dsdt.dsl $(UNPATCHED)/$(GFXSSDT).dsl $(UNPATCHED)/ssdt6.dsl $(PATCHED)
	patchmatic $(PATCHED)/dsdt.dsl patches/syntax_dsdt.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/cleanup.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/remove_wmi.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl patches/cleanup.txt $(PATCHED)/$(GFXSSDT).dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/keyboard.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/audio.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/sensors.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_IRQ.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt $(PATCHED)/$(GFXSSDT).dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl $(LAPTOPGIT)/graphics/graphics_PNLF_haswell.txt $(PATCHED)/$(GFXSSDT).dsl
	patchmatic $(PATCHED)/$(GFXSSDT).dsl patches/hdmi_audio.txt $(PATCHED)/$(GFXSSDT).dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/usb/usb_7-series.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_WAK2.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_OSYS.txt $(PATCHED)/dsdt.dsl
	#patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_MCHC.txt $(PATCHED)/dsdt.dsl
	#patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_HPET.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_RTC.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_SMBUS.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_Mutex.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/system/system_PNOT.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl $(LAPTOPGIT)/battery/battery_Lenovo-Ux10-Z580.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/ssdt6.dsl $(LAPTOPGIT)/graphics/graphics_Rename-GFX0.txt $(PATCHED)/ssdt6.dsl


.PHONY: patch_debug
patch_debug:
	make patch
	patchmatic $(PATCHED)/dsdt.dsl $(DEBUGGIT)/debug.txt $(PATCHED)/dsdt.dsl
	patchmatic $(PATCHED)/dsdt.dsl patches/debug.txt $(PATCHED)/dsdt.dsl
	#patchmatic $(PATCHED)/dsdt.dsl patches/debug1.txt $(PATCHED)/dsdt.dsl

# native correlations
# ssdt1 - PTID
# ssdt2 - PM related
# ssdt3 - PM related
# ssdt4 - graphics
# ssdt5 - not sure
# ssdt6, ssdt7, ssdt8 - loaded dynamically (PM related)
