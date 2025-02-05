##########################
# Andrey Fomin <andreyafomin at icloud dot com>
##########################

FROM <redactedcr>/base-images/nvidia-astra-base:a1.7.5-c12.1.0-t8.6.1.6

ARG LOCALNET_ARTIFACT_HOST="192.168.0.0"
ARG FFNVCODEC_VERSION="n12.0.16.0"
ARG FFMPEG_VERSION="6.0"
ARG OPENCV_VERSION="4.7.0"
ARG CMAKE_VERSION="3.24.0"
ARG PYTHON_DEPS="Django==4.2.4 numpy==1.24.3 nvidia-ml-py==12.535.77 python-decouple==3.6 pytz==2023.3 requests==2.27.1 torch==2.0.1 zmq==0.0.0"
ARG VIDEOREADER_VERSION="120224-1"

ENV PATH=$PATH:/usr/local/ffmpeg/bin:/usr/cmake-${CMAKE_VERSION}-linux-x86_64/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/ffmpeg/lib:/usr/local/cuda/targets/x86_64-linux/lib/stubs:/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs
ENV PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/ffmpeg/lib/pkgconfig:$PKG_CONFIG_PATH

RUN apt update && apt install git unzip curl xz-utils libva-dev libeigen3-dev -y && apt clean

# Install cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION-linux-x86_64.sh && \
  chmod +x ./cmake-$CMAKE_VERSION-linux-x86_64.sh && \
  ./cmake-$CMAKE_VERSION-linux-x86_64.sh --prefix=/usr --include-subdir --skip-license && \
  rm ./cmake-$CMAKE_VERSION-linux-x86_64.sh

###############################
# FFMpeg build and runtime deps
###############################
RUN apt install nasm libvpx6 libvpx-dev libx264-155 libx264-dev libx265-165 libx265-dev -y && \
  apt clean


#RUN curl -L http://${LOCALNET_ARTIFACT_HOST}/va/ffnvcodec/ffncvodec.tar.xz | tar --xz -xvf - -C /usr/lib
#RUN git clone --depth 1 --branch n12.0.16.0 https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
#    cd nv-codec-headers && make PREFIX=/usr/lib && make PREFIX=/usr install
RUN git clone --depth 1 -b ${FFNVCODEC_VERSION} https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && make PREFIX=/usr install
RUN curl -L http://${LOCALNET_ARTIFACT_HOST}/va/ffnvcodec/ffnvcodec-with-headers_${FFNVCODEC_VERSION}.tar | tar -xvf - -C /usr


###############################
# Compile and install ffmpeg
###############################

# Removed flag --enable-cuvid for testing
RUN git clone -b release/${FFMPEG_VERSION} --single-branch https://github.com/FFmpeg/FFmpeg ffmpeg && \
  cd /ffmpeg && \
  ./configure --enable-nonfree --disable-debug \
        --enable-cuda-nvcc --enable-cuda --enable-cuvid \
        --enable-nvenc --enable-nvdec --enable-libnpp \
        --enable-swresample --enable-libx265 --enable-libx264 --enable-libvpx \
        --enable-gpl --extra-libs=-lpthread \
        --extra-cflags=-I/usr/local/include \
        --extra-cflags=-I/usr/include \
        --extra-cflags=-I/usr/local/cuda/include \
        --extra-ldflags=-L/usr/local/cuda/lib64 \
        --extra-ldflags=-L/usr/lib \
        --disable-static \
        --enable-shared --prefix=/usr/local/ffmpeg && \
  make -j$(nproc) && make install && \
  cd ../ && rm -rf /ffmpeg


###############################
# OpenCV build and runtime deps
###############################

RUN pip3 install --no-cache-dir ${PYTHON_DEPS}

###############################
# Compile and install OpenCV
###############################

WORKDIR /opencv

RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.zip && \
  wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/refs/tags/${OPENCV_VERSION}.zip && \
  unzip ./opencv.zip && unzip ./opencv_contrib.zip && \
  mkdir -pv ./opencv-${OPENCV_VERSION}/build && cd ./opencv-${OPENCV_VERSION}/build && \
  cmake \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local/opencv \
        -D OPENCV_EXTRA_MODULES_PATH=/opencv/opencv_contrib-${OPENCV_VERSION}/modules \
        -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
        -D OPENCV_ENABLE_NONFREE=ON \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_DOCS=OFF \
        -D BUILD_OPENCV_LEGACY=OFF \
        -D BUILD_TESTS=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_PYTHON_SUPPORT=ON \
        -D BUILD_NEW_PYTHON_SUPPORT=ON \
        -D BUILD_OPENCV_PYTHON2=OFF \
        -D BUILD_OPENCV_PYTHON3=ON \
        -D BUILD_opencv_python3=ON \
        -D HAVE_opencv_python3=ON \
        -D PYTHON_DEFAULT_EXECUTABLE=$(which python3) \
        -D PYTHON3_EXECUTABLE=$(which python3) \
        -D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
        -D PYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
        -D PYTHON3_LIBRARY=$(python3 -c "from distutils.sysconfig import get_config_var;from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')),get_config_var('LDLIBRARY')))") \
        -D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") \
        -D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
        -D WITH_CUDA=ON \
        -D CUDA_ARCH_BIN="6.1 7.0 7.5 8.6" \
        -D CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
        -D ENABLE_FAST_MATH=ON \
        -D CUDA_FAST_MATH=ON \
        -D WITH_CUBLAS=ON \
        -D WITH_TBB=ON \
        -D OPENCV_DNN_CUDA=OFF \
        -D WITH_NVCUVID=ON \
        -D VIDEOIO_PLUGIN_LIST=ffmpeg .. && \
        make -j$(nproc) && make install && cd / && rm -rvf /opencv


WORKDIR /

# Install Nvidia VPS
RUN git clone -b master https://github.com/NVIDIA/VideoProcessingFramework.git && \
  cd ./VideoProcessingFramework && pip3 install . --no-cache-dir && cd / && rm -rf /VideoProcessingFramework

# Symlink libcuda.so from installed version of CUDA to so.1 so the pynvcodec wont fail
RUN ln -sf /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so /usr/local/cuda/targets/x86_64-linux/lib/stubs/libcuda.so.1

#ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,video,utility

WORKDIR /code

COPY requirements.txt .

RUN apt update && apt install xz-utils curl tk git -y && apt clean

# Handle broken dependencies

RUN wget https://files.pythonhosted.org/packages/ef/f3/8679dd59e04e7d5e077bd968ddf7904b7e0523680e5576cc802cca029ff6/ganymede_aux-0.5.2-cp310-cp310-manylinux_2_31_x86_64.whl && \
    mv ./ganymede_aux-0.5.2-cp310-cp310-manylinux_2_31_x86_64.whl ./ganymede_aux-0.5.2-py3-none-any.whl && \
    pip3 install --no-cache-dir ./ganymede_aux-0.5.2-py3-none-any.whl

RUN python3 -m pip install --upgrade pip setuptools wheel --no-cache-dir
RUN pip3 install --no-cache-dir -r requirements.txt


# ------------------------------------------------------------------

#COPY . .
