#!/usr/bin/env bash
shopt -s extglob

# Usage: ./install_MC_fedora.sh [-v|--version] [version] [-b|--build-mode] [-i|--install-repo] [-p|--password]
# e.g. ./install_MC_fedora.sh -v 25.0.48
# If no version number is specified (i.e. ./install_MC_fedora.sh or ./install_MC_fedora.sh -b), the script
# will attempt to install the latest version from Interact
# Beta team members can add the beta password to autoamtically check for beta versions

# URL for latest MC for Linux board (for automatic version scraping)
boardurl="https://yabb.jriver.com/interact/index.php/board,62.0.html"

##########################
####### FUNCTIONS ########
##########################

parse_input_and_version () {

    # clear user vars
    build_mode=false
    install_mode=false

    # parse user input
    while (( "$#" )); do
        case "$1" in
            -i |--install-repo )
                echo "Installing repo file!"
                install_mode=true
                ;;
            -b |--build-mode )
                echo "Using build mode!"
                build_mode=true
                ;;
            -v |--version )
                shift
                version="$1"
                ;;
            -p |--password )
                shift
                betapwd="$1"
                ;;
            +([0-9]).[0-9].+([0-9]) )
                version="$1"
                ;;
        esac
        shift
    done

    # If version number not supplied by user, scrape Interact
    [ -z "$version" ] && version=$(curl -s "$boardurl" | grep -o "2[0-9]\.[0-9]\.[0-9]\+" | head -n 1)
    [ -z "$version" ] && read -t 60 -p "Version number cannot be scraped, re-enter it now manually, otherwise Ctrl-C to exit: " version
    [ -z "$version" ] && echo "No version number available, exiting..." && exit 0

    # parse version number
    variation=${version##*.}
    mversion=${version%%.*}
}


find_os () {

    if [ "$build_mode" == false ]; then
        if [ -e /etc/os-release ]; then
            source /etc/os-release
            if [ "$ID" = "centos" ] && [ "$VERSION_ID" -ge "8" ]; then
                PM="yum"
            elif [ "$ID" = "fedora" ]; then
                PM="dnf"
            elif [ "$install_mode" == false ]; then
                echo "You are not running Fedora or CentOS >=8, falling back to build mode..."
                build_mode=true
            fi
        elif [ "$install_mode" == false ]; then
            echo "You are not running Fedora or CentOS >=8, falling back to build mode..."
            build_mode=true
        fi
    fi
}


get_source_deb () {

    # If deb file exists, skip download
    if [ -f $builddir/SOURCES/MediaCenter-${version}-amd64.deb ]; then
        echo "Using local DEB file: $builddir/SOURCES/MediaCenter-${version}-amd64.deb"
        return
    fi

    # Acquire DEB
    echo "Attempting to download MC $version DEB file..."
    wget -q -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb \
               http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-${version}-amd64.deb
    if [ $? -ne 0 ]; then
        echo "Specified Media Center version not found! Retrying the test repo..."
        wget -q -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb \
                   http://files.jriver.com/mediacenter/test/MediaCenter-${version}-amd64.deb
    fi
    if [ $? -ne 0 ]; then
        [ -z $betapwd ] && read -t 60 -p "Not found in test repo, if beta version, enter beta password to retry, otherwise Ctrl-C to exit: " betapwd
        [ -z $betapwd ] && echo "Cannot find DEB file, re-check version number or beta password. Exiting..." && exit 1
        wget -q -O $builddir/SOURCES/MediaCenter-${version}-amd64.deb \
                   http://files.jriver.com/mediacenter/channels/v${mversion}/beta/${betapwd}/MediaCenter-${version}-amd64.deb
        [ $? -ne 0 ] && echo "Cannot find DEB file, re-check version number or beta password. Exiting..." && exit 1
    fi

    if [ -f $builddir/SOURCES/MediaCenter-${version}-amd64.deb ]; then
        echo "Downloaded MC $version DEB file to $builddir/SOURCES/MediaCenter-${version}-amd64.deb"
    else
        echo "Downloaded DEB file missing or corrupted, exiting..."
        exit 1
    fi
}


install_dependencies () {

    if [ $build_mode == false ]; then
        if ! rpm --quiet --query rpmfusion-free-release; then echo "Installing rpmfusion-free-release repo..."; \
            sudo ${PM} -y --nogpgcheck install https://download1.rpmfusion.org/free/${ID}/rpmfusion-free-release-${VERSION_ID}.noarch.rpm; fi
        if ! rpm --quiet --query rpm-build; then echo "Installing rpm-build..."; sudo ${PM} install rpm-build -y; fi
        if ! rpm --quiet --query dpkg; then echo "Installing dpkg..."; sudo ${PM} install dpkg -y; fi
    else
        command -v rpmbuild >/dev/null 2>&1 || { echo "Please install rpmbuild, cannot continue, aborting..." >&2; exit 1; }
        command -v dpkg >/dev/null 2>&1 || { echo "Please install dpkg, cannot continue, aborting..." >&2; exit 1; }
    fi
}


