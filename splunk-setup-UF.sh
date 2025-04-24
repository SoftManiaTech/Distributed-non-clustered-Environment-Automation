#!/bin/bash

# Become root user (if not already root)
if [ $(id -u) -ne 0 ]; then
    echo "Switching to root user..."
    sudo su
fi

# Create user & group if not already present
id -u splunk &>/dev/null || useradd splunk
id -g splunk &>/dev/null || groupadd splunk

# Create directory for Splunk Universal Forwarder
mkdir -p /opt/splunkforwarder
chown -R splunk:splunk /opt/splunkforwarder/

# Verify the ownership of the directory (optional)
ll /opt/splunkforwarder

# Install wget
yum install -y wget

#Splunk Universal Forwarder Installation

# Switch to splunk user
su - splunk <<'EOF'
cd /home/splunk

wget -O splunkforwarder-9.4.1.tgz "https://download.splunk.com/products/universalforwarder/releases/9.4.1/linux/splunkforwarder-9.4.1-e3bdab203ac8-linux-amd64.tgz"
tar -xvf splunkforwarder-9.4.1.tgz -C /opt/

cd /opt/splunkforwarder/bin

./splunk start --accept-license --no-prompt --answer-yes --seed-passwd admin123
EOF

exit

# Enable boot-start for Splunk Universal Forwarder
/opt/splunkforwarder/bin/splunk stop
/opt/splunkforwarder/bin/splunk enable boot-start -user splunk
/opt/splunkforwarder/bin/splunk start
