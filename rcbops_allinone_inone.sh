#!/usr/bin/env bash
# Set Verbose
set -v

# Set Exit on error
set -e

# make sure variables are set
set -u

# Copyright [2013] [Kevin Carter]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# This script will install/configure several bits
# ============================================================================
# Openstack Controller
# Openstack Compute
# Horizon
# Cinder is built on a loop file unless you specify a device
# Nova-Network is used
# Quantum is NOT being used by Default
# Package Installation of Openstack for Ubuntu 12.04 LTS or CentOS6(RHEL6)
# cirros Image
# fedora Image
# Qemu is the default Virt Driver
# The Latest Stable Chef Server
# Chef Client
# Knife


# Here are the script Override Values.
# Any of these override variables can be exported as environment variables.
# ============================================================================
# Disable roll back on Failure (NOTICE LETTER CASE)
# DISABLE_ROLL_BACK=true || false

# Set this to override the RCBOPS Developer Mode, DEFAULT is False
# DEVELOPER_MODE=True || False

# Set this to allow the cook to do package upgrades
# DO_PACKAGE_UPGRADES=True || False

# Set this to override the chef default password, DEFAULT is "Random Things"
# CHEF_PW=""

# Set this to override the RabbitMQ Password, DEFAULT is "Random Things"
# RMQ_PW=""

# Set this to override the RabbitMQ Address, DEFAULT is "127.0.0.1"
# RMQ_ADDR=""

# Set this to override the Openstack Admin Pass, DEFAULT is "Random Things"
# NOVA_PW=""

# Set this to override the system users Password, DEFAULT is the NOVA_PW
# SYSTEM_PW=""

# Set this to override the Cookbook version, DEFAULT is "v4.1.2"
# COOKBOOK_VERSION=""

# Set this to override the Management Interface, DEFAULT is "eth0"
# MANAGEMENT_INTERFACE=""

# Set this to override the Nova Interface, DEFAULT is "eth0"
# NOVA_INTERFACE=""

# Set this to override the Public Interface, DEFAULT is "eth0"
# PUBLIC_INTERFACE=""

# Set this to override the Virt Type, DEFAULT is "qemu"
# VIRT_TYPE=""

# Set this to override the Cinder Device, DEFAULT is "/opt/cinder.img"
# CINDER=""

# Set this to set the Neutron Interface, Only Set if you want to use Neutron
# ================== NOTE NEUTRON MAY NOT WORK RIGHT NOW ===================
# Enale || Disable Neutron
# NEUTRON_ENABLED=False

# Set the Interface for Neutron
# NEUTRON_INTERFACE=""

# Set the name of the Service
# NEUTRON_NAME="neutron"
# ==========================================================================

# Chef Server Override for Package URL
# CHEF_SERVER_PACKAGE_URL=""

# Override the runlist with something different
# RUN_LIST=""

# ==========================================================================
# Default Images True||False, DEFAULT is False
# FEDORA_IMAGE=False

# UBUNTU_IMAGE=False

# CIRROS_IMAGE=False

# ==========================================================================
# If not set, the script will attempt to determine the cidr of the interface
# or 127.0.0.0/24 will be used. Setting these override the interface variables.
# MANAGEMENT_INTERFACE_CIDR="Custom Cidr"

# NOVA_INTERFACE_CIDR="Custom Cidr"

# PUBLIC_INTERFACE_CIDR="Custom Cidr"

# ==========================================================================
# This is used for Testing Cookbooks. If you want to use a non-stock cookbook
# you can specify them in this variable. The format is "name=branch=url"
# This is a space seperated list.
# TESTING_COOKBOOKS="name=branch=url"


# Package Removal
# ==========================================================================
function remove_apt_packages() {
  # Remove known Packages
  for package in ${GENERAL_PACKAGES};do
    for known_package in $(dpkg -l | grep -i ${package} | awk '{print $2}'); do
      if [ "${known_package}" ];then
        apt-get -y remove ${known_package}
        apt-get -y purge ${known_package}
      fi
    done
  done

  # Search for Openstack Packages
  for os_package in $(dpkg -l | grep -i openstack | awk '{print $2}'); do
    if [ "${os_package}" ];then
      apt-get -y remove ${os_package}
      apt-get -y purge ${os_package}
    fi
  done

  # Remove all packages which are no longer needed
  apt-get -y autoremove

}

