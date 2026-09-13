#!/usr/bin/env bash

echo -e 'File Janitor, 2026\nPowered by Bash'

# Check for no args
if [[ $# -eq 0 ]]; then
    echo -e "\nType file-janitor.sh help to see available options"
    exit 0
fi

command=$1
target_path="${2:-.}"  # A string, which might be directory, or if no second arg, default to current directory
                       # (Default Value Parameter Expansion)

if [[ "$command" == "help" ]]; then
    cat file-janitor-help.txt
elif [[ "$command" == "list" ]]; then
    if [[ ! -e "$target_path" ]]; then
        echo -e "\n$target_path is not found"
    elif [[ ! -d "$target_path" ]]; then
        echo -e "\n$target_path is not a directory"
    else
        if [[ "$target_path" == "." ]]; then
            echo -e "\nListing files in the current directory\n"
        else
            echo -e "\nListing files in $target_path"
        fi
        shopt -s dotglob # Enable matching of hidden file and directories
        export LC_COLLATE=C # Enforce standard ASCII/byte lexicographicaal ordering during glob expansion
        # Loop through files and directories in target_path using Pathname Expansion (globbing)
        for item in "$target_path"/*; do
            if [[ -e "$item" ]]; then
                echo "${item##*/}" # Use Parameter Expansion with Prefix Pattern Removal to remove any preceding path
            fi
        done
    fi
elif [[ "$command" == "report" ]]; then
    if [[ ! -e "$target_path" ]]; then
        echo -e "\n$target_path is not found"
    elif [[ ! -d "$target_path" ]]; then
        echo -e "\n$target_path is not a directory"
    else
        if [[ "$target_path" == "." ]]; then
            echo -e "\nThe current directory contains:"
        else
            echo -e "\n$target_path contains:"
        fi
        
        for EXT in tmp log py; do
            # Create a multi-line string of file sizes
            sizes=$(find "$target_path" -maxdepth 1 -type f -name "*.$EXT" -printf "%s\n")

            # If no files of this type, report back and move on to the next type
            if [[ -z "$sizes" ]]; then
                echo "0 $EXT file(s), total size 0 bytes"
                continue
            fi
            
            # Count how many lines (i.e. how many files)
            count=$(printf "%s\n" "$sizes" | wc -l)
            # Add up the file size in each line
            total=0
            for s in $sizes; do
                (( total += s ))
            done
            
            echo "$count $EXT file(s), with a total size of $total bytes"
        done
    fi
elif [[ "$command" == "clean" ]]; then
    if [[ ! -e "$target_path" ]]; then
        echo -e "\n$target_path is not found"
    elif [[ ! -d "$target_path" ]]; then
        echo -e "\n$target_path is not a directory"
    else
        if [[ "$target_path" == "." ]]; then
            echo -e "\nCleaning the current directory..."
        else
            echo -e "\nCleaning $target_path..."
        fi
        
        countoldlogs=$(find "$target_path" -maxdepth 1 -type f -name "*.log" -mtime +3 | wc -l)
        printf "Deleting old log files... "
        find "$target_path" -maxdepth 1 -type f -name "*.log" -mtime +3 -delete
        printf "done! %d files have been deleted\n" "$countoldlogs"

        counttmps=$(find "$target_path" -maxdepth 1 -type f -name "*.tmp" | wc -l)
        printf "Deleting temporary files... "
        find "$target_path" -maxdepth 1 -type f -name "*.tmp" -delete
        printf "done! %d files have been deleted\n" "$counttmps"

        countpys=$(find "$target_path" -maxdepth 1 -type f -name "*.py" | wc -l)
        # find "$target_path" -type f -name "*.py" -print
        printf "Moving python files... "
        if [[ $countpys -gt 0 ]]; then
            mkdir -p "$target_path"/python_scripts
            mv "$target_path"/*.py "$target_path"/python_scripts
        fi
        printf "done! %d files have been moved\n" "$countpys"
    fi
else
    echo -e "\nType file-janitor.sh help to see available options"
fi

