# Source Code Compile




官方推荐的方式有报错 [使用 Docker 开发镜像编译（推荐）](https://doris.apache.org/zh-CN/community/source-install/compilation-with-docker)

参考`docker\README.md`打镜像用于编译，如有问题调整Dockerfile



### Ubuntu
```sh
WORK_DIR=$(pwd -P)/doris_ubuntu
mkdir -p $WORK_DIR && cd $WORK_DIR
git clone -b 2.1.6-rc04 ~/git_repo/doris doris/
cd $WORK_DIR/doris/thirdparty
# 提前下载第三方依赖包，或拷贝已下载好的
# cp -r /data/doris/thirdparty_doris-2.1.6 $WORK_DIR/doris/thirdparty/src
source vars.sh && bash -x download-thirdparty.sh
# 其他第三方依赖可以提前下载，mvn,nodejs,jdk17,ldb-toolchain,ccache
wget -P tools/ https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/apache-maven-3.6.3-bin.tar.gz
wget -P tools/ https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/node-v12.13.0-linux-x64.tar.gz
wget -P tools/ https://doris-thirdparty-1308700295.cos.ap-beijing.myqcloud.com/tools/openjdk-17.0.2_linux-x64_bin.tar.gz
wget -P tools/ https://doris-community-bj-1308700295.cos.ap-beijing.myqcloud.com/tools/ldb_toolchain_gen.sh

docker build -t doris_dev-ubuntu2204:2.1.6-rc04 .

git submodule update --init --recursive be/src/clucene
git submodule update --init --recursive be/src/be/src/apache-orc

docker run -it \
--name doris_build \
-v /data/mvn_repo/:/root/.m2/repository \
-v ./doris/:/root/doris-2.1.6-rc04/ \
doris_dev-ubuntu2204:2.1.6-rc04



git config --global --add safe.directory /root/doris-2.1.6-rc04



cd /root/doris-2.1.6-rc04
# 启动容器前做好clucene和apache-orc的git submodule update
sed -i "s#update_submodule\s#\# update_submodule #g" build.sh
nohup bash -x build.sh >> build.log 2>& 1 &


cd $WORK_DIR
wget -O Dockerfile https://github.com/tiakx1003/doris/docker/Dockerfile.ubuntu22.04
# build过程会调用mvn，挂载宿主机repository到临时容器
docker build \
    --mount type=bind,source=/data/mvn_repo,target=/root/.m2/repository \
    -t doris_dev-ubuntu2204:2.1.6-rc04 .
    
docker build -v /data/mvn_repo:/root/.m2/repository -t doris_dev-ubuntu2204:2.1.6-rc04 .




DOCKER_BUILDKIT=1 
docker build --mount=type=bind,source=/data/mvn_repo,target=/root/.m2/repository -t doris_dev-ubuntu2204:2.1.6-rc04 .
```







```sh

mkdir doris_centos && cd doris_centos
git clone -b 2.1.6-rc04 ~/git_repo/doris doris/
cd doris/thirdparty
# 提前下载第三方依赖包，或拷贝已下载好的
source vars.sh && bash -x download-thirdparty.sh


cp doris/docker/compilation/Dockerfile ./




docker build -t doris_dev-centos7:2.1.6-rc04 .


docker run -it -v ~/.m2:/root/.m2 -v ./doris-2.1.6-rc04-src/:/root/doris-2.1.6-rc04-src/ doris_dev-ubuntu2204:2.1.6-rc04
bash -x build.sh

docker run -it -d -v /data/mvn_repo:/root/.m2 -v ./doris:/var/local/doris --name doris_centos centos:7 bash
```