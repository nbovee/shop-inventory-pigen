#!/bin/bash
set -e

# Load configuration
APP_ENV_DIR=${APP_ENV_DIR:-/etc/pantry}
source ${APP_ENV_DIR}/config

echo "Setting up firewall rules for captive portal..."

# Flush existing rules
iptables -F
iptables -t nat -F
iptables -X

# Set default policies
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH from eth0 (for remote administration)
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT

# Allow all traffic TO the gateway from wlan0 (captive portal access)
iptables -A INPUT -i wlan0 -d ${AP_GATEWAY_IP} -j ACCEPT

# Allow DNS queries
iptables -A INPUT -i wlan0 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 53 -j ACCEPT

# Allow HTTP/HTTPS to local server
iptables -A INPUT -i wlan0 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 443 -j ACCEPT

# Allow SSH (for remote administration)
iptables -A INPUT -i wlan0 -p tcp --dport 22 -j ACCEPT

# Allow DHCP
iptables -A INPUT -i wlan0 -p udp --dport 67:68 -j ACCEPT

# Block all forwarding from wlan0 to other interfaces (no internet sharing)
iptables -A FORWARD -i wlan0 -j DROP

# Drop any forwarding to wlan0 from other interfaces
iptables -A FORWARD -o wlan0 -j DROP

echo "Firewall rules applied - captive portal is now isolated from internet"
iptables -L -v -n