function remove_rpm_packages() {
  # Remove known Packages
  for package in ${GENERAL_PACKAGES};do
    for known_package in $(rpm -qa | grep -i ${package}); do
      if [ "${known_package}" ];then
        yum -y remove ${known_package}
      fi
    done
  done

  # Search for Openstack Packages
  for os_package in $(rpm -qa | grep -i openstack); do
    if [ "${os_package}" ];then
      yum -y remove ${os_package}
    fi
  done

  # Remove all packages which are no longer being used
  EXTRA_PACKAGES=$(package-cleanup --quiet --leaves --exclude-bin)
  for extra_package in ${EXTRA_PACKAGES};do
    if [ "${extra_package}" ];then
      yum remove -y ${extra_package}
    fi
  done

  # Restore IPTables if set
  if [ -f "/etc/iptables.original" ];then
    if [ "${IPTABLES_RESTORE}" ];then
      ${IPTABLES_RESTORE} < /etc/iptables.original
      service iptables save
    fi
  fi

}


# Error Handler
# ==========================================================================
function error_message() {
  # Print Messages
  echo "ERROR ON LINE: ${1}, MESSAGE ${2}, ALL KNOWN DATA ${@}"
  exit 1

}

function error_exit() {
  if ${DISABLE_ROLL_BACK};then
    echo "NO ROLL BACK BEING DONE!"
    error_message $@
  else
    set +e
    set +u
    set +v

    # Remove Packages
    echo "Removing Known Files and Folders."
    ${REMOVE_SYSTEM_PACKAGES}

    # Cleanup all the things
    service_stop
    cinder_device_remove
    file_cleanup
    directory_cleanup
    error_message $@
  fi

}


function file_cleanup() {
  echo "Performing File Cleanup"

  [ -f "/tmp/chef_server.deb" ] && rm /tmp/chef_server.deb
  [ -f "/opt/cinder.img" ] && rm /opt/cinder.img
  [ -f "/root/.ssh/id_rsa.pub" ] && rm /root/.ssh/id_rsa.pub
  [ -f "/root/.ssh/id_rsa" ] && rm /root/.ssh/id_rsa
  [ -f "/root/.my.cnf" ] && rm /root/.my.cnf
  [ -f "/root/openrc" ] && rm /root/openrc
  [ -f "/etc/yum.repos.d/epel.repo" ] && rm /etc/yum.repos.d/epel.repo
  [ -f "/etc/yum.repos.d/epel-testing.repo" ] && rm /etc/yum.repos.d/epel-testing.repo
  [ -f "/etc/yum.repos.d/remi.repo" ] && rm /etc/yum.repos.d/remi.repo
  [ -f "/etc/my.cnf.rpmsave" ] && rm /etc/my.cnf.rpmsave
  [ -f "/etc/mysql_grants.sql" ] && rm /etc/mysql_grants.sql
  [ -f "/etc/init/chef-server-runsvdir.conf" ] && rm /etc/init/chef-server-runsvdir.conf
  [ -f "/tmp/epel-release-6-8.noarch.rpm" ] && rm /tmp/epel-release-6-8.noarch.rpm
  [ -f "/tmp/rabbitmq.rpm" ] && rm /tmp/rabbitmq.rpm
  [ -f "/tmp/rabbitmq.asc" ] && rm /tmp/rabbitmq.asc
  [ -f "/tmp/remi-release-6.rpm" ] && rm /tmp/remi-release-6.rpm
  [ -f "/tmp/mods.txt" ] && rm /tmp/mods.txt
  [ -f "/var/log/mysqld.log.rpmsave" ] && rm /var/log/mysqld.log.rpmsave

  # Remove ALL temp files
  for temp_file in $(ls /tmp/);do
    rm -rf /tmp/${temp_file}
  done

}


function directory_cleanup() {
  echo "Performing Directory Cleanup"

  [ -d "/tmp/opt/chef-server" ] && rm -rf /tmp/opt/chef-server
  [ -d "/opt/allinoneinone/" ] && rm -rf /opt/allinoneinone/
  [ -d "/opt/aioio-installed.lock" ] && rm /opt/aioio-installed.lock
  [ -d "/opt/chef-server" ] && rm -rf /opt/chef-server
  [ -d "/opt/chef" ] && rm -rf /opt/chef
  [ -d "/root/.chef" ] && rm -rf /root/.chef
  [ -d "/etc/chef" ] && rm -rf /etc/chef
  [ -d "/etc/rabbitmq" ] && rm -rf /etc/rabbitmq
  [ -d "/etc/chef-server" ] && rm -rf /etc/chef-server
  [ -d "/etc/mysql" ] && rm -rf /etc/mysql
  [ -d "/usr/lib/rabbitmq" ] && rm -rf /usr/lib/rabbitmq
  [ -d "/var/chef" ] && rm -rf /var/chef
  [ -d "/var/opt/chef-server" ] && rm -rf /var/opt/chef-server
  [ -d "/var/lib/rabbitmq/" ] && rm -rf /var/lib/rabbitmq/
  [ -d "/var/lib/mysql/" ] && rm -rf /var/lib/mysql/
  [ -d "/var/log/chef-server" ] && rm -rf /var/log/chef-server
  [ -d "/var/log/mysql" ] && rm -rf /var/log/mysql
  [ -d "/var/log/rabbitmq" ] && rm -rf /var/log/rabbitmq

}


