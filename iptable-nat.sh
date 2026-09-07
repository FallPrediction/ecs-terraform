#!/bin/bash

yum install iptables-services -y
systemctl enable iptables
systemctl start iptables

cat <<'EOF' >/etc/sysctl.d/custom-ip-forwarding.conf
net.ipv4.ip_forward=1
EOF

sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf

interface_name=$(ip route show | grep 'default' | xargs | cut -d ' ' -f 5)

/sbin/iptables -t nat -A POSTROUTING -o ${interface_name} -j MASQUERADE
/sbin/iptables -F FORWARD
service iptables save