build_rpm () {

    # skip rebuilding the rpm if it already exists
    if [ -f $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.x86_64.rpm ]; then
        echo "$builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.x86_64.rpm already exists! Skipping build step..."
        return
    fi

    # If necessary, make build directories
    [ -d SOURCES ] || mkdir -p SOURCES
    [ -d SPECS ] || mkdir -p SPECS

    # Create spec file
    echo 'Name:    MediaCenter' > SPECS/mediacenter.spec
    echo 'Version: %{_tversion}' >> SPECS/mediacenter.spec
    echo 'Release: %{?_variation:%{_variation}}' >> SPECS/mediacenter.spec
    echo 'Summary: JRiver Media Center' >> SPECS/mediacenter.spec
    echo 'Group:   Applications/Media' >> SPECS/mediacenter.spec
    echo "Source0: http://files.jriver.com/mediacenter/channels/v${mversion}/latest/MediaCenter-%{_version}-amd64.deb" >> SPECS/mediacenter.spec
    echo '' >> SPECS/mediacenter.spec
    if [ $build_mode == false ]; then
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
    cd "$builddir"/SPECS
    echo "Building version ${version}, please wait..."
    rpmbuild --quiet --define="%_topdir $builddir" --define="%_variation $variation" --define="%_tversion ${mversion}" \
             --define="%_version ${version}" --define="%_libdir /usr/lib" -bb mediacenter.spec
}


install_rpm () {

    # skip installing same version
    installed_ver="$(rpm --query MediaCenter)"
    to_be_installed_ver="MediaCenter-${mversion}-${variation}.x86_64"
    if [ "$installed_ver" == "$to_be_installed_ver" ]; then
        echo "JRiver Media Center $version is already installed! Skipping installation..."
        return
    fi

    # install rpm
    if [ -f $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.x86_64.rpm ]; then
        echo "Attempting to install version ${version}..."
        sudo ${PM} install $builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.x86_64.rpm -y
        if [ $? -eq 0 ]; then
            echo "JRiver Media Center ${version} was installed successfully!"
        else
            echo "JRiver Media Center ${version} installation failed!"
            exit 1
        fi
    else
        echo "$builddir/RPMS/x86_64/MediaCenter-${mversion}-${variation}.x86_64.rpm is missing!"
        echo "JRiver Media Center ${version} installation failed!"
        exit 1
    fi
}


install_repo () {

    echo "Installing repo file to /etc/yum.repos.d/jriver.repo"
    sudo bash -c 'cat << EOF > /etc/yum.repos.d/jriver.repo
[jriver]
name=JRiver Media Center repo by BryanC
baseurl=https://repos.bryanroessler.com/jriver
gpgcheck=0
EOF'

    echo "Installing latest JRiver Media Center from repo..."
    sudo ${PM} update && sudo ${PM} install MediaCenter -y
    if [ $? -eq 0 ]; then
        echo "JRiver Media Center installed successfully!"
        echo "You can check for future MC updates by running \"sudo dnf|yum update\""
        echo "To remove the repo file run \"sudo rm /etc/yum.repos.d/jriver.repo\""
    else
        echo "JRiver Media Center installation failed!"
        exit 1
    fi
}


symlink_certs_and_restore () {

    if [ ! -e /etc/ssl/certs/ca-certificates.crt ] && [ -e /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem ]; then
        echo "Symlinking ca-certificates for license registration..."
        sudo ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-certificates.crt
        read -p "To install your .mjr license, enter the full filepath to your .mjr file, or enter Ctrl-C to skip: " restorefile
        while [ ! -z "$restorefile" ] || [ ! -f "$restorefile" ]; do
            echo "File not found!"
            read -p "To install your .mjr license, enter the full filepath to your .mjr file, or enter Ctrl-C to skip: " restorefile
        done
        mediacenter${mversion} /RestoreFromFile "$restorefile"
    fi
}





##########################
######## EXECUTE #########
##########################

# set build directory to current path
builddir="$(pwd)"

parse_input_and_version "${@}"
[ "$install_mode" == true ] && find_os \
                            && install_dependencies \
                            && install_repo \
                            && symlink_certs_and_restore \
                            && exit 0
find_os
get_source_deb
install_dependencies
build_rpm
[ "$build_mode" == true ] && exit 0
install_rpm
symlink_certs_and_restore

exit 0
