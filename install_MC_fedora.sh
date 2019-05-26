#!/usr/bin/env bash

# URL for latest MC for Linux board (for automatic version scraping)
boardurl="https://yabb.jriver.com/interact/index.php/board,62.0.html"

##########################
####### FUNCTIONS ########
##########################

get_source_deb () {

    # Get version number from user input or scrape Interact
    if [ ! -z ${1} ]; then
        version=${1}
    else
        echo "No version number specified, attempting automatic mode..."
        version=$(curl -s "${boardurl}" | grep -o "2[0-9]\.[0-9]\.[0-9]\+" | head -n 1)
        while [ -z ${version} ]; do
            read -p "Version number not found, re-enter it now, otherwise Ctrl-C to exit: " version
        done
    fi

    # parse version number
    variation=${version##*.}
    mversion=${version%%.*}

    # in automatic mode and build only mode, skip building/reinstalling the same version
    if [ -z ${1} ]; then
        if [ ! -z ${build_only_mode} ]; then
            if [ -f $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64.rpm ]; then
                echo "$builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64.rpm already exists!"
                exit 0
            fi
        else
            installed_ver="$(rpm --quiet --query MediaCenter)"
            to_be_installed_ver="MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64"
            if [ "${installed_ver}" == "${to_be_installed_ver}" ]; then
                echo "MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64 is already installed!"
                exit 0
            fi
        fi
    fi

    # Acquire DEB if missing
    if [ -f $builddir/SOURCES/MediaCenter-${version}-amd64.deb ]; then
        echo "Using local DEB file: $builddir/SOURCES/MediaCenter-${version}-amd64.deb"
    else
        echo "Downloading source DEB..."
        wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-${version}-amd64.deb
        if [ $? -ne 0 ]; then
            echo "Specified Media Center version not found! Retrying the test repo..."
            wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/test/MediaCenter-${version}-amd64.deb
            while [ $? -ne 0 ]; do
                read -p "Not found in test repo, if beta version, enter beta password to retry, otherwise Ctrl-C to exit: " betapwd
                wget -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb http://files.jriver.com/mediacenter/channels/v${mversion}/beta/${betapwd}/MediaCenter-${version}-amd64.deb
            done
        fi
    fi
}


install_dependencies () {

    if [ -z ${build_only_mode} ]; then
        if ! rpm --quiet --query rpmfusion-free-release; then
            echo "Installing rpmfusion-free-release repo..."
            sudo ${PM} -y --nogpgcheck install https://download1.rpmfusion.org/free/${ID}/rpmfusion-free-release-${VERSION_ID}.noarch.rpm
        fi
        if ! rpm --quiet --query rpm-build; then
            echo "Installing rpm-build..."
            sudo ${PM} install rpm-build -y
        fi
        if ! rpm --quiet --query dpkg; then
            echo "Installing dpkg..."
            sudo ${PM} install dpkg -y
        fi
    else
        pkgs='rpm dpkg'
        if ! dpkg -s ${pkgs} >/dev/null 2>&1; then
          sudo ${PM} install -y ${pkgs}
        fi
    fi
}


build_rpm () {

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
    if [ -z ${build_only_mode} ]; then
        echo 'BuildRequires: rpm >= 4.11.0' >> SPECS/mediacenter.spec
        echo 'BuildRequires: dpkg' >> SPECS/mediacenter.spec
    fi
    echo 'BuildArch: x86_64' >> SPECS/mediacenter.spec
    echo '' >> SPECS/mediacenter.spec
    echo 'AutoReq:  0' >> SPECS/mediacenter.spec
    echo 'Requires: libnotify librtmp lame vorbis-tools alsa-lib' >> SPECS/mediacenter.spec
    echo 'Requires: libX11 libX11-common libxcb libXau libXdmcp libuuid' >> SPECS/mediacenter.spec
    echo 'Requires: gtk3 mesa-libGL gnutls lame libgomp webkit2gtk3 ca-certificates' >> SPECS/mediacenter.spec
    echo 'Requires: gstreamer1 gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-ugly gstreamer1-libav' >> SPECS/mediacenter.spec
    echo '' >> SPECS/mediacenter.spec
    echo 'License: Copyright 1998-2019, JRiver, Inc.  All rights reserved.  Protected by U.S. patents #7076468 and #7062468' >> SPECS/mediacenter.spec
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

    # Run rpmbuild
    cd ${builddir}/SPECS
    rpmbuild --quiet --define="%_topdir $builddir" --define="%_variation $variation" --define="%_tversion ${mversion}" --define="%_version ${version}" --define="%_libdir /usr/lib" -bb mediacenter.spec
}


# Install RPM
install_rpm () {
    if [ -f $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64.rpm ]; then
        echo "Attempting to install RPM..."
        sudo ${PM} install $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64.rpm -y && echo "JRiver Media Center ${version} installed successfully!"
    else
        echo "Installation Failed!"
        echo "$builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.${SID}${VERSION_ID}.x86_64.rpm is missing!"
        exit 1
    fi

    # Symlink certificates
    if [ ! -e /etc/ssl/certs/ca-certificates.crt ]; then
        if [ -e /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem ]; then
            echo "Symlinking ca-certificates for license registration..."
            sudo ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-certificates.crt
        fi
    fi
}


##########################
######## EXECUTE #########
##########################

# set build directory to current path
builddir=`readlink -f .`

# Get host OS name and version and set repo IDs and package manager based on distro
if [ -e /etc/os-release ]; then
    source /etc/os-release
    if [ $ID = "centos" ]; then
        ID="el"
        SID="el"
        PM="yum"
        get_source_deb
        install_dependencies
        echo "Attempting to build version ${version}..." && build_rpm
        echo "Build complete! Attempting to install version ${version}..." && install_rpm
    elif [ $ID = "fedora" ]; then
        ID="fedora"
        SID="fc"
        PM="dnf"
        get_source_deb
        install_dependencies
        echo "Attempting to build version ${version}..." && build_rpm
        echo "Build complete! Attempting to install version ${version}..." && install_rpm
    else
        echo "You are not running Fedora or CentOS, entering build-only mode..."
        ID="fedora"
        SID=""
        PM="apt-get"
        VERSION_ID=""
        build_only_mode=1
        get_source_deb
        install_dependencies
        echo "Attempting to build version ${version}..." && build_rpm
        echo "Build complete!"
    fi
else
    echo "Can't determine host OS, exiting..."
    exit 1
fi

exit $?
