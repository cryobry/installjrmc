# installJRMC

This script will help install [JRiver Media Center](https://www.jriver.com/) and associated services on Fedora (>=29), CentOS (>=8), Ubuntu (>=16.04), and Debian.

## Notes

This script will not point major upgrades (i.e. from v25 to v26) to your old library. You should **first perform a library backup**, install the new major version, and then restore the library backup in the new version.

## Installing

1.  Extract:
```
unzip ./installJRMC.zip
```
2.  You may need to make the script executable:
```
chmod +x ./installJRMC
```
3.  Run the script using default options (see Options section below):
```
./installJRMC
```

## Options

Running `installJRMC` without any options will install the latest version of JRiver Media Center from the official JRiver repository (Ubuntu/Debian) or my unofficial repository (Fedora/CentOS) using the system package manager.

Here is a list of additional options that can be passed to the script. You can always find the latest supported options by running `installJRMC --help`.
```text
--rpmbuild
    Debian/Ubuntu: Build RPM from source DEB
    Fedora/CentOS: Build RPM from source DEB and install it
--outputdir PATH
    Generate rpmbuild output in this directory (Default: $PWD/outputdir)
--mcversion VERSION
    Build or install a specific version (Default: scrape the latest version from Interact)
--restorefile RESTOREFILE
    Restore file location for registration (Default: skip registration)
--betapass PASSWORD
    Enter beta team password for access to beta builds
--service SERVICE
    See services section below for a list of possible service to install
-v|--version
    Print this script version and exit
-d|--debug
    Enter debug mode
-h|--help
    Print help dialog and exit
-u|--uninstall
    Uninstall JRiver MC, cleanup service files, and remove firewall rules (does not remove
    library files)
```
Some options are incompatible with each other, for example it is not possible to install the `mediaserver` service on Ubuntu/Debian when using `--rpmbuild` or `--createrepo` since those options do not actually install Media Center.

#### createrepo
```text
--createrepo
    Build rpm, copy to webroot, and run createrepo

    --createrepo-webroot PATH
        The webroot directory to install the repo (Default: /srv/jriver/)
    --createrepo-user USER
        The web server user (Default: current user)
```
#### services
When installing systemd services it is important to execute `installJRMC` as the user you wish to run the services. Typically this is your normal user account but for some server installations it may be necessary to execute the script as root.
```text
mediaserver
    Create and enable a JRiver MC Media Server systemd service for the current user

x11vnc-mediaserver
    Create and enable a JRiver MC mediaserver service and x11vnc (for headless
    installations without an existing X server) service for the current user

    --vncpass PASSWORD
        Set vnc password for x11vnc access. If no password is set, the script will either use
        existing password stored in ~/.vnc/jrmc_passwd or use no password
    --display DISPLAY
        Start X11VNC on this display (Default: The current display or :0 if current display is
        unaccessible)

createrepo
    Install service to build latest MC RPM and run createrepo hourly for the current user (can also take additional input arguments --createrepo-webroot and/or createrepo-user)
```
I utilize `--service createrepo` to build the rpm repository used by Fedora/CentOS.

### Examples

*   `installJRMC --service mediaserver`

    Installs JRiver Media Center using the package manager and starts the jriver-mediaserver service.

*   `installJRMC --restorefile /path/to/license.mjr --mcversion 26.0.15`

     Builds JRiver Media Center version 26.0.15 RPM from the source DEB (and installs it on Fedora/CentOS along with the associated license).

*   `installJRMC --createrepo --createrepo-webroot /srv/jriver/repo --createrepo-user www-user`

     Builds the RPM, moves it to the webroot, and runs createrepo as `www-user`.

*   `installJRMC --service createrepo --createrepo-webroot /srv/jriver/repo --createrepo-user www-user`

    Installs the jriver-createrepo timer and service to build the RPM and move it to the webroot as `www-user`.