function cinder_device_remove() {
  # Remove any loopback devices setup
  for loopback_dev in $(losetup -a | awk -F':' '{print $1}');do
    if [ "${loopback_dev}" ];then
      losetup -d ${loopback_dev}
    fi
  done

}

function service_stop() {
  # general Services
  SERVICES="rabbitmq nginx chef-server-webui erchef bookshelf chef apache mysql httpd libvirt "
  # Openstack Services
  SERVICES+=${OPENSTACK_SERVICES}

  # Stop Service
  for service in ${SERVICES}; do
    for pid in $(ps auxf | grep -i ${service} | grep -v grep | awk '{print $2}'); do
      if [ "${pid}" ];then
        if [ "$(ps auxf | grep ${pid} | grep -v grep | awk '{print $2}')" ];then
          kill ${pid}
        fi
      fi
    done
  done

}


# Package Install
# ==========================================================================
function install_apt_packages() {
  # Install RabbitMQ Repo
  RABBITMQ_KEY="http://www.rabbitmq.com/rabbitmq-signing-key-public.asc"
  wget -O /tmp/rabbitmq.asc ${RABBITMQ_KEY}
  apt-key add /tmp/rabbitmq.asc

  RABBITMQ="${RABBIT_URL}/v3.1.5/rabbitmq-server_3.1.5-1_all.deb"
  wget -O /tmp/rabbitmq.deb ${RABBITMQ}
  # Install Packages
  apt-get update && apt-get install -y git curl lvm2 erlang erlang-nox
  dpkg -i /tmp/rabbitmq.deb

  # Setup shared RabbitMQ
  rabbit_setup

  # Download/Install Chef
  CHEF="https://www.opscode.com/chef/download-server?p=ubuntu&pv=12.04&m=x86_64"
  CHEF_SERVER_PACKAGE_URL=${CHEF_SERVER_PACKAGE_URL:-$CHEF}
  wget -O /tmp/chef_server.deb ${CHEF_SERVER_PACKAGE_URL}
  dpkg -i /tmp/chef_server.deb

}


function install_yum_packages() {
  # Install BASE Packages
  yum -y install git lvm2

  if [ "${IPTABLES_SAVE}" ];then
    ${IPTABLES_SAVE} > /etc/iptables.original
  fi

  if [ "${IPTABLES}" ];then
    ${IPTABLES} -I INPUT -m tcp -p tcp --dport 443 -j ACCEPT
    ${IPTABLES} -I INPUT -m tcp -p tcp --dport 80 -j ACCEPT
    service iptables save
  fi

  # Install ERLANG
  pushd /tmp
  set +e
  wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
  wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
  rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm
  set -e
  popd
  yum -y install erlang

  # Install RabbitMQ
  RABBITMQ_KEY="http://www.rabbitmq.com/rabbitmq-signing-key-public.asc"
  rpm --import ${RABBITMQ_KEY}

  RABBITMQ="${RABBIT_URL}/v3.1.5/rabbitmq-server-3.1.5-1.noarch.rpm"
  wget -O /tmp/rabbitmq.rpm ${RABBITMQ}
  rpm -Uvh /tmp/rabbitmq.rpm
  chkconfig rabbitmq-server on
  /sbin/service rabbitmq-server start

  # Setup shared RabbitMQ
  rabbit_setup

  # Download/Install Chef
  CHEF="https://www.opscode.com/chef/download-server?p=el&pv=6&m=x86_64"
  CHEF_SERVER_PACKAGE_URL=${CHEF_SERVER_PACKAGE_URL:-$CHEF}
  wget -O /tmp/chef_server.rpm ${CHEF_SERVER_PACKAGE_URL}
  yum install -y /tmp/chef_server.rpm

}


# Create a Cinder Volume file
# ==========================================================================
function create_cinder() {
  LOOP=$(losetup -f)
  dd if=/dev/zero of=${CINDER} bs=1 count=0 seek=1000G
  losetup ${LOOP} ${CINDER}
  pvcreate ${LOOP}
  vgcreate cinder-volumes ${LOOP}

  # Set Cinder Device as Persistent
  cat > /opt/cinder.sh <<EOF
#!/usr/bin/env bash
LOOP=$(losetup -f)
CINDER="/opt/cinder.img"
losetup ${LOOP} ${CINDER}
EOF

  if [ -f "/opt/cinder.sh" ];then
    check_rclocal

    if [ ! "$(grep 'cinder.sh' /etc/rc.local)" ];then
      echo "/opt/cinder.sh" | tee -a /etc/rc.local
    fi

    chmod +x /opt/cinder.sh
    chmod +x /etc/rc.local
  fi

}


