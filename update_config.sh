#!/bin/bash

#set -x

EFI=`sudo mount_efi.sh /`
config=$EFI/EFI/Clover/config.plist
#config=config_new.plist

# smbios data
# Note: The code for serial# generation from ProBook Installer, originally
#  researched/written by RehabMan and philip_petev

week=CDFGHJKLMNPQRTVWXY12345678
week2=012345678
chars=ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890
week_letter=`echo ${week:$(($RANDOM%${#week})):1}`
week_letter2=`echo ${week:$(($RANDOM%${#week2})):2}`

function random_char()
{
    echo ${chars:$(($RANDOM%${#chars})):1};
}

function serial_number()
{
    echo "C02"$week_letter$(random_char)$(random_char)$(random_char)"F5V7"
}

function generate_new_plist()
{
    cp config.plist $config
    echo Generated random serial: \"$(serial_number)\"
    /usr/libexec/plistbuddy -c "Set :SMBIOS:SerialNumber $(serial_number)" $config
}

# no config.plist... make new one.
if [[ ! -e $config ]]; then
    echo No config.plist at $config, generating new.
    generate_new_plist
    exit
fi

# check to see if it is installation config.plist... if so, make new one
check=`/usr/libexec/plistbuddy -c "Print :ACPI:SortedOrder-Comment" $config 2>&1`
if [[ ! "$check" == *"Does Not Exist"* ]]; then
    echo The config.pilst at $config is install plist, generating new.
    generate_new_plist
    exit
fi

function replace_var()
# $1 is path to replace
{
    value=`/usr/libexec/plistbuddy -c "Print \"$1\"" $config`
    /usr/libexec/plistbuddy -c "Set \"$1\" \"$value\"" $config
}

function replace_dict()
# $1 is path to replace
{
    /usr/libexec/plistbuddy -x -c "Print \"$1\"" config.plist >/tmp/org_rehabman_node.plist
    /usr/libexec/plistbuddy -c "Delete \"$1\"" $config
    /usr/libexec/plistbuddy -c "Add \"$1\" dict" $config
    /usr/libexec/plistbuddy -c "Merge /tmp/org_rehabman_node.plist \"$1\"" $config
}

# existing config.plist, preserve:
#   CPU
#   DisableDrivers
#   GUI
#   RtVariables, except CsrActiveConfig and BooterConfig
#   SMBIOS
#
# replaced are:
#   ACPI
#   Boot
#   Devices
#   KernelAndKextPatches
#   SystemParameters
#   RtVariables:BooterConfig
#   RtVariables:CsrActiveConfig

echo The config.plist at $config will be updated.

replace_dict ":ACPI"
replace_dict ":Boot"
replace_dict ":Devices"
replace_dict ":KernelAndKextPatches"
replace_dict ":SystemParameters"
replace_var ":RtVariables:BooterConfig"
replace_var ":RtVariables:CsrActiveConfig"

