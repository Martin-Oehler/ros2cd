# ros2cd
A complete and identical replacement for `roscd` in ros2.

## Usage
Clone the repository and source the provided script (e.g. in your .bashrc)
```
source ros2cd/roscd.sh
```

The command works identical to the old `roscd` command.

Go to a package folder:
```
roscd <pkg-name>
```
Go to the workspace source or root folder:
```
roscd
````

# Details
The script changes the current directory to the folder of the package which is used for execution in the current environment (i.e. the same folder that is used to execute launch files with `ros2 launch <pkg_name>`). This means, in general, it will take you to the install folder of a package. If symlink build is enabled, the script changes to the respective source folder instead. Overlays are also respected.

The script uses the `AMENT_PREFIX_PATH` environment variable to search for packages. Packages are identified by a `package.xml` file. If this file is a symlink, it is followed to the source directory. The workspace root is identified with the `COLCON_PREFIX_PATH` environment variable.

