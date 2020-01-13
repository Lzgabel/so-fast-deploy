# 基于openjdk:8
FROM openjdk:8
MAINTAINER lizhi <lz19960321lz@163.com>

# compile 部署脚本传入 service 名称
ARG SERVICE_NAME

# env 会传递到容器中
ENV SERVICE_NAME_ENV ${SERVICE_NAME}

# deploy 部署脚本传入修改
ENV DATE "2020-01-01-11:00:00"

# 启动参数配置, 可通过 deploy 脚本传入进行修改
ENV JAVA_OPTS "-Xms128m -Xmx256m  -XX:-UseGCOverheadLimit -XX:+UseParallelOldGC -XX:+UseParallelGC"

# jar 包名称
ARG JAR_FILE

# jar 包存放目录
WORKDIR /data/backend/${SERVICE_NAME}

# 将当前目录下的 app.war/app.jar 复制到 docker 容器工作目录下
COPY ${JAR_FILE} app.jar

# 新建服务目录 --- 一个 Dockerfile 中只能存在一个 CMD 指令，如果有多个只有最后一个 CMD 指令会执行
CMD mkdir /data/log/${SERVICE_NAME_ENV} -p && \
    java ${JAVA_OPTS} -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/log/${SERVICE_NAME_ENV}/dump-${DATE}.hprof -jar app.jar
