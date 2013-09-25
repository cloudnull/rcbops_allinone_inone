#!/usr/bin/env bash
set -v

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


# This script will install several bits
# ============================================================================
# Openstack Controller
# Openstack Compute
# Horizon
# Cinder is built on a loop file unless you specify a device
# Nova-Network is used
# Quantum is NOT being used
# ubuntu 12.04 LTS Image
# cirros Image
# fedora Image
# Qemu is the default Virt Driver
# The Latest Stable Chef Server
# Chef Client
# Knife


# Here are the script Override Values.
# Any of these override variables can be exported as environment variables.
# ============================================================================
# Set this to override the RCBOPS Developer Mode, DEFAULT is False
# DEVELOPER_MODE=True || False

# Set this to override the chef default password, DEFAULT is "Random Things"
# CHEF_PW=""

# Set this to override the RabbitMQ Password, DEFAULT is "Random Things"
# RMQ_PW=""

# Set this to override the Openstack Admin Pass, DEFAULT is "Random Things"
# NOVA_PW=""

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
# ================== NOTE NEUTRON DOES NOT WORK RIGHT NOW ==================
# TODO(kevin) This needs more testing and time to bake.
# NEUTRON_INTERFACE=""
# NEUTRON_NAME="quantum"
# ==========================================================================


# Begin the Install Process
# ============================================================================


# Make the system key used for bootstrapping self
yes '' | ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
pushd /root/.ssh/
cat id_rsa.pub >> authorized_keys
popd

# Upgrade packages and repo list.
apt-get update && apt-get -y upgrade
apt-get install -y rabbitmq-server git curl lvm2

# Chef Server Password
CHEF_PW=${CHEF_PW:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 9)}

# Set Rabbit Pass
RMQ_PW=${RMQ_PW:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 9)}

# Set Admin Pass
NOVA_PW=${NOVA_PW:-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 9)}

# Configure Rabbit
rabbitmqctl add_vhost /chef
rabbitmqctl add_user chef ${RMQ_PW}
rabbitmqctl set_permissions -p /chef chef '.*' '.*' '.*'

# Grab existing Chef Cookie
CHEF_COOKIE=$(cat /var/lib/rabbitmq/.erlang.cookie)

# Download/Install Chef
wget -O /tmp/chef_server.deb 'https://www.opscode.com/chef/download-server?p=ubuntu&pv=12.04&m=x86_64'
dpkg -i /tmp/chef_server.deb

# Configure Chef Vars
mkdir /etc/chef-server
cat > /etc/chef-server/chef-server.rb <<EOF
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

# Configure Knife
mkdir /root/.chef
cat > /root/.chef/knife.rb <<EOF
log_level                :info
log_location             STDOUT
node_name                'admin'
client_key               '/etc/chef-server/admin.pem'
validation_client_name   'chef-validator'
validation_key           '/etc/chef-server/chef-validator.pem'
chef_server_url          'https://localhost:4000'
cache_options( :path => '/root/.chef/checksums' )
cookbook_path            [ '/opt/allinoneinone/chef-cookbooks/cookbooks' ]
EOF

# Get RcbOps Cookbooks
mkdir -p /opt/allinoneinone
git clone -b grizzly git://github.com/rcbops/chef-cookbooks.git /opt/allinoneinone/chef-cookbooks
pushd /opt/allinoneinone/chef-cookbooks
git submodule init
git checkout ${COOKBOOK_VERSION:-v4.1.2}
git submodule update

# Get add-on Cookbooks
knife cookbook site download -f /tmp/cron.tar.gz cron 1.2.6 && tar xf /tmp/cron.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks

knife cookbook site download -f /tmp/chef-client.tar.gz chef-client 3.0.6 && tar xf /tmp/chef-client.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks

# Upload all of the RCBOPS Cookbooks
knife cookbook upload -o /opt/allinoneinone/chef-cookbooks/cookbooks -a