# Create a Swap file if the system has no swap
# ==========================================================================
function check_rclocal() {
  if [ ! -f "/etc/rc.local" ];then
    touch /etc/rc.local
  fi

  if [ "$(grep 'exit 0' /etc/rc.local)" ];then
    sed -i '/exit\ 0/ s/^/#\ /' /etc/rc.local
  fi

}


function create_swap() {
  if [ ! -d "/opt" ];then
    mkdir /opt
  fi

  if [ ! "$(swapon -s | grep -v Filename)" ];then
    cat > /opt/swap.sh <<EOF
#!/usr/bin/env bash
if [ ! "\$(swapon -s | grep -v Filename)" ];then
SWAPFILE="/tmp/SwapFile"
if [ -f "\${SWAPFILE}" ];then
  swapoff -a
  rm \${SWAPFILE}
fi
dd if=/dev/zero of=\${SWAPFILE} bs=1M count=2048
mkswap \${SWAPFILE}
swapon \${SWAPFILE}
fi
EOF

    chmod +x /opt/swap.sh
    /opt/swap.sh
  fi

  if [ -f "/opt/swap.sh" ];then
    check_rclocal

    if [ ! "$(grep 'swap.sh' /etc/rc.local)" ];then
      echo "/opt/swap.sh" | tee -a /etc/rc.local
    fi

    chmod +x /etc/rc.local
  fi

  SWAPPINESS=$(sysctl -a | grep vm.swappiness | awk -F' = ' '{print $2}')
  if [ "${SWAPPINESS}" != 60 ];then
    if [ "$(grep '^vm.swappiness$' /etc/sysctl.conf)" ];then
      sed -i '/vm.swappiness.*/ s/^/#\ /' /etc/sysctl.conf
    fi
    sysctl vm.swappiness=60 | tee -a /etc/sysctl.conf
  fi

}


# Test Cookbooks
# ==========================================================================
function testing_cookbooks() {
  if [ "${TESTING_COOKBOOKS}" ];then
    pushd /opt/allinoneinone/chef-cookbooks/cookbooks
    for COOKBOOK in ${TESTING_COOKBOOKS};do
      NAME=$(echo ${COOKBOOK} | awk -F'=' '{print $1}')
      BRANCH=$(echo ${COOKBOOK} | awk -F'=' '{print $2}')
      URL=$(echo ${COOKBOOK} | awk -F'=' '{print $3}')

      if [ -d "${NAME}" ];then
        rm -rf ${NAME}
      fi

      git clone -b ${BRANCH} ${URL} ${NAME}
    done
    popd
  fi

}


# Configure Rabbit
# ==========================================================================
function rabbit_setup() {
  rabbitmqctl add_vhost /chef
  rabbitmqctl add_user chef ${RMQ_PW}
  rabbitmqctl set_permissions -p /chef chef '.*' '.*' '.*'
}


# Neutron Setup
# ==========================================================================
function neutron_setup() {
  # Add in some Kernel Options
  MODS="/tmp/mods.txt"
  sysctl -a | sed 's/\ //g' | tee ${MODS}

  if [ -f "/etc/sysctl.conf" ];then
    if [ "$(awk -F'=' '/net.ipv4.ip_forward/ {print $2}' ${MODS})" == "0" ];then
      sysctl net.ipv4.ip_forward=1 | tee -a /etc/sysctl.conf
    fi

    if [ ! "$(awk -F'=' '/net.ipv4.conf.all.rp_filter/ {print $2}' ${MODS})" == "0" ];then
      sysctl net.ipv4.conf.all.rp_filter=0 | tee -a /etc/sysctl.conf
    fi

    if [ ! "$(awk -F'=' '/net.ipv4.conf.default.rp_filter/ {print $2}' ${MODS})" == "0" ];then
      sysctl net.ipv4.conf.default.rp_filter=0 | tee -a /etc/sysctl.conf
    fi
  fi

  # Make our networks
  ${NEUTRON_NAME} net-create --provider:physical_network=ph-${NEUTRON_INTERFACE} \
                             --provider:network_type=flat \
                             --shared ${NEUTRON_NETWORK_NAME}

  # Make our subnets
  ${NEUTRON_NAME} subnet-create ${NEUTRON_NETWORK_NAME} \
                                172.16.0.0/16 \
                                --name ${NEUTRON_NETWORK_NAME}_subnet \
                                --no-gateway \
                                --host-route destination=0.0.0.0/0,nexthop=172.16.0.1 \
                                --allocation-pool start=172.16.0.100,end=172.16.0.200 \
                                --dns-nameservers list=true 8.8.8.8 8.8.8.7

  # Configure OVS
  ovs-vsctl add-port br-${NEUTRON_INTERFACE} ${NEUTRON_INTERFACE}

  # Add Default Ping Security Group
  ${NEUTRON_NAME} security-group-rule-create --protocol icmp \
                                             --direction ingress default

  # Add Default SSH Security Group
  ${NEUTRON_NAME} security-group-rule-create --protocol tcp \
                                             --port-range-min 22 \
                                             --port-range-max 22 \
                                             --direction ingress \
                                             default

  # Add notice to bash login
  echo -e '
Remember! That this system is using Neutron. To gain access to an instance via
the command line you MUST execute commands within in the namespace. Example,
"ip netns exec NAME_SPACE_ID bash".

This will give you shell access to the specific namespace routing table Execute
"ip netns" for a full list of all network namespsaces on this Server.
' | tee -a /etc/motd

}


