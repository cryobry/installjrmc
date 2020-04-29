# installJRMC

This program will install [JRiver Media Center](https://www.jriver.com/) and associated helper services on Fedora (>=29), CentOS (>=8), Ubuntu (>=16.04), and Debian (>=9).

## Notes

1.  This script will not point major upgrades (i.e. from v25 to v26) to your old library. You should **first perform a library backup**, install the new major version, and then restore the library backup in the new version.
2.  In *most* cases `installJRMC` should be **executed as your normal user** (i.e. don't run it with `sudo`). Services are installed for the user that executes the script so do not execute as root unless you want to install system-wide services. Doing so may lead to permissions issues. `installJRMC` will prompt you for your `sudo` password as necessary to install dependencies and services.

## Options

Running `installJRMC` without any options will install the latest version of JRiver Media Center from the official JRiver repository (Ubuntu/Debian) or my [unofficial repository](https://repos.bryanroessler.com/jriver/) (Fedora/CentOS) using the system package manager. If any other option is specified then the default install method will need to be specified using `--install-repo` (or `--install-rpmbuild`). This makes it possible to create services, containers, repos, etc. separate from installing Media Center.

Here is a list of additional options that can be passed to the script. You can always find the latest supported options by running `installJRMC --help`.
```text
--install-repo
    Install JRiver Media Center from repository using package manager (Default)
    DEB-based OSes: Official package repository
    RPM-based OSes: BryanC's unofficial repository
--install-rpmbuild
     (RPM-based OSes only) Build RPM from source DEB and install it
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
--service-user USER
    Install systemd services and containers for USER
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
--help, -h
    Print help dialog and exit
--uninstall, -u
    Uninstall JRiver MC, cleanup service files, and remove firewall rules (does not remove library files)
```


### services
When installing systemd services it is important to execute `installJRMC` as the user you wish to run the services. Typically this is your normal user account but for some server installations it may be necessary to execute the script as root.


```text
jriver-mediaserver
    Enable and start a mediaserver systemd service (requires an existing X server)
jriver-mediacenter
    Enable and start a mediacenter systemd service (requires an existing X server)
jriver-x11vnc-mediacenter
    Enable and start x11vnc for the local desktop (requires an existing X server)
    --vncpass PASSWORD
        Set vnc password for x11vnc/Xvnc access. If no password is set, the script
        will either use existing password stored in ~/.vnc/jrmc_passwd or use no password
    --display DISPLAY
        Display to start x11vnc/Xvnc (Default: The current display (x11vnc) or the
        current display incremented by 1 (Xvnc))
jriver-xvnc-mediacenter
    Enable and start an Xvnc session running JRiver Media Center
    --vncpass and --display are also valid options (see above)
jriver-createrepo
    Install hourly service to build latest MC RPM and run createrepo
```

##### `jriver-x11vnc-mediaserver` versus `jriver-xvnc-mediacenter`
`x11vnc` shares your existing X display via vnc and starts a minimized JRiver Media Center service. Conversely, `xvnc` creates a new VNC display and starts a JRiver Media Center service in the foreground. The requisite firewall rules will also be added to the system firewall to enable remote access.

**Note**: If `jriver-xvnc-mediacenter` finds an existing display it will attempt to increment the display number by 1. This should work fine in 99% of cases, but if you have multiple running X servers on your host machine you should use the `--display` option to specify a free display.


### containers

**Coming soon!**

## Examples

*   `installJRMC`

    Installs the latest version of JRiver Media Center from the repository.

*   `installJRMC --install-repo --service jriver-mediaserver`

    Installs JRiver Media Center from the repository and starts/enables the mediaserver service.

*   `installJRMC --install-rpmbuild --restorefile /path/to/license.mjr --mcversion 26.0.56`

    Builds JRiver Media Center version 26.0.56 RPM from the source DEB, installs it (RPM distros only), and activates it using the specified .mjr license file.

*   `installJRMC --createrepo --createrepo-webroot /srv/jriver/repo --createrepo-user www-user`

     Builds the RPM, moves it to the webroot, and runs createrepo as `www-user`.

*   `installJRMC --service jriver-createrepo --createrepo-webroot /srv/jriver/repo --createrepo-user www-user`

    Installs the jriver-createrepo timer and service to build the RPM, move it to the webroot, and run createrepo as `www-user` hourly.

*   `installJRMC --install-repo --service jriver-x11vnc-mediaserver --vncpass "letmein"`

    Installs services to share the existing local desktop via VNC and automatically run a minimized instance of Media Center (Media Server).

*   `installJRMC --install-repo --service jriver-xvnc-mediacenter --display ":2"`

    Installs a service that starts Xvnc on display ':2' that just runs Media Center.

*   `installJRMC --uninstall`

    Uninstalls JRiver Media Center and its associated services and firewall rules. This will **not** remove your media, media library/database, or automated library backup folder.

## Additional Info
Did you find `installJRMC` useful? [Buy me a coffee!](https://paypal.me/bryanroessler?locale.x=en_US)

Did you find a bug? Let me know on [Interact!](https://yabb.jriver.com/interact/index.php/topic,123648.0.html)
