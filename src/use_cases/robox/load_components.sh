#!/bin/bash

ROBOX_DIR=/usr/share/local/robox
function download_and_install()
{
    if [ ! -e ${ROBOX_DIR}/$1 ]; then
        sudo wget -p ${ROBOX_DIR} https://github.com/ysemi-computing/RoboxWidget/blob/main/components/$1
    fi
    sudo cp ${ROBOX_DIR}/$1  /usr/bin/
    sudo chmod -f 777 /usr/bin/$1
}

if [ "$(arch)" = "x86_64" ]; then
    echo "components only support on arch arm64"
    exit
fi

sudo mkdir -p ${ROBOX_DIR}
which node_exporter
if [ $? -ne 0 ]; then
    echo "node_exporter not found, downloading !!!!"
    download_and_install node_exporter
fi

which perf_exporter
if [ $? -ne 0 ]; then
    echo "perf_exporter not found, downloading !!!!"
    download_and_install perf_exporter
fi

which prometheus
if [ $? -ne 0 ]; then
    echo "prometheus not found, downloading !!!!"
    download_and_install prometheus
fi

which grafana-server
if [ $? -ne 0 ]; then
    echo "grafana not found, downloading !!!!"
    download_and_install grafana-server
fi

# update configuration file
if [ ! -e ${ROBOX_DIR}/ys_perf_exporter ]; then
    sudo wget -P ${ROBOX_DIR} https://github.com/ysemi-computing/RoboxWidget/blob/main/config/ys_perf_exporter.yml
fi
sudo cp -f ${ROBOX_DIR}/ys_perf_exporter /etc/perf_exporter

if [ ! -e ${ROBOX_DIR}/ys_prometheus.yml ]; then
    sudo wget -P ${ROBOX_DIR} https://github.com/ysemi-computing/RoboxWidget/blob/main/config/ys_prometheus.yml
fi

# start basic components
echo "starting node_exporter"
ps aux | grep -v grep | grep node_exporter
if [ $? -ne 0 ]; then
    sudo node_exporter &
fi

echo "starting perf_exporter"
ps aux | grep -v grep | grep perf_exporter
if [ $? -ne 0 ]; then
    sudo perf_exporter &
fi

echo "starting prometheus"
ps aux | grep -v grep | grep prometheus
if [ $? -ne 0 ]; then
    sudo prometheus --config.file=${ROBOX_DIR}/ys_prometheus.yml &
fi

echo "starting grafana-server"
ps aux | grep -v grep | grep grafana-server
if [ $? -ne 0 ]; then
    sudo grafana-server &
fi

