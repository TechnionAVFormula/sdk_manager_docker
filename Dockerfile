FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04

# ARGUMENTS
ARG USERNAME=jetpack
ARG SDK_MANAGER_VERSION=1.1.0-6343
ARG SDK_MANAGER_DEB=sdkmanager_${SDK_MANAGER_VERSION}_amd64.deb
ARG DRIVEWORKS_VERSION=2.2
ARG PROTOBUF_VERSION=3.8.0
ARG SPDLOG_VERSION=1.6.1
ARG CMAKE_VERSION=3.16.4
ARG MONGO_C_DRIVER_VERSION=1.16.2
ARG MONGO_CXX_DRIVER_VERSION=3.5.0
ARG ZSTD_VERSION=1.4.5

# add new sudo user
ENV USERNAME jetpack
ENV HOME /home/$USERNAME
RUN useradd -m $USERNAME && \
        echo "$USERNAME:$USERNAME" | chpasswd && \
        usermod --shell /bin/bash $USERNAME && \
        usermod -aG sudo $USERNAME && \
        mkdir /etc/sudoers.d && \
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
        chmod 0440 /etc/sudoers.d/$USERNAME && \
        # Replace 1000 with your user/group id
        usermod  --uid 1000 $USERNAME && \
        groupmod --gid 1000 $USERNAME

# install package
RUN yes | unminimize && \
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        curl \
        git \
        gpg \
        gpg-agent \
        gpgconf \
        gpgv \
        less \
        libcanberra-gtk-module \
        libcanberra-gtk3-module \
        libgconf-2-4 \
        libgtk-3-0 \
        libnss3 \
        libx11-xcb1 \
        libxss1 \
        libxtst6 \
        net-tools \
        python3-pip \
        sshpass \
        libssl-dev \
        swig \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# set locale
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# install SDK Manager
USER jetpack
COPY ${SDK_MANAGER_DEB} /home/${USERNAME}/
WORKDIR /home/${USERNAME}
RUN sudo apt-get install -f /home/${USERNAME}/${SDK_MANAGER_DEB}

USER root
RUN echo "${USERNAME}:${USERNAME}" | chpasswd
RUN rm /home/${USERNAME}/${SDK_MANAGER_DEB}

# Create links
RUN ln -s /usr/local/driveworks-${DRIVEWORKS_VERSION} /usr/local/driveworks

# Install Cmake

USER jetpack
ADD --chown=jetpack:jetpack https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz  /home/${USERNAME}/
WORKDIR /home/${USERNAME}
RUN tar -xf /home/${USERNAME}/cmake-${CMAKE_VERSION}.tar.gz
WORKDIR /home/${USERNAME}/cmake-${CMAKE_VERSION}
RUN /home/${USERNAME}/cmake-${CMAKE_VERSION}/configure
RUN make
RUN sudo make install

WORKDIR /home/${USERNAME}
RUN sudo rm -rf /home/${USERNAME}/cmake-${CMAKE_VERSION}
RUN rm /home/${USERNAME}/cmake-${CMAKE_VERSION}.tar.gz

# Install protobuf
USER jetpack
ADD --chown=jetpack:jetpack https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-all-${PROTOBUF_VERSION}.tar.gz /home/${USERNAME}/
WORKDIR /home/${USERNAME}
RUN tar -xf /home/${USERNAME}/protobuf-all-${PROTOBUF_VERSION}.tar.gz
WORKDIR /home/${USERNAME}/protobuf-${PROTOBUF_VERSION}
RUN /home/${USERNAME}/protobuf-${PROTOBUF_VERSION}/configure
RUN make
RUN sudo make install
RUN sudo ldconfig

WORKDIR /home/${USERNAME}
RUN sudo rm -rf /home/${USERNAME}/protobuf-${PROTOBUF_VERSION}
RUN rm /home/${USERNAME}/protobuf-all-${PROTOBUF_VERSION}.tar.gz

RUN pip3 install protobuf

# Install spdlog
USER jetpack
ADD --chown=jetpack:jetpack https://github.com/gabime/spdlog/archive/v${SPDLOG_VERSION}.tar.gz  /home/${USERNAME}/spdlog-${SPDLOG_VERSION}.tar.gz
WORKDIR /home/${USERNAME}
RUN tar -xf /home/${USERNAME}/spdlog-${SPDLOG_VERSION}.tar.gz
RUN mkdir /home/${USERNAME}/spdlog-${SPDLOG_VERSION}/_build
WORKDIR /home/${USERNAME}/spdlog-${SPDLOG_VERSION}/_build
RUN cmake ..
RUN make
RUN sudo make install

WORKDIR /home/${USERNAME}
RUN sudo rm -rf /home/${USERNAME}/spdlog-${SPDLOG_VERSION}
RUN rm /home/${USERNAME}/spdlog-${SPDLOG_VERSION}.tar.gz

# Install ZSTD
USER jetpack
ADD --chown=jetpack:jetpack https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz  /home/${USERNAME}/
WORKDIR /home/${USERNAME}
RUN tar -xf /home/${USERNAME}/zstd-${ZSTD_VERSION}.tar.gz
RUN mkdir /home/${USERNAME}/zstd-${ZSTD_VERSION}/build/cmake/_build
WORKDIR /home/${USERNAME}/zstd-${ZSTD_VERSION}/build/cmake/_build
RUN cmake ..
RUN make
RUN sudo make install

WORKDIR /home/${USERNAME}
RUN sudo rm -rf /home/${USERNAME}/zstd-${ZSTD_VERSION}
RUN rm /home/${USERNAME}/zstd-${ZSTD_VERSION}.tar.gz

# Install MongoDB

## Instal mongo c driver
USER jetpack
ADD --chown=jetpack:jetpack https://github.com/mongodb/mongo-c-driver/releases/download/${MONGO_C_DRIVER_VERSION}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}.tar.gz  /home/${USERNAME}/
WORKDIR /home/${USERNAME}
RUN tar -xf /home/${USERNAME}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}.tar.gz
RUN mkdir /home/${USERNAME}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}/_build
WORKDIR /home/${USERNAME}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}/_build
RUN cmake .. -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF
RUN make
RUN sudo make install

WORKDIR /home/${USERNAME}
RUN sudo rm -rf /home/${USERNAME}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}
RUN rm /home/${USERNAME}/mongo-c-driver-${MONGO_C_DRIVER_VERSION}.tar.gz

## Instal mongo cxx driver
USER jetpack
ADD --chown=jetpack:jetpack https://github.com/mongodb/mongo-cxx-driver/releases/download/r${MONGO_CXX_DRIVER_VERSION}/mongo-cxx-driver-r${MONGO_CXX_DRIVER_VERSION}.tar.gz  /home/${USERNAME}/
WORKDIR /home/${USERNAME}
RUN tar -xf /home/${USERNAME}/mongo-cxx-driver-r${MONGO_CXX_DRIVER_VERSION}.tar.gz
RUN mkdir /home/${USERNAME}/mongo-cxx-driver-r${MONGO_CXX_DRIVER_VERSION}/_build
WORKDIR /home/${USERNAME}/mongo-cxx-driver-r${MONGO_CXX_DRIVER_VERSION}/_build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_AND_STATIC_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr/local
RUN sudo make EP_mnmlstc_core
RUN make
RUN sudo make install

WORKDIR /home/${USERNAME}
RUN sudo rm -rf /home/${USERNAME}/mongo-cxx-driver-r${MONGO_CXX_DRIVER_VERSION}
RUN rm /home/${USERNAME}/mongo-cxx-driver-r${MONGO_CXX_DRIVER_VERSION}.tar.gz
