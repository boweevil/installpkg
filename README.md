InstallPkg
==========

[Installpkg] is a tool for scripted installation packages on various Linux distributions.  This is accomplished by doing the following:

* It first detects the running distribution.
* It then defines which tools to use for the installation based on the detected distribution.
* Then it parses text files in a given directory for the line containing the proper package name for the detected distribution.
* Installs all packages defined in the text files.

[InstallPkg]: https://github.com/boweevil/installpkg
[issue tracker]: https://github.com/boweevil/installpkg/issues
[unixpackage]: https://github.com/unixpackage/unixpackage

## Why was this tool developed?
[InstallPkg] was created to answer a need I had with new Linux installations.
I've become comfortable with a certain set of tools and wanted to have them available to me in all of my installations regardless of the Linux distribution.
While I could have scripted the install for individual Linux distributions, this proved to be difficult to maintain and frustrating to implement.
So, I set out to create a tool which detects the distribution, reads a predetermined "list" of packages, reconciling the package name for the detected distro and installs all of them.

## Installation
Clone the repository, populate the packages directory with the package files following the templates provided, and run `installPkg.sh -i`.

```
installPkg.sh, version: 1.0.0

Usage: installPkg.sh [ARGUMENTS]...

The following arguments are available.
  -h, --help        Print this help and exit.
  -v, --version     Print the version and exit.
  -i, --install     Install all packages from /home/boweevil/projects/personal/installPkg/packages/.
  -c, --custom      Specify a custom packages directory from which to install.

Examples:
installPkg.sh -h

installPkg.sh -v

installPkg.sh -i

installPkg.sh -c ./path/to/packages

supported_distros: "fedora" "centos" "centos linux" "debian" "ubuntu" "arch" "antergos linux"
```

You may also define a custom path for packages to install using `-c ./path/to/packages`.

## Feedback

Having issues with [installpkg]? Report them in the [issue tracker].
