#!/bin/sh
if ! $BOOTMODE; then
    ui_print "*********************************************************"
    ui_print "Installing from recovery is not supported!"
    ui_print "Please install from the Magisk / KernelSU / APatch app!"
    abort    "*********************************************************"
fi

. $MODPATH/utils.sh

check_support
set_variables
save_deviceLevelList
set_highend
finisher
credits

# EOF