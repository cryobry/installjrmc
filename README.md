# installJRMC

This program will install [JRiver Media Center](https://www.jriver.com/) and associated helper services on most major distros.

## README

1. This script will not point major upgrades to your old library. You should **first perform a library backup**, install the new major version, and then restore the library backup in the new version.
2. Typically `installJRMC` should be **executed as your normal user** (i.e. don't run it with `sudo`). Services are installed for the user that executes the script so do not execute as root unless you want to install system-level services. Doing so may lead to permissions issues. `installJRMC` will prompt you for your `sudo` password as necessary to install dependencies and services.

## Executing

`installJRMC [--option [ARGUMENT]]`

Running `installJRMC` without any options will install the latest version of JRiver Media Center from the official JRiver repository (Ubuntu/Debian) or my [unofficial repository](https://repos.bryanroessler.com/jriver/) (Fedora/CentOS) using the system package manager. SUSE users will need to use the `--install rpm` install method until a SUSE repo becomes available. If any other option is specified, then the default install method will need to be specified using `--install`. This makes it possible to install services and containers independent of Media Center.

## Options

You can always find the latest supported options by running `installJRMC --help`.

```text
--install, -i repo|rpm|deb
    repo: Install MC from repository, future updates will be handled by the system package manager
    rpm: Build and install MC locally (RPM-based OSes only)
    deb: Download and install official MC package locally (useful with --compat flag for older distros)
--build=[suse|fedora|centos]
    Build RPM from source DEB but do not install
    Specify cross-build target with optional argument, note '=' (ex. --build=suse)
--compat
    Build/install MC without minimum library specifiers
--mcversion VERSION
    Build or install a specific MC version, ex. "28.0.25"
--outputdir PATH
    Generate rpmbuild output in this PATH (Default: ./output)
--restorefile RESTOREFILE
    Restore file location for automatic license registration
--betapass PASSWORD
    Enter beta team password for access to beta builds
--service, -s SERVICE
    See SERVICES section below for the list of services to deploy
  --service-type user|system
      Starts services at boot (system) or user login (user) (Default: system)
--container, -c CONTAINER (TODO: Under construction)
    See CONTAINERS section below for a list of containers to deploy
--createrepo
    Build rpm, copy to webroot, and run createrepo.
  --createrepo-webroot PATH
      The webroot directory to install the repo (Default: /var/www/jriver/)
  --createrepo-user USER
      The web server user if different from the current user
--version, -v
    Print this script version and exit
--debug, -d
    Print debug output
--help, -h
    Print help dialog and exit
--uninstall, -u
    Uninstall JRiver MC, cleanup service files, and remove firewall rules (does not remove library or media files)
```

### services

When installing systemd services it is important to execute `installJRMC` as the user you wish to run the services. MC services are installed as system-level services (`--service-type=system`) by default. They can be manipulated by the root user: `sudo systemctl stop jriver-servicename@username.service`. It is also possible to create user-level services using `--service-type=user` that can be manipulated by the current user: `systemctl --user stop jriver-mediacenter`.

```text
jriver-mediaserver
    Enable and start a mediaserver systemd service (requires an existing X server)
jriver-mediacenter
    Enable and start a mediacenter systemd service (requires an existing X server)
jriver-x11vnc
    Enable and start x11vnc for the local desktop (requires an existing X server, does NOT support Wayland)
    --vncpass and --display are also valid options (see below)
jriver-xvnc
    Enable and start a new Xvnc session running JRiver Media Center
    --vncpass PASSWORD
        Set vnc password for x11vnc/Xvnc access. If no password is set, the script will either use existing password stored in ~/.vnc/jrmc_passwd or use no password
    --display DISPLAY
        Manually specify display to use for x11vnc/Xvnc (ex. ':1')
jriver-createrepo
    Install hourly service to build latest MC RPM and run createrepo
```

It is possible to install multiple services at one time using multiple `--service` blocks: `installJRMC --repo --service jriver-x11vnc --service jriver-mediacenter`

#### `jriver-x11vnc` versus `jriver-xvnc`

[jriver-x11vnc](http://www.karlrunge.com/x11vnc/) shares your existing X display via VNC and can be combined with additional services to start Media Center or Media Server. Conversely, [jriver-xvnc](https://tigervnc.org/doc/Xvnc.html) creates a new Xvnc display and starts a JRiver Media Center service in the foreground of the new VNC display.

**Note**: If `jriver-xvnc` finds an existing display it will attempt to increment the display number by 1. This should work fine in most cases, but if you have multiple running X servers on your host machine you should use the `--display` option to specify a free display.

### Firewall Rules

`installJRMC` will automatically add port forwarding firewall rules enabling remote access to Media Server (52100-52200/tcp, 1900/udp DLNA) and Xvnc/x11vnc (depends on port selection). `installJRMC` uses `firewall-cmd` on Fedora/CentOS/SUSE and `ufw` on Ubuntu/Debian.

**Note:** `ufw` is not installed by default on Debian but will be installed by `installJRMC`. To prevent user lock-out (i.e. SSH), Debian users that have not already enabled `ufw` will need to `sudo ufw enable` after running `installJRMC` and inspecting their configuration.

### containers

**Coming soon!**

## Examples

* `installJRMC`

    Install the latest version of JRiver Media Center from the repository.

* `installJRMC --install repo --service jriver-mediaserver`

    Install JRiver Media Center from the repository and starts/enables the /MediaServer service.

* `installJRMC --install rpm --restorefile /path/to/license.mjr --mcversion 28.0.87`

    Build JRiver Media Center version 28.0.87 RPM from the source DEB, installs it (RPM distros only), and activates it using the specified .mjr license file.

* `installJRMC --createrepo --createrepo-webroot /srv/jriver/repo --createrepo-user www-user`

     Build the RPM, moves it to the webroot, and runs createrepo as `www-user`.

* `installJRMC --service jriver-createrepo --createrepo-webroot /srv/jriver/repo --createrepo-user www-user`

    Install the jriver-createrepo timer and service to build the RPM, move it to the webroot, and run createrepo as `www-user` hourly.

* `installJRMC --install repo --service jriver-x11vnc --service jriver-mediacenter --vncpass "letmein"`

    Install services to share the existing local desktop via VNC and automatically run Media Center on startup.

* `installJRMC --install repo --service jriver-xvnc --display ":2"`

    Install an Xvnc server on display ':2' that starts Media Center.

* `installJRMC --install deb --compat`

    Install a more widely-compatible version of MC on deb-based distros.

* `installJRMC --uninstall`

    Uninstall JRiver Media Center and its associated services and firewall rules. This will **not** remove your media, media library/database, or automated library backup folder.

## Additional Info

Did you find `installJRMC` useful? [Buy me a coffee!](https://paypal.me/bryanroessler?locale.x=en_US)

Did you find a bug? Let me know on [Interact!](https://yabb.jriver.com/interact/index.php/topic,123648.0.html)
