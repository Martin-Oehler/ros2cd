# Check if function exists already
if type roscd &>/dev/null; then
    echo "${BASH_SOURCE[0]}:${LINENO}: [Warning] A command, alias, or function named 'roscd' already exists and may interfere with this script."
fi

# Auto completion
function _roscd_autocomplete() {
    # Clear previously generated completions
    COMPREPLY=()

    local cur="${COMP_WORDS[COMP_CWORD]}"
    local packages
    packages=$(ros2 pkg list 2>/dev/null)

    COMPREPLY=($(compgen -W "${packages}" -- "$cur"))
    return 0
}

# Register the completion function for the roscd command.
complete -F _roscd_autocomplete roscd

function roscd() {
    # Check for help arguments
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: roscd [<pkg_name>]"
        echo "  If <pkg_name> is given, cd into the directory containing the package installation."
        echo "  If no argument is given, tries to cd into COLCON_PREFIX_PATH/../src if it exists,"
        echo "  otherwise into COLCON_PREFIX_PATH if it exists."
        return 0
    fi

    # If no argument is given, go to the workspace root
    if [ -z "$1" ]; then
        if [ -n "$COLCON_PREFIX_PATH" ]; then
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

    local pkg_name="$1"

    # If AMENT_PREFIX_PATH is not set or empty, we cannot proceed with package search.
    if [ -z "$AMENT_PREFIX_PATH" ]; then
        echo "ERROR: AMENT_PREFIX_PATH is not set. Make sure you have sourced your ROS2 workspace."
        return 1
    fi

    # Split AMENT_PREFIX_PATH by ':'
    IFS=':' read -r -a paths <<< "$AMENT_PREFIX_PATH"

    for prefix in "${paths[@]}"; do
        # Check if prefix/share/ament_index/resource_index/packages/<pkg_name> exists
        local index_dir="$prefix/share/ament_index/resource_index/packages"
        if [ -f "$index_dir/$pkg_name" ]; then
            # We found the package in this prefix
            local pkg_dir="$prefix/share/$pkg_name"
            local pkg_xml="$pkg_dir/package.xml"

            if [ -L "$pkg_xml" ]; then
                # package.xml is a symlink, follow it
                local real_pkg_xml
                real_pkg_xml=$(readlink -f "$pkg_xml")
                local real_pkg_dir
                real_pkg_dir=$(dirname "$real_pkg_xml")
                cd "$real_pkg_dir" || return 1
            else
                # package.xml is not a symlink, just cd into pkg_dir
                cd "$pkg_dir" || return 1
            fi
            return 0
        fi
    done

    echo "Package '$pkg_name' not found."
    return 1
}
