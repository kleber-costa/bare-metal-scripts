#!/bin/bash

echo -e "\nYou must run this script with root user..."
echo -e "\nCheck prometheus version: https://prometheus.io/download/"

echo -e "\nPrometheus version path: \nExample: v2.41.0"
read prometheus_dir

echo -e "\nPrometheus artifactory: \nExample: prometheus-2.41.0.linux-amd64"
read prometheus_version

prometheus_service='/etc/systemd/system/prometheus.service'

echo -e "\nStart ${prometheus_version} download...\n"
wget https://github.com/prometheus/prometheus/releases/download/${prometheus_dir}/${prometheus_version}.tar.gz

if [ -f "${prometheus_version}".tar.gz ] ; then

    echo -e "\nConfiguring prometheus user and service...\n"
    
    useradd --no-create-home --shell /bin/false prometheus
    tar xf ${prometheus_version}.tar.gz
    mkdir -p /etc/prometheus
    mkdir -p /var/lib/prometheus
    cp ${prometheus_version}/prometheus /usr/local/bin/
    chown prometheus: /usr/local/bin/prometheus
    cp ${prometheus_version}/promtool /usr/local/bin/
    chown prometheus: /usr/local/bin/promtool
    cp -a ${prometheus_version}/consoles /etc/prometheus/
    cp -a ${prometheus_version}/console_libraries /etc/prometheus/
    cp -a ${prometheus_version}/prometheus.yml /etc/prometheus/prometheus.yml
    chown prometheus: -R /etc/prometheus
    rm -rf ${prometheus_version}*
fi

echo -e "\nConfiguring prometheus systemd unit service\n"

if [ $? == 0 ] ; then

cat << EOF > "$prometheus_service"
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
[Install]
WantedBy=multi-user.target
EOF

fi

echo -e "\nConfiguring prometheus service startup\n"

if [ -f "$prometheus_service" ] ; then
    systemctl daemon-reload
    systemctl start prometheus.service
    if [ $? == 0 ] ; then 
        systemctl enable prometheus.service
        systemctl status prometheus.service
    fi
fi
