#!/bin/bash

echo -e "\nYou must run this script with root user..."
echo -e "\nCheck Node Exporter version: https://node_exporter.io/download/#node_exporter"

echo -e "\nNode Exporter version path: \nExample: v1.5.0"
read node_exporter_dir

echo -e "\nNode Exporter artifactory: \nExample: node_exporter-1.5.0.linux-amd64"
read node_exporter_version

node_exporter_service='/etc/systemd/system/node_exporter.service'
prometheus_config='/etc/prometheus/prometheus.yml'

echo -e "\nStart ${node_exporter_version} download...\n"
wget https://github.com/prometheus/node_exporter/releases/download/${node_exporter_dir}/${node_exporter_version}.tar.gz

if [ -f "${node_exporter_version}".tar.gz ] ; then

    echo -e "\nConfiguring node_exporter user and service...\n"
    
    useradd --no-create-home --shell /bin/false node_exporter
    tar xf ${node_exporter_version}.tar.gz
    cp ${node_exporter_version}/node_exporter /usr/local/bin/
    chown node_exporter: /usr/local/bin/node_exporter
    rm -rf "${node_exporter_version}"*
fi

echo -e "\nConfiguring node_exporter systemd unit service\n"

if [ $? == 0 ] ; then

cat << EOF > "$node_exporter_service"
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOF

fi

if [ -f "$prometheus_config" ] ; then
    echo -e "\nConfiguring local prometheus scrape...\n"
    cat prometheus.yml >> "$prometheus_config"
    systemctl daemon-reload
    systemctl restart prometheus.service
fi

echo -e "\nConfiguring node_exporter service startup\n"

if [ -f "$node_exporter_service" ] ; then
    systemctl daemon-reload
    systemctl start node_exporter.service
    if [ $? == 0 ] ; then 
        systemctl enable node_exporter.service
    fi
fi
