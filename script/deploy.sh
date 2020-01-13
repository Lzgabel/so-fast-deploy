#!/bin/bash
#
################################################################################
#
# $Version:      v2.0
# $Author:       lzgbel
# $Organization: www.lzgabel.cn
# $Create Date:  2020-01-02
# $Description:  后端项目部署脚本
#
################################################################################


# ------ 测试参数 ----
#HOST_LIST="39.106.88.97"
#PORT=1111
#CONTEXT_PATH="/"
#PROMOTED_JOB_NAME="test"
#PROMOTED_NUMBER=1



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


# ------- 环境设置 -------

# Jenkins 传入主机 IP  (eg: "192.168.255.107 192.168.255.108") 默认IP: (localhost)
HOST_LIST=${HOST_LIST:-"localhost"}

# Jenkins 传入服务运行环境, 默认使用 dev 环境
SERVICE_DEPLOY_ENV=${SERVICE_DEPLOY_ENV:-dev}

# Jenkins 传入服务启动端口 默认端口 (8080)
PORT=${PORT:-"8080"}

# Jenkins 传入服务 context path 默认 ("/")
CONTEXT_PATH=${CONTEXT_PATH:-"/"}

# Nexus Docker 镜像仓库地址 [请修改]
DOCKER_HUB=192.168.1.111:8551

# 容器名称，默认为 Jenkins 任务名称
CONTAINER_NAME=${CONTAINER_NAME:-${PROMOTED_JOB_NAME}}

# 镜像名称
IMAGE_NAME=${DOCKER_HUB}/${SERVICE_DEPLOY_ENV}/${PROMOTED_JOB_NAME}:v${PROMOTED_NUMBER}


# 如果容器正在运行，则先停止容器，删除 Docker 容器
function delete_container() {
	# 服务运行容器ID （包括已停止镜像）
	CONTAINER_ID=$(salt $1 cmd.run "docker ps -a --filter=\"name=${CONTAINER_NAME}\" -q"  --out=json | awk 'NR==2 {print $NF}' | sed 's/\"//g' )
  
    echo "CONTAINER_ID: "${CONTAINER_ID}
	if [ x"${CONTAINER_ID}" != x ]; then

        desc "$1: 停止服务中... "

		# salt $1 cmd.run
		salt $1 cmd.run "docker stop ${CONTAINER_ID}"
		# salt $1 cmd.run
	   	salt $1 cmd.run "docker rm -f ${CONTAINER_ID}"

        desc "$1: 服务停止成功！"
	fi
}

# 拉取当前版本镜像
function pull_image() {

	# 镜像ID
	# IMAGE_ID=$(docker images | grep ${IMAGE_NAME} | grep -v grep | awk '{print $3}')
	IMAGE_ID=$(salt $1 cmd.run "docker images -q ${IMAGE_NAME}" --out=json | awk 'NR==2 {print $NF}' | sed 's/\"//g')
    echo "IMAGE_ID: "$IMAGE_ID
	if [ x"${IMAGE_ID}" == x ]; then

        desc "$1: 正在拉取镜像... "

		# 登录 nexus 
		# [username] [password] 请修改
    	salt $1 cmd.run "docker login -u [username] --password [password] ${DOCKER_HUB}"
		# 拉取镜像
		# salt $1 cmd.run
		salt $1 cmd.run "docker pull ${IMAGE_NAME}"

		# 判断镜像是否拉取完成
		image_id=$(salt $1 cmd.run "docker images -q ${IMAGE_NAME}" --out=json | awk 'NR==2 {print $NF}' | sed 's/\"//g')
		echo "image_id: "$image_id
		if [ x"${image_id}" == x ]; then
            desc "$1: 镜像【${IMAGE_NAME}】取失败!!!"
			exit 9
		fi

        desc "$1: 镜像拉取完成！"
	fi
}

# 运行当前容器
function run() {

	for node in ${HOST_LIST};
	do
		# 拉取镜像
		pull_image ${node}

		# 删除正在运行的容器
		delete_container ${node}

		desc "${node}: 正在启动容器..."
		DATE=$(date +"%Y-%m-%d-%T")
		# salt $node cmd.run "docker ....."
		salt $node cmd.run "docker run -d -v /data/log:/data/log -p ${PORT}:${PORT}  -e DATE=${DATE} --name ${CONTAINER_NAME} ${IMAGE_NAME}"

		desc "${node}: 容器启动成功！"
	done
}

# 测试服务状态
function check_service() {
	now=`date +"%Y/%m/%d %T"`
    desc "$now: 测试服务启动状态 ..."
    for node in ${HOST_LIST};
    do
		for n in $(seq 30)
		do
		    sleep 15
		    desc "检查 'http://${node}:${PORT}${CONTEXT_PATH}/hello/world' 状态码"
		    status=`curl --max-time 1 -o /dev/null -s -w %{http_code} http://${node}:${PORT}${CONTEXT_PATH}/hello/world`
		    desc "HTTP 状态码 $status ."

		    if [[ ${status} -eq 200 ]]; then
		    	desc "${node} : 服务【${PROMOTED_JOB_NAME}】部署成功！"
		    	break
			fi

			stop_container_id=$(salt $node cmd.run "docker ps --filter \"status=exited\" | grep ${CONTAINER_NAME} | awk '{print $1}'"  --out=json | awk 'NR==2 {print $NF}' | sed 's/\"//g')

			if [ x"${stop_container_id}" != x ]; then
				desc "${node}：服务【${PROMOTED_JOB_NAME}】 部署失败!!!"
				salt $node cmd.run "docker logs --tail 100 ${stop_container_id}" --out=json | awk 'NR==2 {print $NF}'
				exit 9
			fi
		    #salt $node cmd.run "tail -n 200 ${destination_log_dir}/${prog}/catalina.out"
		done
		if [[ ${status} -eq 200 ]]; then
		    continue
		else
			desc "${node}：服务【${PROMOTED_JOB_NAME}】 部署失败，请查看日志！！！"
			exit 9
		fi
	done
}


run
check_service