# Remove Default Flavors and add a new default
# ==========================================================================
function flavor_setup() {
  # Delete all of the m1 flavors
  for FLAVOR in $(nova flavor-list | awk '/m1/ {print $2}');do
    nova flavor-delete ${FLAVOR}
  done

  # Create a new Standard Flavor
  nova flavor-create "512MB Standard Instance" 1 512 5 1 --ephemeral 0 \
                                                         --swap 512 \
                                                         --rxtx-factor 1 \
                                                         --is-public True

}


# Run Chef Bootstrap
# ==========================================================================
function boot_strap_node() {
  set +e

  MAX_RETRIES=${MAX_RETRIES:-5}
  RETRY=0

  # Set the initial return value to failure
  false

  while [ $? -ne 0 -a ${RETRY} -lt ${MAX_RETRIES} ];do
    # Begin Cooking
    RETRY=$((${RETRY}+1))
    knife bootstrap localhost -E allinoneinone -r ${RUN_LIST}
  done

  if [ ${RETRY} -eq ${MAX_RETRIES} ];then
    error_exit "Hit maximum number of retries, giving up..."
  fi

  set -e

}


# Success Message
# ==========================================================================
function success_exit() {
  set +v

  # Drop Lock File
  echo "AIOIO INSTALLATION COMPLETED: $(date +%y%m%d%H%M)" | tee /opt/aioio-installed.lock

  # Reset users Password post installation
  IAM=$(whoami)
  echo -e "${SYSTEM_PW}\n${SYSTEM_PW}" | (${PASSWD} ${IAM})

  # Notify the users and set new the MOTD
  echo -e "

** NOTICE **

This is an Openstack Deployment based on the Rackspace Private Cloud Software.
# ============================================================================

Cookbook Branch/Version is     : ${COOKBOOK_VERSION}
Your RabbitMQ Password is      : ${RMQ_PW}
Your OpenStack Password is     : ${NOVA_PW}
Admin SSH key has been set as  : adminKey
Cinder volumes are located     : ${CINDER}
Openstack Cred File is located : /root/openrc
Horizon URL is                 : https://${SYS_IP}:443

Chef Server URL is             : ${CHEF_SERVER_URL}
Chef Server Password is        : ${CHEF_PW}
Your knife.rb is located       : /root/.chef/knife.rb
All cookbooks are located      : /opt/allinoneinone

# ============================================================================

" | tee /etc/motd

  # Tell users how to get started on the CLI
  echo -e "
For instant access to Nova please run \"source /root/openrc\" This will load
Your credentials. Otherwise logout and log back in, your Nova Credentials will
be auto-loaded when you log back in.

You also have access to \"knife\" which can be used for modification and
management of your Chef Server.


================== NOTICE ==================
      Your ROOT password has been reset

Here are the details:

Username : ${IAM}
Password : ${SYSTEM_PW}

** Please make a note of this! **



*** While not required or necessary, you may want to reboot your AIO server ***
"

  # Exit Zero
  exit 0

}

# Trap all Death Signals and Errors
trap "error_exit ${LINENO} $? 'Received STOP Signal'" SIGHUP SIGINT SIGTERM
trap "error_exit ${LINENO} $?" ERR


# Begin the Install Process
# ============================================================================
# Check for previous Installation

# OS Check
if [ "$(grep -i -e redhat -e centos /etc/redhat-release)"  ]; then
  REMOVE_SYSTEM_PACKAGES=remove_rpm_packages
  PACKAGE_INSTALL=install_yum_packages
elif [ "$(grep -i ubuntu /etc/lsb-release)" ];then
  REMOVE_SYSTEM_PACKAGES=remove_apt_packages
  PACKAGE_INSTALL=install_apt_packages
else
  echo "This is not a supported OS, So this script will not work."
  exit 1
fi

