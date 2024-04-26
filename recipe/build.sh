#!/bin/bash

set -ex

# strip std settings from conda
CXXFLAGS="${CXXFLAGS/-std=c++14/}"
CXXFLAGS="${CXXFLAGS/-std=c++11/}"
export CXXFLAGS

if [ "$(uname)" == "Linux" ]; then
   export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"

   # need this for draco finding
   export PKG_CONFIG_PATH="$PKG_CONFIG_PATH;${PREFIX}/lib64/pkgconfig"
fi


if [ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]; then
  mkdir native; pushd native;

if [ "$(uname)" == "Darwin" ]; then
   export CXXFLAGS_NATIVE=${CXXFLAGS//$PREFIX/$BUILD_PREFIX}
   export LDFLAGS_NATIVE=${LDFLAGS//$PREFIX/$BUILD_PREFIX} \
   export CFLAGS_NATIVE=${CFLAGS//$PREFIX/$BUILD_PREFIX} \
   export EXTRA_CMAKE_ARGS=-DCMAKE_OSX_ARCHITECTURES="x86_64"
   export CC_FOR_NATIVE_BUILD=$CC_FOR_BUILD
   export CXX_FOR_NATIVE_BUILD=$CXX_FOR_BUILD
else
   export CXXFLAGS_NATIVE=${CXXFLAGS}
   export CFLAGS_NATIVE=${CFLAGS}
   export LDFLAGS_NATIVE=${LDFLAGS}
   export EXTRA_CMAKE_ARGS=""
   export CC_FOR_NATIVE_BUILD=$CC
   export CXX_FOR_NATIVE_BUILD=$CXX
fi

  CC=$CC_FOR_NATIVE_BUILD CXX=$CXX_FOR_NATIVE_BUILD \
    LDFLAGS=${LDFLAGS_NATIVE} \
    CFLAGS=${CFLAGS_NATIVE} \
    CXXFLAGS=${CXXFLAGS_NATIVE} \
    cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        ${EXTRA_CMAKE_ARGS} \
        ..

  export DIMBUILDER=`pwd`/bin/dimbuilder
  ninja dimbuilder
  popd
else
  export DIMBUILDER=dimbuilder

fi

rm -rf build
mkdir -p build
pushd build

export PDAL_BUILD_DIR=`pwd`/install
mkdir $PDAL_BUILD_DIR

if [[ "${target_platform}" == osx-* ]]; then
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

cmake -G Ninja \
  ${CMAKE_ARGS} \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DDIMBUILDER_EXECUTABLE=$DIMBUILDER \
  -DBUILD_PLUGIN_E57=ON \
  -DBUILD_PLUGIN_PGPOINTCLOUD=OFF \
  -DBUILD_PLUGIN_ARROW=OFF \
  -DENABLE_CTEST=OFF \
  -DWITH_TESTS=OFF \
  -DWITH_ZLIB=ON \
  -DWITH_ZSTD=ON \
  ..

cmake --build . --config Release
cmake --install . --prefix=$PDAL_BUILD_DIR

popd


# ArrowV
pushd plugins/arrow

rm -rf build
mkdir -p build
pushd build

cmake -G Ninja \
  ${CMAKE_ARGS} \
  -DSTANDALONE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  ..

cmake --build . --config Release --target pdal_plugin_writer_arrow pdal_plugin_reader_arrow
ls -al .

popd
popd

# Trajectory

pushd plugins/trajectory

rm -rf build
mkdir -p build
pushd build

cmake -G Ninja "$CMAKE_ARGS" \
  -DSTANDALONE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DBUILD_PLUGIN_TRAJECTORY=ON \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  ..

cmake --build . --config Release --target pdal_plugin_filter_trajectory

popd
popd

# TileDB

pushd plugins/tiledb

rm -rf build
mkdir -p build
pushd build

cmake -G Ninja ${CMAKE_ARGS} \
  -DSTANDALONE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DBUILD_PLUGIN_TILEDB=ON \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  ..

cmake --build . --config Release --target pdal_plugin_reader_tiledb pdal_plugin_writer_tiledb

popd
popd


# pgpointcloud

pushd plugins/pgpointcloud

rm -rf build
mkdir -p build
pushd build

cmake -G Ninja ${CMAKE_ARGS} \
  -DSTANDALONE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  -DBUILD_PLUGIN_PGPOINTCLOUD=ON \
  ..

cmake --build . --config Release --target pdal_plugin_reader_pgpointcloud pdal_plugin_writer_pgpointcloud

popd
popd

# NITF

pushd plugins/nitf

rm -rf build
mkdir -p build
pushd build

cmake -G Ninja \
  -DSTANDALONE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DBUILD_PLUGIN_NITF=ON \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  ..

cmake --build . --config Release --target pdal_plugin_reader_nitf pdal_plugin_writer_nitf

popd
popd

#HDF
pushd plugins/hdf

rm -rf build
mkdir -p build
pushd build


cmake -G Ninja ${CMAKE_ARGS} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  -DBUILD_PLUGIN_HDF=ON \
  -DSTANDALONE=ON \
  ..

cmake --build . --config Release --target pdal_plugin_reader_hdf

popd
popd


pushd plugins/icebridge

rm -rf build
mkdir -p build
pushd build

cmake -G Ninja ${CMAKE_ARGS} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  -DSTANDALONE=ON \
  -DBUILD_PLUGIN_ICEBRIDGE=ON \
  ..

cmake --build . --config Release --target pdal_plugin_reader_icebridge

popd
popd

# Draco

pushd plugins/draco

rm -rf build
mkdir -p build
pushd build

cmake -G Ninja ${CMAKE_ARGS} \
  -DSTANDALONE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DBUILD_PLUGIN_DRACO=ON \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  ..

cmake --build . --config Release  --target pdal_plugin_writer_draco pdal_plugin_reader_draco

popd
popd

# CPD

pushd plugins/cpd

rm -rf build
mkdir -p build
pushd build

cmake -G Ninja ${CMAKE_ARGS} \
  -DSTANDALONE=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DPDAL_DIR:PATH=$PDAL_BUILD_DIR/lib/cmake/PDAL \
  ..

cmake --build . --config Release  --target pdal_plugin_filter_cpd

popd
popd

