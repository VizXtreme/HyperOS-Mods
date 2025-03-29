packages="com.miui.packageinstaller com.google.android.packageinstaller com.android.packageinstaller"


ui_print "========================================
"

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
    echo "-"
    if [ -s "$RESDIR/default_deviceLevelList.txt" ]; then
        echo "- The deviceLevelList backup file already exists and is not empty."
        echo "- Skipping backup creation."
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


uninstall_updates() {
    ui_print "- Uninstalling installer updates..."
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
        if [ -z "$replace_folder" ]; then
            echo "$1"
        else
            echo "$replace_folder"
        fi
    else
        echo "$1"
    fi
}

install_package() {
    installer=$1
    partition=$2
    replace_folder=$3
    
    ui_print "- Replacing with $installer"
    
    mkdir -p "$MODPATH$partition/priv-app/ModPackageInstaller"
    cp -rf "$MODPATH/files/${installer}.apk" "$MODPATH$partition/priv-app/ModPackageInstaller"
    
    replace_folder=$(find_replace_folder "$replace_folder")
    
    REPLACE="
    $replace_folder
    "
}

add_installer() {
    ui_print "- Installing package installer for Android $android_ver"
    
    uninstall_updates
    
    for pkg in $packages; do
        get_package_info "$pkg"
        if [ "$installed" = "true" ]; then
            if [[ "$path" == *product* ]]; then
                partition=/system/product
                replace_folder="/system$folder"
            elif [[ "$path" == *system_ext* ]]; then
                partition=/system/system_ext
                replace_folder="/system$folder"
            elif [[ "$path" == *vendor* ]]; then
                partition=/system/vendort
                replace_folder="/system$folder"
            elif [[ "$path" == *system* ]]; then
                partition=/system
                replace_folder="$folder"            
            fi
            
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
    echo "-"
    echo "- HyperOS 1 Mods by VizXtreme"
    echo "- For any device running on HyperOS 1 !"
    echo "- Disable \`Unmount Modules\` in KernelSU settings to prevent abnormalities."
    echo "- Check me out at \`https://github.com/VizXtreme\` !"
    sleep 0.3
    echo "——  Thank you for using HyperOS 1 Mods !  ——"
    echo "-"
    sleep 2
}

finisher() {
    echo "-"
    echo "- Installation complete !"
    sleep 0.3
}

run_install() {
    check_support
    set_variables
    save_deviceLevelList
    set_highend
    add_installer
    clean_files
    finisher
    credits
}

run_install