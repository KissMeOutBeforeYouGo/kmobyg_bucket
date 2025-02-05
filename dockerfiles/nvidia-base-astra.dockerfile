##########################
# Andrey Fomin <andreyafomin at icloud dot com>
##########################
# This basecontainer provides main cuda 12 and related Nvidia ML libraries on top of ALSE 1.7.5
# It serves as base for both buildcontainers (where things like tritonserver are built) and workcontainers.
# 
# This image uses proprietary software developed and redistributed by Nvidia Corporation and not ment to be
# freely redistributable, since some conponents' licenses (TensorRT GA for example) allow their redistribution strictly as part of
# an application or inside local development environment.
##########################

FROM <redactedcr>/astra:1.7.5


RUN echo "deb https://download.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 main contrib non-free" >> /etc/apt/sources.list && \
    apt update

##########################
# Setup Environment
##########################
# Though these values are used as args, they're not intended
# to be passed as args during 'docker build' unless you know exactly what
# you're doing (and you probably don't, so don't do that).
#
# Changing one component without changing others might result in THIS image successfully building,
# but all others that depend on it may fail catastrophically either at build or at runtime. You've been warned.
##########################

ARG LOCALNET_ARTIFACT_HOST="192.168.0.0:8080"
ARG PYTHON_VERSION="3.10.13"
ARG TENSORRT_VERSION="8.6.1.6"
ARG CUDNN_VERSION="8.8.1.3"
ARG CUDA_VERSION="12.1.0"
ARG CUDA_FULL_REL_TAG="12.1.0_530.30.02"
ARG DCGM_VERSION="3.2.3"
ARG NCCL_VERSION="2.18.3-1"
ARG MINICONDA_VERSION="latest"

# This poor boy from cuda 11 is needed to convert some legacy models for trtexec
ARG CULBAS11_VERSION="11.3.6"

# These 2 ENVs are needed hereinafter. Everything else (including ARG -> ENV)
# is at the bottom.
ENV PATH=$PATH:/usr/local/bin:/usr/local/cuda/bin:/usr/local/cuda/nvvm/bin:/opt/conda/bin
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib:/usr/local/cuda/nvvm/lib:/usr/local/cuda/targets/x86_64-linux/lib

##########################
# Install Dependencies
##########################

# Deps for building Python
RUN apt install wget gcc make build-essential gdb lcov pkg-config \
      libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
      libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev \
      lzma lzma-dev tk-dev uuid-dev zlib1g-dev wget  gcc libxml2 curl xz-utils -y && apt clean

##########################
# Get/Compile/Install Software
##########################
# Note that there was a reason originally for downloading and unpacking archives separately.
# It's ok to change everything to curl -L and then pipe to tar if you so desire.
##########################

# Build and install Python
RUN wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz && \
    tar -xvf ./Python-$PYTHON_VERSION.tgz && \
    cd ./Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations --with-lto --enable-shared --prefix=/usr && \
    make -j$(nproc) && make install && \
    cd ../ && \
    rm -rf ./Python-${PYTHON_VERSION} && rm ./Python-${PYTHON_VERSION}.tgz

# Get and install main CUDA redist
RUN wget https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/cuda_${CUDA_FULL_REL_TAG}_linux.run && \
    chmod +x ./cuda_${CUDA_FULL_REL_TAG}_linux.run && \
    ./cuda_${CUDA_FULL_REL_TAG}_linux.run --toolkit --no-drm --silent && \
    rm ./cuda_${CUDA_FULL_REL_TAG}_linux.run

# Get and install cuBLAS from CUDA 11
RUN curl -L https://developer.download.nvidia.com/compute/cuda/redist/libcublas/linux-x86_64/libcublas-linux-x86_64-11.${CULBAS11_VERSION}-archive.tar.xz | \
    tar --xz -xvf - --strip-components=1 -C /usr

# Get and install cuDNN
RUN wget http://${LOCALNET_ARTIFACT_HOST}/va/cuda/cudnn_${CUDNN_VERSION}.tar.xz && tar -xvf ./cudnn_${CUDNN_VERSION}.tar.xz -C /usr/local && \
    rm ./cudnn_${CUDNN_VERSION}.tar.xz

# Get and install DCGM
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb && \
    apt install ./datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb -y && apt clean && \
    rm ./datacenter-gpu-manager_${DCGM_VERSION}_amd64.deb

# Get and install TensorRT GA
RUN wget http://${LOCALNET_ARTIFACT_HOST}/va/cuda/tensorrt_${TENSORRT_VERSION}.tar.gz && tar -xvf ./tensorrt_${TENSORRT_VERSION}.tar.gz && \
    cp -rv ./TensorRT-${TENSORRT_VERSION}/bin/* /usr/bin && \
    cp -rv ./TensorRT-${TENSORRT_VERSION}/lib/* /usr/lib && \
    cp -rv ./TensorRT-${TENSORRT_VERSION}/include/* /usr/include && \
    cp -rv ./TensorRT-${TENSORRT_VERSION}/targets/x86_64-linux-gnu/bin/* /usr/bin && \
    cp -rv ./TensorRT-${TENSORRT_VERSION}/targets/x86_64-linux-gnu/lib/* /usr/lib && \
    cp -rv ./TensorRT-${TENSORRT_VERSION}/targets/x86_64-linux-gnu/include/* /usr/include && \
    rm -rf ./TensorRT-${TENSORRT_VERSION} && rm ./tensorrt_${TENSORRT_VERSION}.tar.gz

# Get and install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && chmod +x ./Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    ./Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -mbp /opt/conda && \
    rm -rf /opt/conda/lib/cmake && rm ./Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh

# Get and install NCCL
RUN wget http://${LOCALNET_ARTIFACT_HOST}/va/cuda/nccl_${NCCL_VERSION}-x86_64.txz && tar -xvf ./nccl_${NCCL_VERSION}-x86_64.txz -C /usr --strip-component=1 && \
    rm ./nccl_${NCCL_VERSION}-x86_64.txz


##########################
# RUNTIME ENVVARS
##########################
# Most of them are for troubleshooting running container
##########################

ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV TENSORRT_VERSION=${TENSORRT_VERSION}
ENV CUDNN_VERSION=${CUDNN_VERSION}
ENV CUDA_VERSION=${CUDA_VERSION}
ENV CUDA_FULL_REL_TAG=${CUDA_FULL_REL_TAG}
ENV DCGM_VERSION=${DCGM_VERSION}
ENV NCCL_VERSION=${NCCL_VERSION}
ENV MINICONDA_VERSION=${MINICONDA_VERSION}
ENV CULBAS11_VERSION=${CULBAS11_VERSION}