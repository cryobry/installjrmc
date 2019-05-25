# install_MC_fedora.sh

**Notes:**
1. 64-bit only
2. This script will not point major upgrades (i.e. from v24 to v25) to the old library. It is recommended to first perform a library backup, install the new major version, and then restore the library backup.

**How to run:**

1. Download the script

2a. Install or update MC (the script will ask for your sudo password to install packages): 
`./install_MC_fedora.sh 25.0.41` (where 25.0.41 is the current Debian AMD64 version)

2b. If no version number is specified the script will try to scrape Interact for the latest MC version

2c. If beta version, the script will prompt for the beta team password 

3. (Optional) Install your .mjr license: 
  `mediacenter25 /RestoreFromFile YOURMEDIACENTER23MJRFILE.mjr`



Additional info can be found at [Interact](https://yabb.jriver.com/interact/index.php/topic,119981.0.html).

