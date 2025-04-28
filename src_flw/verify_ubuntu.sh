#!/bin/bash

mkdir doris_dev && cd doris_dev
git clone -b 2.1.6-rc04 ~/git_repo/doris doris/
cd doris/thirdparty
# 提前下载第三方依赖包，或拷贝已下载好的
source vars.sh && bash -x download-thirdparty.sh
# 其他第三方依赖可以提前下载，mvn,nodejs,jdk17,ldb-toolchain,ccache
wget -P tools/ https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/apache-maven-3.6.3-bin.tar.gz
wget -P tools/ https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/node-v12.13.0-linux-x64.tar.gz
wget -P tools/ https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/openjdk-17.0.2_linux-x64_bin.tar.gz
wget -P tools/ https://doris-community-bj-1308700295.cos.ap-beijing.myqcloud.com/tools/ldb_toolchain_gen.sh


# 启动Ubuntu 22.04容器，用于验证Dockerfile
docker run -it -d --name doris_dev -v /data/mvn_repo:/root/.m2/repository -v ./doris:/var/local/doris ubuntu:22.04 /bin/bash
docker exec -it doris_dev bash

# 以下命令在容器内执行

# 配置apt使用阿里云镜像
sed -i 's@//.*archive.ubuntu.com@//mirrors.aliyun.com@g' /etc/apt/sources.list
apt-get update
apt-get install -y curl wget

# 安装基础依赖
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    autoconf automake autopoint binutils-dev bison build-essential byacc bzip2 cmake \
    curl flex file gettext git libiberty-dev libncurses5-dev libncurses-dev libtool libtool-bin \
    make ninja-build openjdk-8-jdk patch pkg-config python2 python3 unzip vim zip

ln -s /usr/bin/python2 /usr/bin/python

# TODO: clang-16 llvm

# 安装 Maven 3.6.3
mkdir -p /usr/share/maven /usr/share/maven/ref
wget -q -O /tmp/apache-maven.tar.gz https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/apache-maven-3.6.3-bin.tar.gz
tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1
rm -f /tmp/apache-maven.tar.gz
ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# 安装 NodeJS
wget https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/node-v12.13.0-linux-x64.tar.gz \
    -q -O /tmp/node-v12.13.0-linux-x64.tar.gz
cd /tmp/ && tar -xf node-v12.13.0-linux-x64.tar.gz
cp -r node-v12.13.0-linux-x64/* /usr/local/
rm /tmp/node-v12.13.0-linux-x64.tar.gz && rm -rf node-v12.13.0-linux-x64

# 安装 JDK17
wget https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/openjdk-17.0.2_linux-x64_bin.tar.gz \
    -q -O /tmp/openjdk-17.0.2_linux-x64_bin.tar.gz
cd /tmp && tar -xzf openjdk-17.0.2_linux-x64_bin.tar.gz
cp -r jdk-17.0.2/ /usr/lib/jvm/
rm /tmp/openjdk-17.0.2_linux-x64_bin.tar.gz && rm -rf /tmp/jdk-17.0.2/

# 安装 ldb-toolchain
rm -rf /var/local/ldb-toolchain/
rm -f /tmp/ldb_toolchain_gen.sh
wget https://doris-community-bj-1308700295.cos.ap-beijing.myqcloud.com/tools/ldb_toolchain_gen.sh \
    -q -O /tmp/ldb_toolchain_gen.sh
chmod +x /tmp/ldb_toolchain_gen.sh
bash /tmp/ldb_toolchain_gen.sh /var/local/ldb-toolchain/
rm /tmp/ldb_toolchain_gen.sh

# 设置环境变量
export REPOSITORY_URL="https://doris-thirdparty-hk-1308700295.cos.ap-hongkong.myqcloud.com/thirdparty"
export DEFAULT_DIR="/var/local"
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
export PATH="/var/local/ldb-toolchain/bin/:$PATH"

apt-get install -y ca-certificates && update-ca-certificates

# 安装 ccache
wget https://doris-community-bj-1308700295.cos.ap-beijing.myqcloud.com/tools/ccache-4.8.tar.gz \
    -q -O /tmp/ccache-4.8.tar.gz
cd /tmp/ && tar xzf ccache-4.8.tar.gz
cd ccache-4.8
cmake -B _build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=/var/local/ldb-toolchain/bin/clang -DCMAKE_CXX_COMPILER=/var/local/ldb-toolchain/bin/clang++ .
cmake --build _build --config Release -j 4
cp _build/ccache /var/local/ldb-toolchain/bin/

# 禁用自动启用ccache并解决curl证书验证位置错误
rm -f /etc/profile.d/ccache.*
cp /etc/pki/tls/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt 2>/dev/null || true

cd /var/local/doris
/bin/bash -x thirdparty/build-thirdparty.sh
# -j 8 # 指定并行度，默认$(($(nproc) / 4 + 1))
# --continue <package> # 指定从某个包开始继续构建


THIRDPARTY_INSTALLED=/var/local/doris/thirdparty/installed/
mvn clean package -Pnative,dist -DskipTests -Dmaven.javadoc.skip -f hadoop-hdfs-project \
-Dthirdparty.installed="${THIRDPARTY_INSTALLED}" -Dopenssl.prefix="${THIRDPARTY_INSTALLED}" -e