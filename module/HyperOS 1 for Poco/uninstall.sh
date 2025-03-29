#!/bin/sh
. ./customize.sh  # Source utils script for any functions or variables

set_variables  # Set necessary variables for the script
restore_deviceLevelList  # Restore device-level settings

tmp_list="framework-res"  # List of items to be removed

# Set Dalvik cache directory path
dda="/data/dalvik-cache/arm"
[ -d "$dda"64 ] && dda="$dda"64  # Check if 64-bit directory exists and set it

# Check if the Dalvik cache directory exists before continuing
if [ ! -d "$dda" ]; then
    echo "Dalvik cache directory does not exist: $dda"
    exit 1  # Exit with error code
fi

# Iterate over the items in tmp_list (currently just "framework-res")
for i in $tmp_list; do
    echo "Removing dalvik cache files for: $i"
    rm -f "$dda/system@*@"$i"*"  # Remove specific files matching the pattern
done

# Clean up the package cache
echo "Cleaning up package cache..."
rm -rf /data/system/package_cache/*  # Remove all files in the package cache directory

echo "Uninstallation complete."