if [ -f "/opt/aioio-installed.lock" ];then
  echo "Lock File found at \"/opt/aioio-installed.lock\""
  echo "I am assuming that this installation has already been completed on this box."
  exit 1
fi

# Make the system key used for bootstrapping self
if [ ! -f "/root/.ssh/id_rsa" ];then
    ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
    pushd /root/.ssh/
    cat id_rsa.pub | tee -a authorized_keys
    popd
fi

# Enable || Disable Developer Mode
DEVELOPER_MODE=${DEVELOPER_MODE:-False}

# Enable || Disable Package Upgrades
DO_PACKAGE_UPGRADES=${DO_PACKAGE_UPGRADES:-True}

# List of all Services
OPENSTACK_SERVICES="cinder glance nova keystone ceilometer heat horizon "

# General Packages
GENERAL_PACKAGES="rabbitmq chef mysql monit collectd epel-release-6 remi-release-6 nginx apache httpd "

# Disable Roll Back
DISABLE_ROLL_BACK=${DISABLE_ROLL_BACK:-false}

# Chef Server Password
CHEF_PW=${CHEF_PW:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 9)}

# Set Rabbit Pass
RMQ_PW=${RMQ_PW:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 9)}

# Set Rabbit Address
RMQ_ADDR=${RMQ_ADDR:-""}

# Set Admin Pass
NOVA_PW=${NOVA_PW:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 9)}

# Set the system Pass
SYSTEM_PW=${SYSTEM_PW:-${NOVA_PW}}

# Set the Cookbook Version
COOKBOOK_VERSION=${COOKBOOK_VERSION:-v4.1.2}

# Set Cinder Data
CINDER=${CINDER:-"/opt/cinder.img"}

# Enable || Disable Neutron
NEUTRON_ENABLED=${NEUTRON_ENABLED:-False}

# Set the Interface
NEUTRON_INTERFACE=${NEUTRON_INTERFACE:-eth1}

# Set the Name of the Neutron Service
NEUTRON_NAME=${NEUTRON_NAME:-"quantum"}

# Set network name
NEUTRON_NETWORK_NAME=${NEUTRON_NETWORK_NAME:-"aioionet"}

# Set the default Run list
RUN_LIST=${RUN_LIST:-"role[allinone],role[cinder-all]"}

# Default Images
UBUNTU_IMAGE=${UBUNTU_IMAGE:-False}
FEDORA_IMAGE=${FEDORA_IMAGE:-False}
CIRROS_IMAGE=${CIRROS_IMAGE:-False}

# Testing Cookbooks
TESTING_COOKBOOKS=${TESTING_COOKBOOKS:-""}

# Bind Interfaces
MANAGEMENT_INTERFACE=${MANAGEMENT_INTERFACE:-eth0}
NOVA_INTERFACE=${NOVA_INTERFACE:-eth0}
PUBLIC_INTERFACE=${PUBLIC_INTERFACE:-eth0}

# Bind Cidrs
MANAGEMENT_INTERFACE_CIDR=${MANAGEMENT_INTERFACE_CIDR:-""}
NOVA_INTERFACE_CIDR=${NOVA_INTERFACE_CIDR:-""}
PUBLIC_INTERFACE_CIDR=${PUBLIC_INTERFACE_CIDR:-""}

# Set the PATH on things we need
PYTHON_PATH=${PYTHON_PATH:-"$(which python)"}
IPTABLES_RESTORE=${IPTABLES_RESTORE:-"$(which iptables-restore)"}
IPTABLES_SAVE=${IPTABLES_SAVE:-"$(which iptables-save)"}
IPTABLES=${IPTABLES:-"$(which iptables)"}
PASSWD=${PASSWD:-"$(which passwd)"}

create_swap

RABBIT_URL="http://www.rabbitmq.com/releases/rabbitmq-server"

# Install Packages
${PACKAGE_INSTALL}

# Grab existing Chef Cookie
CHEF_COOKIE=$(cat /var/lib/rabbitmq/.erlang.cookie)

if [ "$(ip -f inet -o addr show ${MANAGEMENT_INTERFACE})" ];then
  MANAGEMENT_IP=$(ip -f inet -o addr show ${MANAGEMENT_INTERFACE} | awk '{print $4}' | awk -F'/' '{print $1}')
else
  MANAGEMENT_IP='#{node["ipaddress"]}'
fi

# Configure Chef Vars
mkdir -p /etc/chef-server
cat > /etc/chef-server/chef-server.rb <<EOF
erchef['s3_url_ttl'] = 3600
nginx["ssl_port"] = 4000
nginx["non_ssl_port"] = 4080
nginx["enable_non_ssl"] = true
rabbitmq["enable"] = false
rabbitmq["password"] = "${RMQ_PW}"
chef_server_webui['web_ui_admin_default_password'] = "${CHEF_PW}"
bookshelf['url'] = "https://#{node['ipaddress']}:4000"
EOF

