#!/bin/bash
#
################################################################################
#
# $Name:         build.sh
# $Version:      v2.0
# $Author:       lzgabel
# $Organization: www.lzgabel.cn
# $Create Date:  2020-01-06
# $Description:  项目构建，镜像打包脚本
#
################################################################################


# '=' 输出个数
LEN=100
function separator(){
for ((i=1;i<=${LEN};i++))
    do
        echo -n "="
    done
        echo -e
}

# desc
function desc(){
    len=${#1}
    space=`expr $((${LEN}-${len})) / 2`
    separator
    printf "%-${space}s" "" 
    echo -n ${1}
    echo -e
    separator
}


# Nexus Docker 镜像仓库地址 [镜像仓库，请替换]
DOCKER_HUB=192.168.1.1:8551

# Jenkins 传入服务运行环境, 默认使用 dev 环境
SERVICE_DEPLOY_ENV=${SERVICE_DEPLOY_ENV:-dev}

# Jenkins 传入部署服务名称， 默认使用 Jenkins 任务名称
SERVICE_NAME=${SERVICE_NAME:-${JOB_NAME}}

# Jenkins 传入 jar 包名称
JAR_NAME=${JAR_NAME}

# docker file Dockerfile 存储路径 [根据需求自定义]
DOCKER_FILE="${JENKINS_HOME}/workspace/${JOB_NAME}/src/main/resources/Dockerfile"

# jar 所在目录
SOURCE_DIR="${JENKINS_HOME}/workspace/${JOB_NAME}/target/"

# 镜像名称
IMAGE_NAME=${DOCKER_HUB}/${SERVICE_DEPLOY_ENV}/${JOB_NAME}:v${BUILD_NUMBER}

# 构建镜像
function build_image() {

    desc "构建镜像中..."

    docker build -t ${IMAGE_NAME} --build-arg JAR_FILE=${JAR_NAME} --build-arg SERVICE_NAME=${SERVICE_NAME} -f ${DOCKER_FILE} ${SOURCE_DIR}

    desc "镜像构建成功！"
}

# 上传镜像
function push_image() {

    desc "镜像上传中..."

    # 登录 nexus 
    # [username] [password] [请替换]
    docker login -u [username] --password [password] ${DOCKER_HUB}
    # 上传镜像
    docker push ${IMAGE_NAME}

    desc "镜像上传成功！"
}

build_image
# -- 测试环境，临时注释 --
#push_image
