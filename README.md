# install_MC_fedora.sh

**Notes:**
1. 64-bit only
2. This script will not point major upgrades (i.e. from v24 to v25) to the old library. It is recommended to first perform a library backup, install the new major version, and then restore the library backup.

**How to run:**

`./install_MC_fedora.sh [-v|--version] [version] [-b|--build-mode] [-i|--install-repo] [-p|--password]`

1. Download the script

2A. Install or update MC locally (the script will ask for your sudo password to install packages):
`./install_MC_fedora.sh 25.0.48` (where 25.0.48 is the current Debian AMD64 version)

If no version number is specified the script will try to scrape Interact for the latest MC version

If beta version, the script will prompt for the beta team password

2B. Install the repo file: `./install_MC_fedora.sh -i`

3. (Optional) Install your .mjr license:
  `mediacenter25 /RestoreFromFile YOURMEDIACENTER25MJRFILE.mjr`



Additional info can be found at [Interact](https://yabb.jriver.com/interact/index.php/topic,119981.0.html).
