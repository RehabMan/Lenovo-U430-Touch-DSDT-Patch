# makefile

#
# Patches/Installs/Builds DSDT patches for Lenovo u430
#
# Created by RehabMan 
#

HDA=ALC283
RESOURCES=./Resources_$(HDA)
HDAINJECT=AppleHDA_$(HDA).kext
HDAINJECT_MARK=_hdainject_marker.txt
HDAZML=AppleHDA_$(HDA)_Resources
HDAZML_MARK=_hdazml_marker.txt

# set build products
BUILDDIR=./build
#HDA_PRODUCTS=$(HDAZML_MARK) $(HDAINJECT_MARK)
AML_PRODUCTS=$(BUILDDIR)/SSDT-HACK.aml
PRODUCTS=$(AML_PRODUCTS) $(HDA_PRODUCTS)

LE=/Library/Extensions
SLE=/System/Library/Extensions
VERSION_ERA=$(shell ./tools/print_version.sh)
ifeq "$(VERSION_ERA)" "10.10-"
	INSTDIR=$SLE
else
	INSTDIR=$LE
endif

IASLFLAGS=-vw 2095 -vw 2146
IASL=iasl

.PHONY: all
all: $(PRODUCTS)

$(BUILDDIR)/SSDT-HACK.aml: SSDT-HACK.dsl
	$(IASL) $(IASLFLAGS) -p $@ $<

.PHONY: clean
clean:
	rm -f $(BUILDDIR)/*.dsl $(BUILDDIR)/*.aml
	make clean_hda

.PHONY: install
install: $(AML_PRODUCTS)
	$(eval EFIDIR:=$(shell ./mount_efi.sh))
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/DSDT.aml
	rm -f $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT-*.aml $(EFIDIR)/EFI/CLOVER/ACPI/patched/SSDT.aml
	cp $(AML_PRODUCTS) $(EFIDIR)/EFI/CLOVER/ACPI/patched

$(HDAZML_MARK): $(RESOURCES)/*.plist tools/patch_hdazml.sh tools/_hda_subs.sh
	./tools/patch_hdazml.sh $(HDA)
	touch $(HDAZML_MARK)

$(HDAINJECT_MARK): $(RESOURCES)/*.plist tools/patch_hdazml.sh tools/_hda_subs.sh
	./tools/patch_hdainject.sh $(HDA)
	touch $(HDAINJECT_MARK)

.PHONY: clean_hda
clean_hda:
	rm -rf $(HDAZML) $(HDAINJECT)
	rm -f $(HDAZML_MARK) $(HDAINJECT_MARK)

.PHONY: update_kernelcache
	update_kernelcache:
	sudo touch $(SLE) && sudo kextcache -update-volume /

.PHONY: install_hda
install_hda:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo rm -f $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*
	sudo cp $(HDAZML)/* $(SLE)/AppleHDA.kext/Contents/Resources
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*; fi
	make update_kernelcache

.PHONY: install_hdadummy
install_hdadummy:
	sudo rm -Rf $(INSTDIR)/$(HDAINJECT)
	sudo cp -R ./$(HDAINJECT) $(INSTDIR)
	sudo rm -f $(SLE)/AppleHDA.kext/Contents/Resources/*.zml*
	if [ "`which tag`" != "" ]; then sudo tag -a Blue $(INSTDIR)/$(HDAINJECT); fi
	make update_kernelcache

