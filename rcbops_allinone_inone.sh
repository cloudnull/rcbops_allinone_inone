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
# =====================================
# Openstack Controller
# Openstack Compute
# Horizon
# Cinder
# Cinder is built on a loop file
# Nova-Network
# ubuntu 12.04 LTS Image
# cirros Image
# Developer Mode is enabled
# Quantum is NOT being used
# Qemu is used for the Virt Driver
# The Latest Stable Chef Server
# Chef Client
# Knife


#!/usr/bin/env bash
set -v

# Make the system key used for bootstrapping self
yes '' | ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
pushd /root/.ssh/
cat id_rsa.pub >> authorized_keys
popd

# Upgrade packages and repo list.
apt-get update && apt-get -y upgrade
apt-get install -y rabbitmq-server git curl lvm2

# Set Rabbit Pass
export CHEF_RMQ_PW=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 24)

# Set Admin Pass
export admin_pass=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

# Configure Rabbit
rabbitmqctl add_vhost /chef
rabbitmqctl add_user chef ${CHEF_RMQ_PW}
rabbitmqctl set_permissions -p /chef chef '.*' '.*' '.*'

# Grab existing Chef Cookie
export CHEF_COOKIE=$(cat /var/lib/rabbitmq/.erlang.cookie)

# Download/Install Chef
wget -O /tmp/chef_server.deb 'https://www.opscode.com/chef/download-server?p=ubuntu&pv=12.04&m=x86_64'
dpkg -i /tmp/chef_server.deb

# Configure Chef Vars.
mkdir /etc/chef-server
cat > /etc/chef-server/chef-server.rb <<EOF
nginx["ssl_port"] = 4000
nginx["non_ssl_port"] = 4080
nginx["enable_non_ssl"] = true
rabbitmq["enable"] = false
rabbitmq["password"] = "${CHEF_RMQ_PW}"
chef_server_webui['web_ui_admin_default_password'] = "${admin_pass}"
bookshelf['url'] = "https://#{node['ipaddress']}:4000"
EOF

# Reconfigure Chef.
chef-server-ctl reconfigure

# Install Chef Client.
bash <(wget -O - http://opscode.com/chef/install.sh)

# Configure Knife.
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

# Get RcbOps Cookbooks.
mkdir -p /opt/allinoneinone
git clone -b grizzly git://github.com/rcbops/chef-cookbooks.git /opt/allinoneinone/chef-cookbooks
pushd /opt/allinoneinone/chef-cookbooks
git submodule init
git checkout v4.1.2
git submodule update
knife cookbook site download -f /tmp/cron.tar.gz cron 1.2.6 && tar xf /tmp/cron.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks

knife cookbook site download -f /tmp/chef-client.tar.gz chef-client 3.0.6 && tar xf /tmp/chef-client.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks

knife cookbook upload -o /opt/allinoneinone/chef-cookbooks/cookbooks -a
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
            return '127.0.0.0/8'
    else:
        return '127.0.0.0/8'

network = get_network(interface='eth0')

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
    'rabbitmq': {
      'erlang_cookie': "${CHEF_COOKIE}"
    },
    'developer_mode': True,
    'enable_monit': True,
    'glance': {
        'image': {
            'cirros': cirros_img_url,
            'precise': ubuntu_img_url
            'fedora': fedora_img_url
        },
    'image_upload': True,
    'images': ['cirros', 'precise', 'fedora']},
    'keystone': {'admin_user': 'admin',
    'pki': {'enabled': True},
    'tenants': ['service', 'admin'],
    'users': {'admin': {'password': "${admin_pass}",
      'role': {'admin': ['admin']}}}},
    'monitoring': {'metric_provider': 'collectd',
    'procmon_provider': 'monit'},
    'mysql': {'allow_remote_root': True,
    'root_network_acl': '%',
    'tunable': {'log_queries_not_using_index': False}},
    'nova': {
      'config': {
        'cpu_allocation_ratio': 2.0,
        'disk_allocation_ratio': 1.0,
        'ram_allocation_ratio': 1.0,
        'resume_guests_state_on_host_boot': False,
        'use_single_default_gateway': False
      },
      'libvirt': {
        'virt_type': 'qemu',
        'vncserver_listen': '0.0.0.0'
      },
      'network': {
        'multi_host': True,
        'public_interface': 'br0'
      },
      'networks': {
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
      },
      'scheduler': {
        'default_filters': [
          'AvailabilityZoneFilter',
          'ComputeFilter',
          'RetryFilter'
        ]
      }
    },
    'osops_networks': {
      'management': network,
      'nova': network,
      'public': network
    }
  }
}

with open('allinoneinone.json', 'wb') as rcbops:
    rcbops.write(json.dumps(env, indent=2))

EOF

# Upload Environment
knife environment from file allinoneinone.json

# Exit Work Dir
popd

# Export Chef URL
export CHEF_SERVER_URL=https://$(ohai ipaddress | awk '/^ / {gsub(/ *\"/, ""); print; exit}'):4000

# Set Cinder Data
export CINDER="/opt/cinder.img"
export LOOP=$(losetup -f)

# Make Cinder Device
dd if=/dev/zero of=${CINDER} bs=1 count=0 seek=1000G
losetup ${LOOP} ${CINDER}
pvcreate ${LOOP}
vgcreate cinder-volumes ${LOOP}

# Set Cinder Device as Persistent
echo -e 'LOOP=$(losetup -f)\nCINDER="/opt/cinder.img"\nlosetup ${LOOP} ${CINDER}' | tee /etc/rc.local

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
echo 'source openrc' | tee -a .bashrc
echo "export EDITOR=vim" | tee -a .bashrc

popd

# Notify the users
echo -e "
Installation complete.

Your RabbitMQ Password is    : ${CHEF_RMQ_PW}
Your OpenStack Password is   : ${admin_pass}
Admin SSH key has been added : adminKey
Cinder Image file is located : ${CINDER}
Admin Cred File is located   : /root/openrc

Chef Server URL is           : ${CHEF_SERVER_URL}
Chef Server Password is      : ${admin_pass}
Your Knife Creds are located : /root/.chef
All raw cookbooks are located: /opt/allinoneinone


"
