# installJRMC

This script will help install [JRiver Media Center](https://www.jriver.com/) and associated services on Fedora (>=29), CentOS (>=8), Ubuntu (>=16.04), and Debian (>=9).

## Notes

1.  This script will not point major upgrades (i.e. from v25 to v26) to your old library. You should **first perform a library backup**, install the new major version, and then restore the library backup in the new version.
2.  It is recommended to run `installJRMC` as your normal system user (i.e. don't run it with `sudo`). Services are installed for the user that executes the script so do not execute as root unless you want to install system-wide services like `createrepo` (see services section below for more information).

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
You will be prompted to enter your sudo password to install dependencies, etc.

## Options

Running `installJRMC` without any options will install the latest version of JRiver Media Center from the official JRiver repository (Ubuntu/Debian) or my unofficial repository (Fedora/CentOS) using the system package manager.

Here is a list of additional options that can be passed to the script. You can always find the latest supported options by running `installJRMC --help`.
```text
--install-repo
    Install JRiver Media Center from repository using package manager (Default)
    DEB-based OSes: Official package repository
    RPM-based OSes: BryanC unofficial repository
--install-rpmbuild
     (RPM-based OSes only!) Build RPM from source DEB and install it
--rpmbuild
    Build RPM from source DEB
--outputdir PATH
    Generate rpmbuild output in this directory (Default: $PWD/outputdir)
--mcversion VERSION
    Build or install a specific version (Default: scrape the latest version from Interact)
--restorefile RESTOREFILE
    Restore file location for registration (Default: skip registration)
--betapass PASSWORD
    Enter beta team password for access to beta builds
--service, -s SERVICE
    See SERVICES section below for a list of possible services to install
--container, -c CONTAINER
    See CONTAINERS section below for a list of possible services to install
--createrepo
    Build rpm, copy to webroot, and run createrepo
--createrepo-webroot PATH
    The webroot directory to install the repo (Default: /srv/jriver/)
--createrepo-user USER
    The web server user (Default: current user)
--version, -v
    Print this script version and exit
--debug, -d
    Print debug output
--force, -f
    Force reinstallation and ignore/overwrite previous output
--help, -h
    Print help dialog and exit
--uninstall, -u
    Uninstall JRiver MC, cleanup service files, and remove firewall rules (does not remove library files)
```
**Some options are incompatible** with each other, for example it is not possible to install the `mediaserver` service on Ubuntu/Debian when using `--rpmbuild` or `--createrepo` since those options do not actually install Media Center. `installJRMC` does perform sanity checks to automatically fix conflicting options, but it may not catch all edge cases.



#### services
When installing systemd services it is important to execute `installJRMC` as the user you wish to run the services. Typically this is your normal user account but for some server installations it may be necessary to execute the script as root.
```text
mediaserver
    Enable and start a mediaserver systemd service (requires an existing X server)
mediacenter
    Enable and start a mediacenter systemd service (requires an existing X server)
x11vnc
    Enable and start x11vnc for the local desktop (requires an existing X server)
    --vncpass and --display are valid options (see below)
mediacenter-vncserver
    Enable and start a vncserver
    --vncpass PASSWORD
        Set vnc password for x11vnc access. If no password is set, the script will either
        use existing password stored in ~/.vnc/jrmc_passwd or use no password
    --display DISPLAY
        Display to start vncserver/x11vnc (Default: The current display or :0 if current display
        is unaccessible)
createrepo
    Install hourly service to build latest MC RPM and run createrepo
```
I utilize `--service createrepo` to build the rpm repository used by Fedora/CentOS.

#### containers

**Coming soon!**

### Examples

*   `installJRMC`

    Installs the latest version of JRiver Media Center from the repository.

*   `installJRMC --service mediaserver`

    Installs JRiver Media Center from the repository and starts/enables the mediaserver service.

*   `installJRMC --install-rpmbuild --restorefile /path/to/license.mjr --mcversion 26.0.56`

     Builds JRiver Media Center version 26.0.56 RPM from the source DEB, installs it, and activates it using the specified .mjr license file (Fedora/CentOS only).

*   `installJRMC --createrepo --createrepo-webroot /srv/jriver/repo --createrepo-user www-user`

     Builds the RPM, moves it to the webroot, and runs createrepo as `www-user`.

*   `installJRMC --service createrepo --createrepo-webroot /srv/jriver/repo --createrepo-user www-user`

    Installs the jriver-createrepo timer and service to build the RPM, move it to the webroot, and run createrepo as `www-user`.

*   `installJRMC --service x11vnc --service mediacenter --vncpass "letmein"`

    Installs services to share the existing local desktop via VNC and automatically run Media Center

*   `installJRMC --service mediacenter-vncserver --vncpass "letmein"`

    Installs a service that starts a vncserver containing Media Center

*   `installJRMC --uninstall`

    Uninstalls JRiver Media Center and its associated services and firewall rules. This will **not** remove your media library and database in case you want to reinstall.