# Upload all of the RCBOPS Roles
knife role from file /opt/allinoneinone/chef-cookbooks/roles/*.rb

# Set the Default Chef Environment
$(which python) << EOF
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
                    return net.get('destination', '127.0.0.0/8')
                    break
        else:
            print('Interface "%s" not found, using "127.0.0.0/8".' % interface)
            return '127.0.0.0/8'
    else:
        print('Interface "%s" not found, using "127.0.0.0/8".' % interface)
        return '127.0.0.0/8'

management_network = get_network(interface="${MANAGEMENT_INTERFACE:-eth0}")
nova_network = get_network(interface="${NOVA_INTERFACE:-eth0}")
public_network = get_network(interface="${PUBLIC_INTERFACE:-eth0}")

cirros_img_url = 'https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img'
ubuntu_img_url = 'http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img'
fedora_img_url = 'http://download.fedoraproject.org/pub/fedora/linux/releases/19/Images/x86_64/Fedora-x86_64-19-20130627-sda.qcow2'

env = {'chef_type': 'environment',
  'cookbook_versions': {},
  'default_attributes': {},
  'description': 'OpenStack Test All-In-One Deployment in One Server',
  'json_class': 'Chef::Environment',
  'name': 'allinoneinone',
  'override_attributes': {
    'developer_mode': ${DEVELOPER_MODE:-False}
    'rabbitmq': {
      'erlang_cookie': "${CHEF_COOKIE}"
    },
    'enable_monit': True,
    'glance': {
        'image': {
            'cirros': cirros_img_url,
            'precise': ubuntu_img_url,
            'fedora': fedora_img_url
        },
      'image_upload': True,
      'images': [
        'cirros',
        'precise',
        'fedora'
      ]
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
    'monitoring': {
      'metric_provider': 'collectd',
      'procmon_provider': 'monit'
    },
    'mysql': {
      'allow_remote_root': True,
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

neutron_interface = "${NEUTRON_INTERFACE}"

if neutron_interface:
    env['override_attributes']["${NEUTRON_NAME}"] = {
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
    env['override_attributes']['nova']['network'] = {
        "provider": "${NEUTRON_NAME}"
    }


else:
    env['override_attributes']['nova']['network'] = {
        'multi_host': True,
        'public_interface': 'br0'
    }
    env['override_attributes']['nova']['networks'] = {
        'public': {
          'bridge': 'br0',
          'bridge_dev': 'eth0',
          'dns1': '8.8.8.8',
          'dns2': '8.8.4.4',
          'ipv4_cidr': '172.16.0.0/16',
          'label': 'public',
          'network_size': '255',
          'num_networks': '1'
        },
        'private': {
          'bridge': 'br1',
          'bridge_dev': 'eth1',
          'dns1': '8.8.8.8',
          'dns2': '8.8.4.4',
          'ipv4_cidr': '192.168.0.0/24',
          'label': 'private',
          'network_size': '255',
          'num_networks': '1'
        }
    }

with open('allinoneinone.json', 'wb') as rcbops:
    rcbops.write(json.dumps(env, indent=2))

EOF

# Upload Environment
knife environment from file allinoneinone.json

# Exit Work Dir
popd

# Set the systems IP ADDRESS
SYS_IP=$(ohai ipaddress | awk '/^ / {gsub(/ *\"/, ""); print; exit}')

# Export Chef URL
export CHEF_SERVER_URL=https://${SYS_IP}:4000

# Set Cinder Data
CINDER=${CINDER_DEV:-"/opt/cinder.img"}

# Make Cinder Device
if [ "${CINDER_DEV}" ];then
    pvcreate ${CINDER}
    vgcreate cinder-volumes ${CINDER}
    sed -i "/$(echo ${CINDER} | sed 's/\//\\\//g')/ s/^/#\ /" /etc/fstab
else
    LOOP=$(losetup -f)
    dd if=/dev/zero of=${CINDER} bs=1 count=0 seek=1000G
    losetup ${LOOP} ${CINDER}
    pvcreate ${LOOP}
    vgcreate cinder-volumes ${LOOP}

    # Set Cinder Device as Persistent
    echo -e 'LOOP=$(losetup -f)\nCINDER="/opt/cinder.img"\nlosetup ${LOOP} ${CINDER}' | tee /etc/rc.local
fi

# Begin Cooking
knife bootstrap localhost -E allinoneinone -r 'role[allinone],role[cinder-all]'

# go to root home
pushd /root

# Source the Creds
source openrc

# Add a default Key
nova keypair-add adminKey --pub-key /root/.ssh/id_rsa.pub

# Add a Volume Type
nova volume-type-create TestVolType

# Add creds to default env
echo "source openrc" | tee -a .bashrc
echo "export EDITOR=vim" | tee -a .bashrc

# Exit Root Dir
popd

# Remove MOTD files
rm /etc/motd
rm /var/run/motd

# Remove PAM motd modules from config
sed -i '/pam_motd.so/ s/^/#\ /' /etc/pam.d/login
sed -i '/pam_motd.so/ s/^/#\ /' /etc/pam.d/sshd

# Notify the users and set new the MOTD
echo -e "

** NOTICE **

This is an Openstack Deployment based on the Rackspace Private Cloud Software.
# ============================================================================

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

"

# Exit Zero
exit 0
