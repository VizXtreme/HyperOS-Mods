#!/bin/sh

ui_print ""
ui_print "========================================"
ui_print ""

check_support() {
    android_ver=$(getprop ro.build.version.release)
    ui_print "- Checking Android version..."
    if [ "$android_ver" -lt 15 ]; then
        abort "- Your Android version is not supported"
    else
        ui_print "- Android $android_ver is supported."
    fi
}

set_variables() {
    RESDIR=/data/adb/bak
    mkdir -p $RESDIR
}

save_deviceLevelList() {
    echo ""
    echo "----------"
    echo ""
    if [ -s "$RESDIR/default_deviceLevelList.txt" ]; then
        ui_print "- deviceLevelList backup already exists. Skipping backup."
        return
    fi
   
    device_level_list=$(su -c "settings get system deviceLevelList")
    if [ -z "$device_level_list" ] || [ "$device_level_list" = "null" ]; then
        ui_print "- Failed to retrieve deviceLevelList. Continuing without backup."
    else
        echo "$device_level_list" > "$RESDIR/default_deviceLevelList.txt"
        ui_print "- Default deviceLevelList saved: \`$(cat "$RESDIR/default_deviceLevelList.txt")\`"
    fi
}

set_highend() {
    new_value="v:1,c:3,g:3"
    ui_print "- Setting deviceLevelList to: \`$new_value\`"
    if su -c "settings put system deviceLevelList $new_value"; then
        ui_print "- Successfully updated deviceLevelList."
    else
        ui_print "- Failed to update deviceLevelList."
    fi
}

restore_deviceLevelList() {
    echo "-"
    if [ -f "$RESDIR/default_deviceLevelList.txt" ]; then
        saved_value=$(cat "$RESDIR/default_deviceLevelList.txt")
        ui_print "- Restoring deviceLevelList to: \`$saved_value\`."
        if su -c "settings put system deviceLevelList $saved_value"; then
            ui_print "- Successfully restored deviceLevelList."
            rm -rf "$RESDIR"
        else
            ui_print "- Failed to restore deviceLevelList."
        fi
    else
        ui_print "- No saved deviceLevelList found. Skipping restore."
    fi
}

install_files() {
    echo ""
    echo "----------"
    echo ""
    ui_print "- Installing Mods..."

    # Package names
    miui_package="com.miui.home"
    poco_package="com.mi.android.globallauncher"

    # Uninstall updates safely
    pm uninstall-system-updates "$miui_package" >/dev/null 2>&1
    miui_path=$(pm path "$miui_package" | sed 's/package://')

    pm uninstall-system-updates "$poco_package" >/dev/null 2>&1
    poco_path=$(pm path "$poco_package" | sed 's/package://')

    if [ -n "$miui_path" ]; then
        launcher_folder=$(dirname "$miui_path" | sed 's/\/system//')
        launcher_name_current=$(basename "$miui_path" | sed 's/.apk//')
    elif [ -n "$poco_path" ]; then
        launcher_folder=$(dirname "$poco_path" | sed 's/\/system//')
        launcher_name_current=$(basename "$poco_path" | sed 's/.apk//')

        # Ensure overlay path exists before copying
        mkdir -p "$MODPATH/system/product/overlay"
        cp -f "$MODPATH/files/MiuiPocoLauncherResOverlay.apk" "$MODPATH/system/product/overlay"
    else
        ui_print "- Launcher package not found! Exiting..."
        return 1
    fi

    # Ensure the launcher folder exists
    mkdir -p "$MODPATH/system$launcher_folder"

    # Rename and move the launcher APK
    if [ -f "$MODPATH/files/launcher/SystemLauncher.apk" ]; then
        mv "$MODPATH/files/launcher/SystemLauncher.apk" "$MODPATH/files/launcher/$launcher_name_current.apk"
        cp -f "$MODPATH/files/launcher/$launcher_name_current.apk" "$MODPATH/system$launcher_folder"
        
        # Install the launcher to ensure it is applied
        pm install -r "$MODPATH/system$launcher_folder/$launcher_name_current.apk" >/dev/null 2>&1
    else
        ui_print "- Launcher APK not found! Exiting..."
        return 1
    fi

    # Modify init.rc safely
    SRC_FILE="/system/etc/init/hw/init.rc"
    DEST_FILE="$MODPATH/system/etc/init/hw/init.rc"

    if [ -f "$SRC_FILE" ]; then
        if grep -q 'com\.mi\.android\.globallauncher' "$SRC_FILE"; then
            mkdir -p "$(dirname "$DEST_FILE")"
            cp "$SRC_FILE" "$DEST_FILE"
            sed -i 's/com\.mi\.android\.globallauncher/com.miui.home/g' "$DEST_FILE"
        fi
    fi
}

set_permissions() {
    echo ""
    echo "----------"
    echo ""
    echo "- Setting permissions..."
    su -c "pm grant com.miui.home android.permission.READ_MEDIA_IMAGES" >/dev/null 2>&1
    su -c "pm grant com.miui.home android.permission.ACCESS_CONTEXTUAL_SEARCH" >/dev/null 2>&1
    set_perm_recursive "$MODPATH" 0 0 0755 0644
}

cleanup() {
    echo "- Cleaning up...."
    rm -rf "$MODPATH/files" 2>/dev/null
    rm -rf /data/resource-cache/* /data/system/package_cache/* /cache/* /data/dalvik-cache/*
    touch "$MODPATH/hyperoslaunchermod/remove"
}


credits() {
    echo ""
    echo "----------"
    echo ""
    ui_print "- HyperOS 2 Mods by VizXtreme"
    ui_print ""
    ui_print "- Compatible with HyperOS 2"
    ui_print ""
    ui_print "- Disable 'Unmount Modules' in KernelSU settings to prevent issues."
    ui_print ""
    ui_print "- Check out my GitHub: https://github.com/VizXtreme"
    ui_print ""
    ui_print "—— Thank you for using HyperOS 2 Mods! ——"
    ui_print ""
    ui_print "========================================"
    ui_print ""
}

finisher() {
    ui_print "- Installation complete!"
}

#EOF