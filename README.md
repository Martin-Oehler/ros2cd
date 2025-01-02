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

## Details
The script changes the current directory to the folder of the package which is used for execution in the current environment. It uses the same mechanism to determine the package path as `ros2 launch`. In general, it will take you to the share directory of a package in the install folder. If symlink build is enabled, the script changes to the respective source folder instead.


