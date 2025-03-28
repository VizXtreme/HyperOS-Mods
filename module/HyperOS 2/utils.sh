#!/bin/sh
check_support() {
    android_ver=$(getprop ro.build.version.release)
    ui_print "- Checking support..."
    if [ "$android_ver" -lt 14 ]; then
        abort "- Your Android version is not supported"
    fi
}

set_variables() {
  RESDIR=/data/adb/bak
  mkdir -p $RESDIR
}

save_deviceLevelList() {
    echo "-"
    if [ -s "$RESDIR/default_deviceLevelList.txt" ]; then
        echo "- The deviceLevelList backup file already exists and is not empty."
        echo "- Skipping creating backup."
        return
    fi
    
    device_level_list=$(su -c "settings get system deviceLevelList")
    if [ -z "$device_level_list" ] || [ "$device_level_list" = "null" ]; then
        echo "- Failed to retrieve deviceLevelList."
        echo "- Continuing without backup value."
        sleep 0.3
    else
        echo "$device_level_list" > "$RESDIR/default_deviceLevelList.txt"
        echo "- The default value of deviceLevelList is: \`$(cat "$RESDIR/default_deviceLevelList.txt")\`"
    fi
}

set_highend() {
    echo "-"
    new_value="v:1,c:3,g:3"
    echo "- New deviceLevelList value: \`$new_value\`"
    sleep 0.3
    if su -c "settings put system deviceLevelList $new_value"; then
        echo "- Successfully changed the deviceLevelList."
        sleep 0.3
    else
        echo "- Failed to change the deviceLevelList."
        sleep 0.3
    fi
}

restore_deviceLevelList() {
    echo "-"
    if [ -f "$RESDIR/default_deviceLevelList.txt" ]; then
        saved_value=$(cat "$RESDIR/default_deviceLevelList.txt")
        echo "- Restoring deviceLevelList to: \`$saved_value\`."
        sleep 0.3
        if su -c "settings put system deviceLevelList $saved_value"; then
            echo "- Successfully restored deviceLevelList to: \`$saved_value\`"
            sleep 0.3
            if rm -rf "$RESDIR"; then
                echo "- Successfully deleted saved backups."
                sleep 0.3
            else
                echo "- Failed to delete saved backups."
                sleep 0.3
            fi
        else
            echo "- Failed to restore deviceLevelList."
            sleep 0.3
        fi
    else
        echo "- No saved deviceLevelList found. Nothing to restore."
        sleep 0.3
    fi
}

finisher() {
    echo "-"
    echo "- Installation completed. You can now reboot !"
    sleep 0.3
}

credits() {
    echo "-"
    echo "- HyperOS 2 Mods by VizXtreme"
    echo "- For any device running on HyperOS 2 !"
    echo "- Disable \` Unmount Modules \` in KernelSU settings to prevent abnormalities."
    echo "- Check me out at \`https://github.com/VizXtreme/\`!"
    sleep 0.3
    echo "——  Thank you for using HyperOS 2 Mods ! ——"
    echo "-"
    sleep 2
}

# EOF