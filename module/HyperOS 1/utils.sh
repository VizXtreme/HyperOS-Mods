packages="com.miui.packageinstaller com.google.android.packageinstaller com.android.packageinstaller"

ui_print ""
ui_print "========================================"
ui_print ""

set_variables() {
  RESDIR=/data/adb/bak
  mkdir -p $RESDIR
}

check_support() {
    android_ver=$(getprop ro.build.version.release)
    ui_print "- Checking support..."
    if [ "$android_ver" -lt 14 ]; then
        abort "- Your Android version is not supported"
    else
        ui_print "- Android $android_ver is supported!"
    fi
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

uninstall_updates() {
    ui_print "- Uninstalling package installer updates..."
    for pkg in $packages; do
        pm uninstall-system-updates $pkg >/dev/null 2>&1
    done
}

get_package_info() {
    pkg=$1
    installed=$(pm list packages | grep -q $pkg && echo true || echo false)
    path=$(pm path $pkg | sed 's/package://')
    folder=$(dirname "$path")
}

find_replace_folder() {
    local search_dir="/data/adb/modules/$MODID"
    local replace_file=$(find "$search_dir" -name ".replace" -type f)
    if [ -n "$replace_file" ]; then
        local replace_folder=$(dirname "$replace_file")
        replace_folder=${replace_folder#$search_dir}
        echo "${replace_folder:-$1}"
    else
        echo "$1"
    fi
}

install_package() {
    installer=$1
    partition=$2
    replace_folder=$3
    ui_print ""
    ui_print "----------"
    ui_print ""
    ui_print "- Installing Mods..."

    mkdir -p "$MODPATH$partition/priv-app/ModPackageInstaller"
    cp -rf "$MODPATH/files/${installer}.apk" "$MODPATH$partition/priv-app/ModPackageInstaller"

    replace_folder=$(find_replace_folder "$replace_folder")
    
    REPLACE="
    $replace_folder
    "
}

add_installer() {
    echo ""
    echo "----------"
    echo ""
    ui_print "- Installing package installer for Android $android_ver"
    
    uninstall_updates
    
    for pkg in $packages; do
        get_package_info "$pkg"
        if [ "$installed" = "true" ]; then
            case "$path" in
                *product*) partition=/system/product; replace_folder="/system$folder" ;;
                *system_ext*) partition=/system/system_ext; replace_folder="/system$folder" ;;
                *vendor*) partition=/system/vendor; replace_folder="/system$folder" ;;
                *system*) partition=/system; replace_folder="$folder" ;;
            esac
            
            case $pkg in
                com.miui.packageinstaller) install_package "MiuiPackageInstaller" "$partition" "$replace_folder" ;;
                com.google.android.packageinstaller) install_package "GooglePackageInstaller" "$partition" "$replace_folder" ;;
                com.android.packageinstaller) install_package "AndroidPackageInstaller" "$partition" "$replace_folder" ;;
            esac
            return
        fi
    done
    
    abort "- No supported package installer found"
}

clean_files() {
    rm -rf "$MODPATH/addon" "$MODPATH/files" 2>/dev/null
    rm -f "$MODPATH/install.sh" 2>/dev/null
    rm -rf /data/resource-cache/* /data/system/package_cache/* 2>/dev/null
    touch "$MODPATH/newui_pkg_installer/remove"
}

credits() {
    echo ""
    echo "----------"
    echo ""
    ui_print "- HyperOS 1 Mods by VizXtreme"
    ui_print ""
    ui_print "- Compatible with HyperOS 1"
    ui_print ""
    ui_print "- Disable 'Unmount Modules' in KernelSU settings to prevent issues."
    ui_print ""
    ui_print "- Check out my GitHub: https://github.com/VizXtreme"
    ui_print ""
    ui_print "—— Thank you for using HyperOS 1 Mods! ——"
    ui_print ""
    ui_print "========================================"
    ui_print ""
}

finisher() {
    ui_print "- Installation complete!"
}