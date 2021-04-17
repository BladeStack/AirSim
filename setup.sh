#! /bin/bash
set -x
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd "$SCRIPT_DIR" >/dev/null

downloadHighPolySuv=true
MIN_CMAKE_VERSION=3.10.0
function version_less_than_equal_to() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" = "$1"; }

# Parse command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --no-full-poly-car)
    downloadHighPolySuv=false
    shift # past value
    ;;
esac
done

# llvm tools for arch-linux
# libvulkan1 on ubuntu = nvidia + lib32-nvidia-utils on arch
#sudo pacman -S lsb-release \
#        rsync \
#        wget \
#        nvidia \
#        nvidia-utils \
#        lib32-nvidia-utils \
#        vulkan-tools

if ! which cmake; then
    # CMake not installed
    cmake_ver=0
else
    cmake_ver=$(cmake --version 2>&1 | head -n1 | cut -d ' ' -f3 | awk '{print $NF}')
fi
#give user perms to access USB port - this is not needed if not using PX4 HIL
#TODO: figure out how to do below in travis
# Install additional tools, CMake if required
#    if [[ ! -z "${whoami}" ]]; then #this happens when running in travis
#        sudo /usr/sbin/useradd -G dialout $USER
#        sudo usermod -a -G dialout $USER
#    fi
#
#    # install additional tools
#    sudo apt-get install -y build-essential unzip
#
#    if version_less_than_equal_to $cmake_ver $MIN_CMAKE_VERSION; then
#        # in ubuntu 18 docker CI, avoid building cmake from scratch to save time
#        # ref: https://apt.kitware.com/
#        if [ "$(lsb_release -rs)" == "18.04" ]; then
#            sudo apt-get -y install \
#                apt-transport-https \
#                ca-certificates \
#                gnupg
#            wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
#            sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'
#            sudo apt-get -y install --no-install-recommends \
#                make \
#                cmake
#
#        else
#    else
#        echo "Already have good version of cmake: $cmake_ver"
#    fi
#
#fi # End USB setup, CMake install
#
#
# Download rpclib
if [ ! -d "external/rpclib/rpclib-2.2.1" ]; then
    echo "*********************************************************************************************"
    echo "Downloading rpclib..."
    echo "*********************************************************************************************"

    wget https://github.com/madratman/rpclib/archive/v2.2.1.zip

    # remove previous versions
    rm -rf "external/rpclib"

    mkdir -p "external/rpclib"
    unzip -q v2.2.1.zip -d external/rpclib
    rm v2.2.1.zip
fi

# Download high-polycount SUV model
if $downloadHighPolySuv; then
    if [ ! -d "Unreal/Plugins/AirSim/Content/VehicleAdv" ]; then
        mkdir -p "Unreal/Plugins/AirSim/Content/VehicleAdv"
    fi
    if [ ! -d "Unreal/Plugins/AirSim/Content/VehicleAdv/SUV/v1.2.0" ]; then
            echo "*********************************************************************************************"
            echo "Downloading high-poly car assets.... The download is ~37MB and can take some time."
            echo "To install without this assets, re-run setup.sh with the argument --no-full-poly-car"
            echo "*********************************************************************************************"

            if [ -d "suv_download_tmp" ]; then
                rm -rf "suv_download_tmp"
            fi
            mkdir -p "suv_download_tmp"
            cd suv_download_tmp
            wget  https://github.com/Microsoft/AirSim/releases/download/v1.2.0/car_assets.zip
            if [ -d "../Unreal/Plugins/AirSim/Content/VehicleAdv/SUV" ]; then
                rm -rf "../Unreal/Plugins/AirSim/Content/VehicleAdv/SUV"
            fi
            unzip -q car_assets.zip -d ../Unreal/Plugins/AirSim/Content/VehicleAdv
            cd ..
            rm -rf "suv_download_tmp"
    fi
else
    echo "### Not downloading high-poly car asset (--no-full-poly-car). The default unreal vehicle will be used."
fi

echo "Installing Eigen library..."

if [ ! -d "AirLib/deps/eigen3" ]; then
    echo "Downloading Eigen..."
    wget -O eigen3.zip https://gitlab.com/libeigen/eigen/-/archive/3.3.7/eigen-3.3.7.zip
    unzip -q eigen3.zip -d temp_eigen
    mkdir -p AirLib/deps/eigen3
    mv temp_eigen/eigen*/Eigen AirLib/deps/eigen3
    rm -rf temp_eigen
    rm eigen3.zip
else
    echo "Eigen is already installed."
fi

popd >/dev/null

set +x
echo ""
echo "************************************"
echo "AirSim setup completed successfully!"
echo "************************************"
