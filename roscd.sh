# Auto completion
_roscd_autocomplete() {
    # Clear previously generated completions
    COMPREPLY=()

    # The current word being completed is stored in $COMP_CWORD, and the array of words is COMP_WORDS.
    # Typically, we use the last word for generating completion matches.
    local cur="${COMP_WORDS[COMP_CWORD]}"

    # Get the list of packages. We redirect stderr to /dev/null to avoid error messages if ros2 is not sourced yet.
    local packages
    packages=$(ros2 pkg list 2>/dev/null)

    # Use 'compgen' to generate completions from the list of packages.
    # '-W' takes a list of words, and '-- "$cur"' makes sure we only match those words that start with the user's input.
    COMPREPLY=($(compgen -W "${packages}" -- "$cur"))

    return 0
}

# Register the completion function for the roscd command.
complete -F _roscd_autocomplete roscd

roscd() {
    # Check for help arguments
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: roscd [<pkg_name>]"
        echo "  If <pkg_name> is given, cd into the directory containing the package.xml file for that package."
        echo "  If no argument is given, tries to cd into COLCON_PREFIX_PATH/../src if it exists,"
        echo "  otherwise into COLCON_PREFIX_PATH if it exists."
        return 0
    fi

    # If no argument is given, go to the workspace root
    if [ -z "$1" ]; then
        # If COLCON_PREFIX_PATH is set, attempt to go to ../src or itself
        if [ -n "$COLCON_PREFIX_PATH" ]; then
            # Strip trailing slash if any, to avoid double slashes
            local cpp_path="${COLCON_PREFIX_PATH%/}"

            if [ -d "$cpp_path/../src" ]; then
                cd "$cpp_path/../src" || return 1
                return 0
            elif [ -d "$cpp_path" ]; then
                cd "$cpp_path" || return 1
                return 0
            else
                echo "COLCON_PREFIX_PATH directory does not exist: $COLCON_PREFIX_PATH"
                return 1
            fi
        else
            echo "COLCON_PREFIX_PATH is not set. Cannot change directory."
            return 1
        fi
    fi

    # Beyond this point, we have a package name argument.
    local pkg_name="$1"

    # If AMENT_PREFIX_PATH is not set or empty, we cannot proceed with package search.
    if [ -z "$AMENT_PREFIX_PATH" ]; then
        echo "ERROR: AMENT_PREFIX_PATH is not set. Make sure you have sourced your ROS2 workspace."
        return 1
    fi

    # Split AMENT_PREFIX_PATH by ':'
    IFS=':' read -r -a paths <<< "$AMENT_PREFIX_PATH"

    for prefix in "${paths[@]}"; do
        # Use find with -L to follow symlinks
        while IFS= read -r package_file; do
            # Resolve the real path of package_file (in case it's a symlink)
            local real_package_file
            real_package_file=$(readlink -f "$package_file")

            # Extract the <name></name> field from the package.xml
            # We assume the file is a valid package.xml and has one <name> tag.
            local pkg_xml_name
            pkg_xml_name=$(grep "<name>" "$real_package_file" | sed -E 's/.*<name>([^<]+)<\/name>.*/\1/')

            if [ "$pkg_xml_name" = "$pkg_name" ]; then
                local pkg_dir
                pkg_dir="$(dirname "$real_package_file")"
                cd "$pkg_dir" || return 1
                return 0
            fi
        done < <(find -L "$prefix" -type f -name package.xml 2>/dev/null)
    done

    echo "Package '$pkg_name' not found."
    return 1
}
