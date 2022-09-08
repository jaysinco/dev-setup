FROM ubuntu:20.04

# docker
# -----------------
# apt-get install -y docker.io
# usermod -aG docker $USER
# printf '{"registry-mirrors":["https://docker.mirrors.ustc.edu.cn/"]}' > /etc/docker/daemon.json
# systemctl daemon-reload && systemctl restart docker

# ssh
# -----------------
# chmod 700 .ssh
# chmod 600 .ssh/id_rsa
# chmod 644 .ssh/id_rsa.pub
# ssh-add

# font
# -----------------
# FiraMono Nerd Font Medium 11
# mv *.ttf ~/.local/share/fonts
# fc-cache -fv

# locale
# -----------------
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y ca-certificates \
    && cp /etc/apt/sources.list /etc/apt/sources.list.bak \
    && printf 'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse\ndeb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse\ndeb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse\ndeb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse\ndeb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse\ndeb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse\n' > /etc/apt/sources.list \
    && apt-get update -y \
    && apt-get install -y apt-utils tzdata language-pack-zh-hans \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# cmake
# -----------------
COPY src/cmake-3.23.1.tar.gz /tmp/

RUN apt-get update -y \
    && apt-get install -y build-essential curl libssl-dev \
    && cd /tmp \
    && tar zxvf cmake-3.23.1.tar.gz \
    && cd /tmp/cmake-3.23.1 \
    && ./bootstrap --prefix=/usr/local --parallel=`nproc` \
    && make -j`nproc` \
    && make install \
    && rm -rf /tmp/cmake-3.23.1 /tmp/cmake-3.23.1.tar.gz

# clang
# -----------------
RUN apt-get update -y \
    && apt-get install -y wget software-properties-common \
    && wget -q -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && add-apt-repository 'deb https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/focal/ llvm-toolchain-focal-13 main' \
    && apt-get update -y \
    && apt-get install -y clang-13 lldb-13 lld-13 clangd-13 clang-format-13 libc++-13-dev libc++abi-13-dev \
    && ln -s /usr/bin/clang-13 /usr/bin/clang \
    && ln -s /usr/bin/clang++-13 /usr/bin/clang++ \
    && ln -s /usr/bin/ld.lld-13 /usr/bin/ld.lld \
    && ln -s /usr/bin/clangd-13 /usr/bin/clangd \
    && ln -s /usr/bin/clang-format-13 /usr/bin/clang-format

# Qt5 build deps
# -----------------
RUN apt-get update -y \
    && apt-get build-dep -y qt5-default

# common utils
# -----------------
RUN apt-get update -y \
    && curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y gdb zip git git-lfs git-gui ninja-build \
        python3 python3-pip nodejs ttf-wqy-microhei

# switch user
# -----------------
RUN apt-get update -y \
    && apt-get install -y sudo \
    && useradd -u 1000 -m jaysinco \
    && usermod -aG sudo jaysinco \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER jaysinco

# install
# -----------------
RUN sudo apt-get update -y \
    && sudo apt-get install -y xclip jq ripgrep \
    && sudo npm install -g typescript-language-server typescript pyright \
    && pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    && pip3 install --no-warn-script-location conan

# copy files
# -----------------
COPY src/nvim-0.7.0-linux-x86_64.tar.gz \
     src/lua-language-server-3.2.5-linux-x64.tar.gz \
     /tmp/
     
RUN cd /tmp \
    && sudo tar zxf nvim-0.7.0-linux-x86_64.tar.gz --directory=/usr --strip-components=1 \
    && mkdir -p /home/jaysinco/apps/lua-language-server \
    && tar zxf lua-language-server-3.2.5-linux-x64.tar.gz --directory=/home/jaysinco/apps/lua-language-server \
    && sudo rm -rf /tmp/*

# config
# -----------------
ENV XDG_RUNTIME_DIR=/tmp/xdg-runtime-root \
    NO_AT_BRIDGE=1 \
    PATH="/home/jaysinco/apps/lua-language-server/bin:/home/jaysinco/.local/bin:${PATH}" \
    LD_LIBRARY_PATH="/home/jaysinco/.conan/data/torch/1.8.2/jaysinco/stable/package/4db1be536558d833e52e862fd84d64d75c2b3656/lib"

RUN mkdir -p /home/jaysinco/.local/share \
    && git config --global user.name jaysinco \
    && git config --global user.email jaysinco@163.com

WORKDIR /home/jaysinco/workspace
ENTRYPOINT ["/bin/bash"]

