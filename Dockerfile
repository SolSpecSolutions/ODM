FROM osgeo/gdal:alpine-normal-latest
MAINTAINER Nathan Casler <ncasler@solspec.io>

WORKDIR /code

ENV OPENCV_VERSION=4.0.1 \
    CERES_VERSION=1.14.0 \
    PDAL_VERSION=1.9.1 \
    PCL_VERSION=1.9.1

#Following commands are pulled from PDAL/alpinebase

#
# Nitro looks for unistd.h in the wrong place
#
RUN \
    mkdir -p /usr/include/linux; \
    ln -sf /usr/include/unistd.h /usr/include/linux/unistd.h

RUN \
    echo "@edgetesting http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories; \
    echo "@edgemain http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories; \
    echo "@edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
    apk update; \
    apk add --no-cache \
        git \
        cmake \
        ninja \
        g++; \
    apk add --no-cache \
        eigen-dev \
        libxml2-dev \
        libexecinfo-dev@edgemain \
        libunwind@edgemain \
        flann-dev@edgetesting \
        gtest-dev@edgemain \
        libtbb@edgetesting \
        sqlite-dev \
        libcrypto1.1@edgemain \
        libspatialite-dev@edgetesting \
        libgeotiff-dev@edgetesting \
        nitro@edgetesting \
        nitro-dev@edgetesting \
        laszip-dev@edgetesting \
        laz-perf-dev@edgetesting \
        hdf5-dev@edgetesting \
        build-base \
        boost-dev@edgemain \
        ca-certificates \
        coreutils \
        curl \
        curl-dev \
        ffmpeg-dev \
        ffmpeg-libs \
        flann@edgetesting \
        freetype-dev \
        gettext \
        gflags-dev@edgecommunity \
        gfortran \
        glib-dev \
        glog-dev@edgetesting \
        lcms2-dev \
        libavc1394-dev \
        libffi-dev \
        libgfortran \
        libtbb-dev@edgetesting \
        libxext-dev \
        libressl-dev \
        libtool \
        linux-headers \
        numactl@edgemain \
        nlohmann-json@edgetesting \
        openmpi@edgetesting \
        openblas-dev \
        pcl@edgetesting \
        postgresql-dev@edgemain \
        py-numpy-dev \
        py3-numpy \
        py-scipy \
        py-matplotlib@edgetesting \
        py3-scipy \
        python3-dev \
        python2-dev \
        py2-pip \
        py3-pip \
        mesa-dev \
        mesa-osmesa \
        readline-dev \
        suitesparse@edgecommunity \
        swig \
        tcl-dev \
        tiff-dev \
        vim \
        zlib-dev \
    && rm -rf /var/cache/* \
    && rm -rf /root/.cache/*

# Python Libraries
RUN  \
    pip install \
    setuptools \
    wheel \
    appsettings \
    exifread==2.1.2 \
    gdal \
    gpxpy==1.1.2 \
    loky \
    psutil \
    pyproj==2.1.2 \
    pyYAML \
    repoze.lru \
    shapely \
    xmltodict==0.10.2 \
    networkx==1.11 \
    attrs \
    pyodm \
    pytest==3.0.7 \
    python-dateutil==2.6.0 \
    rasterio

# Install vtk
RUN \
    wget -nv -O- http://www.vtk.org/files/release/7.1/VTK-7.1.0.tar.gz | \
    tar xz && \
    cd VTK-7.1.0 && \
    cmake \
    -D CMAKE_BUILD_TYPE:STRING=Release \
    -D CMAKE_INSTALL_PREFIX:STRING=/usr \
    -D BUILD_DOCUMENTATION:BOOL=OFF \
    -D BUILD_EXAMPLES:BOOL=OFF \
    -D BUILD_TESTING:BOOL=OFF \
    -D BUILD_SHARED_LIBS:BOOL=ON \
    -D VTK_USE_X:BOOL=OFF \
    -D VTK_OPENGL_HAS_OSMESA:BOOL=ON \
    -D OSMESA_LIBRARY=/usr/lib/libOSMesa.so.8 \
    -D OSMESA_INCLUDE_DIR=/usr/include/GL/ \
    -D VTK_RENDERING_BACKEND:STRING=OpenGL \
    -D VTK_Group_MPI:BOOL=OFF \
    -D VTK_Group_StandAlone:BOOL=OFF \
    -D VTK_Group_Rendering:BOOL=ON \
    -D VTK_WRAP_PYTHON=ON \
    -D VTK_PYTHON_VERSION:STRING=2 \
    -D Module_vtkIOPLY:BOOL=ON \
    -D Module_vtkIOGeometry:BOOL=ON \
    . && \
    make -j $(nproc) && \
    make install && \
    cd .. && rm -rf VTK-7.1.0

    #
    # These use PDAL's vendor/eigen
    #
#RUN \
#    git clone https://github.com/gadomski/fgt.git \
#    && cd fgt \
#    && mkdir build \
#    && cd build \
#    && cmake .. \
#        -G Ninja \
#        -DCMAKE_BUILD_TYPE=Release \
#    && ninja install \
#    && cd / \
#    && rm -rf fgt \
#    && git clone https://github.com/gadomski/cpd.git \
#    && cd cpd \
#    && mkdir build \
#    && cd build \
#    && cmake .. \
#        -G Ninja \
#        -DCMAKE_BUILD_TYPE=Release \
#    && ninja install \
#    && cd / \
#    && rm -rf cpd

# PDAL
RUN    \
    git clone https://github.com/PDAL/PDAL.git --branch 1.9-maintenance --single-branch pdal \
    && cd pdal \
    && mkdir build \
    && cd build \
    && cmake .. \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_PLUGIN_PYTHON=ON \
        -DBUILD_PLUGIN_NITF=OFF \
        -DBUILD_PLUGIN_GREYHOUND=OFF \
        -DBUILD_PLUGIN_CPD=OFF \
        -DBUILD_PLUGIN_ICEBRIDGE=OFF \
        -DBUILD_PLUGIN_PGPOINTCLOUD=OFF \
        -DBUILD_PLUGIN_SQLITE=OFF \
        -DBUILD_PLUGIN_I3S=OFF \
        -DWITH_LASZIP=ON \
        -DWITH_LAZPERF=ON \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_INSTALL_LIBDIR=lib \
    && ninja install \
    && cd / \
    && rm -rf pdal \
    && rm -rf /usr/share/hdf5_examples

# OpenCV

RUN mkdir -p /tmp/opencv \
    && curl -sfL https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz | tar zxf - -C /tmp/opencv --strip-components=1 \
    && cd /tmp/opencv && mkdir build && cd build \
    && cmake -DBUILD_TIFF=ON \
             -DBUILD_opencv_python2=ON \
             -DWITH_CUDA=OFF \
             -DWITH_OPENGL=ON \
             -DWITH_OPENCL=ON \
             -DWITH_IPP=ON \
             -DWITH_TBB=OFF \
             -DWITH_EIGEN=ON \
             -DWITH_V4L=ON \
             -DWITH_FFMPEG=ON \
             -DWITH_VTK=OFF \
             -DBUILD_opencv_java=OFF \
             -DBUILD_TESTS=OFF \
             -DBUILD_PERF_TESTS=OFF \
             -DCMAKE_BUILD_TYPE=Release \
             -DPYTHON_EXECUTABLE=$(which python) \
             -DPYTHON_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
             -DPYTHON_PACKAGES_PATH=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
             -DPYTHON3_EXECUTABLE=$(which python3) \
             -DPYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
             -DPYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
             .. \
            && make -j $(nproc) install \
            && rm -rf /tmp/opencv

# CERES
RUN mkdir -p /tmp/ceres \
    && curl -sfL http://ceres-solver.org/ceres-solver-${CERES_VERSION}.tar.gz | tar zxf - -C /tmp/ceres --strip-components=1 \
    && cd /tmp/ceres && mkdir build && cd build \
    && cmake .. \
        -DCMAKE_C_FLAGS=-fPIC \
        -DCMAKE_CXX_FLAGS=-fPIC \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_TESTING=OFF \
    && make -j $(nproc) install \
    && rm -rf /tmp/ceres

# OpenGV
RUN cd /tmp \
    && git clone https://github.com/paulinus/opengv.git \
    && cd opengv \
    && git submodule update --init --recursive \
    && mkdir -p build && cd build \
    && cmake \
        -DBUILD_TESTS=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_PYTHON=ON \
        -DPYBIND11_PYTHON_VERSION=2.7 \
        -DHAS_FLTO=OFF \
        -DPYTHON_INSTALL_DIR=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
        .. \
    && make -j $(nproc) install \
    && cd /tmp && rm -rf /tmp/opengv

# OpenSFM 
RUN cd /tmp \
    && git clone --branch 'Suppress_fortify' --single-branch https://github.com/npcasler/OpenSFM.git \
    && cd OpenSFM \
    && git submodule update --init --recursive \
    && python setup.py build \
    && python setup.py install \
    && ls bin \
    && cp bin/export_bundler /usr/bin/export_bundler \
    && rm -rf /tmp/OpenSFM


# PCL
RUN \
    mkdir /tmp/pcl \
    && curl -sfL https://github.com/PointCloudLibrary/pcl/archive/pcl-1.9.0.tar.gz | tar zxf - -C /tmp/pcl --strip-components=1 \
    && cd /tmp/pcl && mkdir build && cd build \
    && cmake .. \
            -DCMAKE_INSTALL_PREFIX=/usr/local \
            -DCMAKE_BUILD_TYPE=Release \
            -DWITH_CUDA=OFF \
            -DWITH_DAVIDSDK=OFF \
            -DWITH_DSSDK=OFF \
            -DWITH_ENSENSO=OFF \
            -DWITH_RSSDK=OFF \
            -DWITH_FZAPI=OFF \
            -DWITH_LIBUSB=OFF \
            -DWITH_OPENGL=OFF \
            -DWITH_OPENNI=OFF \
            -DWITH_OPENNI2=OFF \
            -DWITH_PCAP=OFF \
            -DWITH_PNG=OFF \
            -DWITH_QHULL=OFF \
            -DWITH_QT=OFF \
            -DWITH_VTK=OFF \
            -DBUILD_global_tests=OFF \
            -DBUILD_examples=OFF \
            -DBUILD_tools=ON \
            -DBUILD_apps=OFF \
            -DBUILD_tests_segmentation=OFF \
            -DBUILD_tests_common=OFF \
            -DBUILD_tests_features=OFF \
            -DBUILD_tests_filters=OFF \
            -DBUILD_tests_io=OFF \
            -DBUILD_tests_registration=OFF \
    && make -j $(nproc) install \
    && rm -rf /tmp/pcl

# MvsTexturing
RUN \
    cd /tmp \
    && git clone --branch 'Rebase_to_nmoehrle' --single-branch https://github.com/npcasler/mvs-texturing \
    && cd /tmp/mvs-texturing \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make -j $(nproc) install \
    && rm -rf /tmp/mvs-texturing

COPY . /code
# ODM
RUN chmod -R 777 /code \
    && cd /code \
    && cd SuperBuild \
    && mkdir build \
    && cd build \
    && cmake \
        -DOPENGV_DIR=/usr/local \
        -DMvsTexturing_ROOT_DIR=/usr/local \
        .. \
    && make -j $(nproc) \
    && cd ../.. \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j $(nproc)

RUN rm -rf \
    /code/SuperBuild/build/opencv \
    /code/SuperBuild/download \
    /code/SuperBuild/src/ceres \
    /code/SuperBuild/src/mvstexturing \
    /code/SuperBuild/src/opencv \
    /code/SuperBuild/src/opengv \
    /code/SuperBuild/src/pcl \
    /code/SuperBuild/src/pdal

ENV PYTHONPATH "${PYTHONPATH}:/usr/local/lib/python2.7/site-packages"
ENV PATH "${PATH}:/code/SuperBuild/src/elibs/mve/apps"

ENTRYPOINT ["python", "run.py", "code"]
