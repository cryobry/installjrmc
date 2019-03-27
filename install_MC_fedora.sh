#!/usr/bin/env bash

# Get MC version from user input
builddir=`readlink -f .`
version=${1:?You must enter a MediaCenter version.}
release=`sed -nre "s/.*:([0-9]+)$/\1/gp" /etc/system-release-cpe`
variation=${version##*.}
mversion=${version%%.*}

# Prettify output
bold=$(tput bold)
normal=$(tput sgr0)

# Get host OS name and version
if [ -e /etc/os-release ]; then 
    source /etc/os-release
else
    echo "Can't determine host OS, exiting..."
    exit 1
fi

# Set repo IDs and package manager based on distro
if [ $ID = "centos" ]; then
    ID="el"
    SID="el"
    PM="yum"
elif [ $ID = "fedora" ]; then
    ID="fedora"
    SID="fc"
    PM="dnf"
else
    echo "OS does not appear to be CentOS or Fedora, exiting..."
    exit 1
fi

# If necessary, install RPMFusion repos, dpkg, and rpm-build
if ! rpm --quiet --query rpmfusion-free-release; then
    echo "${bold}Installing rpmfusion-free-release repo...${normal}"
    sudo ${PM} -y --nogpgcheck install https://download1.rpmfusion.org/free/${ID}/rpmfusion-free-release-${VERSION_ID}.noarch.rpm
fi

#if ! rpm --quiet --query rpmfusion-nonfree-release; then
#    echo "${bold}Installing rpmfusion-nonfree-release repo...${normal}"
#    sudo ${PM} -y --nogpgcheck install https://download1.rpmfusion.org/nonfree/${ID}/rpmfusion-nonfree-release-${VERSION_ID}.noarch.rpm
#fi

if ! rpm --quiet --query rpm-build; then
    echo "${bold}Installing rpm-build...${normal}"
    sudo ${PM} install rpm-build -y
fi

if ! rpm --quiet --query dpkg; then
    echo "${bold}Installing dpkg...${normal}"
    sudo ${PM} install dpkg -y
fi

# If necessary, make build directories
[ -d SOURCES ] || mkdir -p SOURCES
[ -d SPECS ] || mkdir -p SPECS

# Create spec file
echo 'Name:    MediaCenter' > SPECS/mediacenter.spec
echo 'Version: %{_tversion}' >> SPECS/mediacenter.spec
echo 'Release: %{?_variation:%{_variation}}%{?dist}' >> SPECS/mediacenter.spec
echo 'Summary: JRiver Media Center' >> SPECS/mediacenter.spec
echo 'Group:   Applications/Media' >> SPECS/mediacenter.spec
echo "Source0: http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-%{_version}-amd64.deb" >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo 'BuildRequires: rpm >= 4.11.0' >> SPECS/mediacenter.spec
echo 'BuildRequires: dpkg' >> SPECS/mediacenter.spec
echo 'BuildArch: x86_64' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo 'AutoReq:  0' >> SPECS/mediacenter.spec
echo 'Requires: libnotify librtmp lame vorbis-tools alsa-lib' >> SPECS/mediacenter.spec
echo 'Requires: libX11 libX11-common libxcb libXau libXdmcp libuuid' >> SPECS/mediacenter.spec
echo 'Requires: gtk3 mesa-libGL gnutls lame libgomp webkit2gtk3 ca-certificates' >> SPECS/mediacenter.spec
echo 'Requires: gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-ugly gstreamer1-libav' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo 'License: Copyright 1998-2013, JRiver, Inc.  All rights reserved.  Protected by U.S. patents #7076468 and #7062468' >> SPECS/mediacenter.spec
echo 'URL:     http://www.jriver.com/' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%description' >> SPECS/mediacenter.spec
echo 'Media Center is more than a world class player.' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%global __os_install_post %{nil}' >> SPECS/mediacenter.spec
echo '%prep' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%build' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%install' >> SPECS/mediacenter.spec
echo 'dpkg -x %{S:0} %{buildroot}' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%post -p /sbin/ldconfig' >> SPECS/mediacenter.spec
echo '%postun -p /sbin/ldconfig' >> SPECS/mediacenter.spec
echo '' >> SPECS/mediacenter.spec
echo '%files' >> SPECS/mediacenter.spec
echo "%{_bindir}/mediacenter${mversion}" >> SPECS/mediacenter.spec
echo '%{_libdir}/jriver' >> SPECS/mediacenter.spec
echo '%{_datadir}' >> SPECS/mediacenter.spec
echo '/etc/security/limits.d/*' >> SPECS/mediacenter.spec

# Acquire deb
if [ ! -f $builddir/SOURCES/MediaCenter-${version}-amd64.deb ]; then
    echo "${bold}Downloading source DEB...${normal}"
    wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-${version}-amd64.deb
    if [ $? -ne 0 ]; then
        echo "${bold}Specified Media Center version not found! Retrying the test repo...${normal}"
        wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/test/MediaCenter-${version}-amd64.deb
        if [ $? -ne 0 ]; then
            read -p "${bold}Not found in test repo, if beta version, enter beta password to retry, otherwise Ctrl-C to exit: ${normal}" betapwd
            wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/channels/v${mversion}/beta/${betapwd}/MediaCenter-${version}-amd64.deb
            if [ $? -ne 0 ]; then
                echo "Beta password wrong or specified Media Center version not found, exiting..."
                exit 1
            fi
        fi
    fi
fi

# Run rpmbuild
echo "${bold}Converting DEB to RPM...${normal}"
cd ${builddir}/SPECS
rpmbuild --quiet --define="%_topdir $builddir" --define="%_variation $variation" --define="%_tversion ${mversion}" --define="%_version ${version}" --define="%_libdir /usr/lib" -bb mediacenter.spec

# Install RPM
if [ -f $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${release}.x86_64.rpm ] ; then
    echo "${bold}Attempting to install RPM...${normal}"
    sudo ${PM} install $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${release}.x86_64.rpm -y && echo "${bold}JRiver Media Center ${version} installed successfully!${normal}"
else
    echo "${bold}Conversion Failed!${normal}"
    exit 1
fi

# Symlink certificates
if [ ! -e /etc/ssl/certs/ca-certificates.crt ]; then
    if [ -e /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem ]; then
        echo "${bold}Symlinking ca-certificates for license registration...${normal}"
        sudo ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-certificates.crt
    fi
fi

exit 0