# Reconfigure Chef
chef-server-ctl reconfigure

# Install Chef Client
bash <(wget -O - http://opscode.com/chef/install.sh)

# Set the systems IP ADDRESS
SYS_IP=$(ohai ipaddress | awk '/^ / {gsub(/ *\"/, ""); print; exit}')

# Configure Knife
mkdir -p /root/.chef
cat > /root/.chef/knife.rb <<EOF
log_level                :info
log_location             STDOUT
node_name                'admin'
client_key               '/etc/chef-server/admin.pem'
validation_client_name   'chef-validator'
validation_key           '/etc/chef-server/chef-validator.pem'
chef_server_url          "https://${SYS_IP}:4000"
cache_options( :path => '/root/.chef/checksums' )
cookbook_path            [ '/opt/allinoneinone/chef-cookbooks/cookbooks' ]
EOF

# Export Chef URL
export CHEF_SERVER_URL=https://${SYS_IP}:4000

# Get RcbOps Cookbooks
mkdir -p /opt/allinoneinone
git clone https://github.com/rcbops/chef-cookbooks.git /opt/allinoneinone/chef-cookbooks
pushd /opt/allinoneinone/chef-cookbooks
git checkout ${COOKBOOK_VERSION}
git submodule init
git submodule sync
git submodule update

# Get add-on Cookbooks
knife cookbook site download -f /tmp/cron.tar.gz cron 1.2.6 && tar xf /tmp/cron.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks
knife cookbook site download -f /tmp/chef-client.tar.gz chef-client 3.0.6 && tar xf /tmp/chef-client.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks

# Get / Replace all testing cookbooks
testing_cookbooks

# Upload all of the RCBOPS Cookbooks
knife cookbook upload -o /opt/allinoneinone/chef-cookbooks/cookbooks -a

# Upload all of the RCBOPS Roles
knife role from file /opt/allinoneinone/chef-cookbooks/roles/*.rb

# Set the Default Chef Environment
${PYTHON_PATH} << EOF
import json
import subprocess

_ohai = subprocess.Popen(['ohai', '-l', 'fatal'], stdout=subprocess.PIPE)
ohai = _ohai.communicate()[0]
data = json.loads(ohai)

def get_network(interface):
    device = data['network']['interfaces'].get(interface)
    if device is not None:
        if device.get('routes'):
            routes = device['routes']
            for net in routes:
                if 'scope' in net:
                    return net.get('destination', '127.0.0.0/24')
                    break
            else:
                return '127.0.0.0/24'
        else:
            return '127.0.0.0/24'
    else:
        return '127.0.0.0/24'

if not "${MANAGEMENT_INTERFACE_CIDR}":
    management_network = get_network(interface="${MANAGEMENT_INTERFACE}")
else:
    management_network = "${MANAGEMENT_INTERFACE_CIDR}"

if not "${NOVA_INTERFACE_CIDR}":
    nova_network = get_network(interface="${NOVA_INTERFACE}")
else:
    nova_network = "${NOVA_INTERFACE_CIDR}"

if not "${PUBLIC_INTERFACE_CIDR}":
    public_network = get_network(interface="${PUBLIC_INTERFACE}")
else:
    public_network = "${PUBLIC_INTERFACE_CIDR}"

env = {'chef_type': 'environment',
  'cookbook_versions': {},
  'default_attributes': {},
  'description': 'OpenStack Test All-In-One Deployment in One Server',
  'json_class': 'Chef::Environment',
  'name': 'allinoneinone',
  'override_attributes': {
    'osops': {
      'do_package_upgrades': ${DO_PACKAGE_UPGRADES:-True}
    },
    'developer_mode': ${DEVELOPER_MODE:-False},
    'rabbitmq': {
      'address': "${RMQ_ADDR}",
      'erlang_cookie': "${CHEF_COOKIE}"
    },
    'enable_monit': True,
    'glance': {
        'image': {},
      'image_upload': True,
      'images': []
    },
    'keystone': {
      'admin_user': 'admin',
      'pki': {
        'enabled': True
      },
      'tenants': [
        'service', 'admin'
      ],
      'users': {
        'admin': {
          'password': "${NOVA_PW}",
          'role': {
            'admin': ['admin']
          }
        }
      }
    },
    'heat': {
      "services": {
        "cloudwatch_api": {
          "workers": 2,
        },
        "cfn_api": {
          "workers": 2,
        },
        "base_api": {
          "workers": 2,
        }
      }
    },
    'monitoring': {
      'metric_provider': 'collectd',
      'procmon_provider': 'monit'
    },
    'mysql': {
      'allow_remote_root': True,
      "bind_address": "0.0.0.0",
      'root_network_acl': '%',
      'tunable': {
        'log_queries_not_using_index': False
      }
    },
    'nova': {
      'config': {
        'cpu_allocation_ratio': 2.0,
        'disk_allocation_ratio': 1.0,
        'ram_allocation_ratio': 1.0,
        'resume_guests_state_on_host_boot': False,
        'use_single_default_gateway': False
      },
      'libvirt': {
        'virt_type': "${VIRT_TYPE:-qemu}",
        'vncserver_listen': '0.0.0.0'
      },
      'network': {},
      'networks': {},
      'scheduler': {
        'default_filters': [
          'AvailabilityZoneFilter',
          'ComputeFilter',
          'RetryFilter'
        ]
      }
    },
    'osops_networks': {
      'management': management_network,
      'nova': nova_network,
      'public': public_network
    }
  }
}

if ${NEUTRON_ENABLED} is True:
    env['override_attributes']['nova']['network'].update({
        "provider": "${NEUTRON_NAME}"
    })

    neutron_interface = "${NEUTRON_INTERFACE}"
    net_attrs = env['override_attributes']["${NEUTRON_NAME}"] = {
        "ovs": {
            "network_type": "gre",
            "provider_networks": [
                {
                    "bridge": "br-%s" % neutron_interface,
                    "vlans": "1:1000",
                    "label": "ph-%s" % neutron_interface
                }
            ]
        }
    }
    net_attrs['metadata_network'] = "True"
else:
    env['override_attributes']['nova']['network'].update({
        'multi_host': True,
        'public_interface': 'br0'
    })

    env['override_attributes']['nova']['networks'].update({
        'public': {
          'bridge': 'br0',
          'bridge_dev': 'eth0',
          'dns1': '8.8.8.8',
          'dns2': '8.8.4.4',
          'ipv4_cidr': '172.16.0.0/16',
          'label': 'public',
          'network_size': '255',
          'num_networks': '1'
        }
    })

cirros_img_url = ('https://launchpad.net/cirros/trunk/0.3.0/+download/'
                  'cirros-0.3.0-x86_64-disk.img')
ubuntu_img_url = ('http://cloud-images.ubuntu.com/precise/current/'
                  'precise-server-cloudimg-amd64-disk1.img')
fedora_img_url = ('http://download.fedoraproject.org/pub/fedora/linux/'
                  'releases/19/Images/x86_64/'
                  'Fedora-x86_64-19-20130627-sda.qcow2')

if ${UBUNTU_IMAGE} is True:
    env['override_attributes']['glance']['image']['ubuntu'] = ubuntu_img_url
    env['override_attributes']['glance']['images'].append('ubuntu')


if ${FEDORA_IMAGE} is True:
    env['override_attributes']['glance']['image']['fedora'] = fedora_img_url
    env['override_attributes']['glance']['images'].append('fedora')


if ${CIRROS_IMAGE} is True:
    env['override_attributes']['glance']['image']['cirros'] = cirros_img_url
    env['override_attributes']['glance']['images'].append('cirros')

with open('allinoneinone.json', 'wb') as rcbops:
    rcbops.write(json.dumps(env, indent=2))

EOF


# Upload Environment
knife environment from file allinoneinone.json

# Exit Work Dir
popd

# Make Cinder Device
if [ -b "${CINDER}" ];then
  pvcreate ${CINDER}
  vgcreate cinder-volumes ${CINDER}
  sed -i "/$(echo ${CINDER} | sed 's/\//\\\//g')/ s/^/#\ /" /etc/fstab
else
  create_cinder
fi

# Run Chef Bootstrap
boot_strap_node

# go to root home
pushd /root

# Source the Creds
source ~/openrc

# Add a default Key
nova keypair-add adminKey --pub-key /root/.ssh/id_rsa.pub

# Add a Volume Type
nova volume-type-create TestVolType

# Add creds to default env
echo "source ~/openrc" | tee -a .bashrc
echo "export EDITOR=vim" | tee -a .bashrc

# Exit Root Dir
popd

# Remove MOTD files
if [ -f "/etc/motd" ];then
  rm /etc/motd
fi

if [ -f "/var/run/motd" ];then
  rm /var/run/motd
fi

# Remove PAM motd modules from config
if [ -f "/etc/pam.d/login" ];then
  sed -i '/pam_motd.so/ s/^/#\ /' /etc/pam.d/login
fi

if [ -f "/etc/pam.d/sshd" ];then
  sed -i '/pam_motd.so/ s/^/#\ /' /etc/pam.d/sshd
fi

# Setup Neutron
if [ "${NEUTRON_ENABLED}" == "True" ];then
  neutron_setup
fi

# Setup a new flavor
flavor_setup

# GREAT SUCCESS!
success_exit
