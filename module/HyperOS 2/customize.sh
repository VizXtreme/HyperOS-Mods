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
    unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2
    save_deviceLevelList
    install_files || exit 1
    set_highend
    set_permissions
    cleanup
    credits
    finisher
	
#EOF