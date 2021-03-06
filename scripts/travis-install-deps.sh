#!/bin/bash

mkdir -p $STACK_SRC
mkdir -p $PACKAGES_DIR

echo "Setting up dependencies"

echo "APT"
sudo apt-get -qy install curl automake cmake gfortran clang git valgrind

cd $STACK_SRC
echo "Downloading mpich"
curl -s -L -O http://www.mpich.org/static/downloads/3.2/mpich-3.2.tar.gz
tar -xf mpich-3.2.tar.gz -C .

mkdir $STACK_SRC/mpich-3.2/clang-build
cd $STACK_SRC/mpich-3.2/clang-build

if [ "$CXX" == "clang++" ]; then
    ../configure --prefix=$PACKAGES_DIR/mpich-3.2 \
    --enable-shared \
    --enable-sharedlibs=clang \
    --enable-fast=03 \
    --enable-debuginfo \
    --enable-totalview \
    --enable-two-level-namespace \
    CC=clang \
    CXX=clang++ \
    FC=gfortran \
    F77=gfortran
elif [ "$CXX" == "g++" ]; then
    ../configure --prefix=$PACKAGES_DIR/mpich-3.2 \
    --enable-shared \
    --enable-fast=03 \
    --enable-debuginfo \
    --enable-totalview \
    --enable-two-level-namespace \
    CC=gcc \
    CXX=g++ \
    FC=gfortran \
    F77=gfortran
else
    echo "ERROR: unknown compiler"
    exit 1
fi

echo "Building mpich"
make -j $MAKE_THREADS 1>>build.log
make install 1>>build.log

export PATH=$PACKAGES_DIR/mpich-3.2/bin:$PATH
export CC=mpicc
export CXX=mpicxx
export FC=mpif90
export F90=mpif90
export C_INCLUDE_PATH=$PACKAGES_DIR/mpich-3.2/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$PACKAGES_DIR/mpich-3.2/include:$CPLUS_INCLUDE_PATH
export FPATH=$PACKAGES_DIR/mpich-3.2/include:$FPATH
export MANPATH=$PACKAGES_DIR/mpich-3.2/share/man:$MANPATH
export LD_LIBRARY_PATH=$PACKAGES_DIR/mpich-3.2/lib:$PACKAGES_DIR/mpich-3.2/lib/openmpi:$LD_LIBRARY_PATH

echo "Building PETSc"
unset PETSC_DIR
cd $STACK_SRC
curl -s -L -O http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.7.4.tar.gz
tar -xf petsc-3.7.4.tar.gz -C .

cd $STACK_SRC/petsc-3.7.4

./configure \
--prefix=$PACKAGES_DIR/petsc-3.7.4 \
--download-hypre=1 \
--with-ssl=0 \
--with-debugging=no \
--with-pic=1 \
--with-shared-libraries=1 \
--with-cc=mpicc \
--with-cxx=mpicxx \
--with-fc=mpif90 \
--download-fblaslapack=1 \
--download-metis=1 \
--download-parmetis=1 \
--download-superlu_dist=1 \
--download-mumps=1 \
--download-scalapack=1 \
--CFLAGS='-fPIC' \
--CXXFLAGS='-fPIC' \
--FFLAGS='-fPIC' \
--FCFLAGS='-fPIC' \
--F90FLAGS='-fPIC' \
--F77FLAGS='-fPIC'

make PETSC_DIR=$STACK_SRC/petsc-3.7.4 PETSC_ARCH=arch-linux2-c-opt all
make PETSC_DIR=$STACK_SRC/petsc-3.7.4 PETSC_ARCH=arch-linux2-c-opt install 1>>build.log
make PETSC_DIR=$PACKAGES_DIR/petsc-3.7.4 PETSC_ARCH="" test 1>>build.log

export PETSC_DIR=$PACKAGES_DIR/petsc-3.7.4

echo "Building SLEPc"
git clone --depth 100 -b v3.7.3 https://bitbucket.org/slepc/slepc.git $STACK_SRC/slepc
cd $STACK_SRC/slepc
./configure --prefix=$PACKAGES_DIR/slepc-3.7.3
make SLEPC_DIR=$STACK_SRC/slepc PETSC_DIR=$PACKAGES_DIR/petsc-3.7.4
make SLEPC_DIR=$STACK_SRC/slepc PETSC_DIR=$PACKAGES_DIR/petsc-3.7.4 install 1>>build.log
make SLEPC_DIR=$PACKAGES_DIR/slepc-3.7.3 PETSC_DIR=$PACKAGES_DIR/petsc-3.7.4 PETSC_ARCH="" test 1>>build.log

export SLEPC_DIR=$PACKAGES_DIR/slepc-3.7.3

echo "Building libMesh"
git clone --depth 100 -b v1.0.0 https://github.com/libMesh/libmesh.git $STACK_SRC/libmesh
cd $STACK_SRC/libmesh
METHODS="dbg" ./configure --prefix=$PACKAGES_DIR/libmesh
make -j $MAKE_THREADS
make install 1>>build.log
