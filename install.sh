#!/bin/bash
# ===================================================================
# Weather Research and Forecasting Model (WRF) + WPS Build Script
# Dependencies included for GNU-based systems (Ubuntu/CentOS)
# Based on UCAR/MMM WRF documentation and example setups
# -------------------------------------------------------------------
# Author: Adapted from UCAR/MMM Forum and WRF community examples
# License: Public domain (reference: forum.mmm.ucar.edu, jamal919 gist)
# ===================================================================

set -e  # Exit on error

# ========== BASIC SYSTEM PREP ==========
sudo apt update
sudo apt install -y gcc gfortran g++ m4 make perl automake autoconf libtool \
  csh tcsh python3 unzip wget curl tar git grads default-jre

# ========== DIRECTORY SETUP ==========
export HOME_DIR=$(pwd)
export WRFDIR=$HOME_DIR/WRF_BUILD
mkdir -p $WRFDIR/Downloads $WRFDIR/Libs
cd $WRFDIR/Downloads

# ========== COMPILER ENVIRONMENT ==========
export DIR=$WRFDIR/Libs
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran
export FFLAGS="-m64 -fallow-argument-mismatch"
export FCFLAGS="-m64 -fallow-argument-mismatch"

# ========== DOWNLOAD DEPENDENCIES ==========
wget -c https://www.zlib.net/zlib-1.2.13.tar.gz
wget -c https://github.com/HDFGroup/hdf5/archive/hdf5-1_10_5.tar.gz
wget -c https://downloads.unidata.ucar.edu/netcdf-c/4.9.0/netcdf-c-4.9.0.tar.gz
wget -c https://downloads.unidata.ucar.edu/netcdf-fortran/4.6.0/netcdf-fortran-4.6.0.tar.gz
wget -c https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/mpich-3.0.4.tar.gz
wget -c https://download.sourceforge.net/libpng/libpng-1.6.37.tar.gz
wget -c https://www.ece.uvic.ca/~frodo/jasper/software/jasper-1.900.1.zip

# ========== BUILD LIBRARIES ==========

# ZLIB
tar -xzf zlib-1.2.13.tar.gz
cd zlib-1.2.13
./configure --prefix=$DIR
make -j4 && make install
cd ..

# HDF5
tar -xzf hdf5-1_10_5.tar.gz
cd hdf5-hdf5-1_10_5
./configure --prefix=$DIR --with-zlib=$DIR --enable-fortran --enable-hl --enable-shared
make -j4 && make install
cd ..

export HDF5=$DIR
export LD_LIBRARY_PATH=$DIR/lib:$LD_LIBRARY_PATH

# NetCDF-C
tar -xzf netcdf-c-4.9.0.tar.gz
cd netcdf-c-4.9.0
export CPPFLAGS="-I$DIR/include"
export LDFLAGS="-L$DIR/lib"
./configure --prefix=$DIR --disable-dap --enable-netcdf4
make -j4 && make install
cd ..

# NetCDF-Fortran
tar -xzf netcdf-fortran-4.6.0.tar.gz
cd netcdf-fortran-4.6.0
export CPPFLAGS="-I$DIR/include"
export LDFLAGS="-L$DIR/lib"
export LIBS="-lnetcdf -lhdf5_hl -lhdf5 -lz"
./configure --prefix=$DIR --disable-shared
make -j4 && make install
cd ..

# MPICH
tar -xzf mpich-3.0.4.tar.gz
cd mpich-3.0.4
./configure --prefix=$DIR
make -j4 && make install
cd ..

export PATH=$DIR/bin:$PATH

# LIBPNG
tar -xzf libpng-1.6.37.tar.gz
cd libpng-1.6.37
./configure --prefix=$DIR
make -j4 && make install
cd ..

# JasPer
unzip jasper-1.900.1.zip
cd jasper-1.900.1
autoreconf -i
./configure --prefix=$DIR
make -j4 && make install
cd ..

export JASPERLIB=$DIR/lib
export JASPERINC=$DIR/include

# ========== BUILD WRF ==========
cd $WRFDIR
git clone --recurse-submodules https://github.com/wrf-model/WRF.git
cd WRF
./clean
echo "Select option 34 (dmpar, gfortran/gcc) and 1 for nesting"
./configure
./compile em_real -j4 >& log.compile

# ========== BUILD WPS ==========
cd $WRFDIR
git clone https://github.com/wrf-model/WPS.git
cd WPS
export WRF_DIR=$WRFDIR/WRF
echo "Select option 1 for gfortran (serial, Grib2)"
./configure
./compile >& log.compile

# ========== ENVIRONMENT SETTINGS ==========
echo "export NETCDF=$DIR" >> ~/.bashrc
echo "export PATH=$DIR/bin:$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$DIR/lib:$LD_LIBRARY_PATH" >> ~/.bashrc
echo "export JASPERLIB=$DIR/lib" >> ~/.bashrc
echo "export JASPERINC=$DIR/include" >> ~/.bashrc
echo "export WRF_DIR=$WRFDIR/WRF" >> ~/.bashrc
source ~/.bashrc

# Finished
echo "===================================================="
echo "WRF + WPS successfully built using GNU toolchain."
echo "Executables:"
echo "  - WRF/main/*.exe"
echo "  - WPS/*.exe"
echo "===================================================="
