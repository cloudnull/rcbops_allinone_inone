# Make the system key used for bootstrapping self
yes '' | ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
pushd /root/.ssh/
cat id_rsa.pub >> authorized_keys
popd

# Upgrade packages and repo list.
apt-get update && apt-get -y upgrade
apt-get install -y rabbitmq-server git curl

# Set Rabbit Pass
export CHEF_RMQ_PW=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 24)

# Configure Rabbit
rabbitmqctl add_vhost /chef
rabbitmqctl add_user chef $CHEF_RMQ_PW
rabbitmqctl set_permissions -p /chef chef '.*' '.*' '.*'

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
rabbitmq["password"] = "$CHEF_RMQ_PW"
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
cd /opt/allinoneinone/chef-cookbooks
git submodule init
git checkout v4.1.0
git submodule update
knife cookbook site download -f /tmp/cron.tar.gz cron 1.2.6 && tar xf /tmp/cron.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks
knife cookbook site download -f /tmp/chef-client.tar.gz chef-client 3.0.6 && tar xf /tmp/chef-client.tar.gz -C /opt/allinoneinone/chef-cookbooks/cookbooks

knife cookbook upload -o /opt/allinoneinone/chef-cookbooks/cookbooks -a
knife role from file /opt/allinoneinone/chef-cookbooks/roles/*.rb

sed -i 's/\["tunable"\]\["repl_pass"\]/["server_repl_password"]/g' /opt/allinoneinone/chef-cookbooks/cookbooks/mysql-openstack/recipes/server.rb
knife cookbook upload -o /opt/allinoneinone/chef-cookbooks/cookbooks -a

knife exec -E 'search(:node, "role:*controller*") { |n| m=n.normal["mysql"]; if m["tunable"].has_key? "repl_pass" ; m["server_repl_password"] = m["tunable"].delete("repl_pass"); n.save ; end }'
knife exec -E 'search(:node, "role:*controller*") { |n| m=n.normal["mysql"]; if m["tunable"]["server_id"].nil? m["tunable"]["server_id"] = m["myid"]; n.save ; end }'

# Set rcbops Chef Environment.
curl --silent https://raw.github.com/rsoprivatecloud/openstack-chef-deploy/master/environments/grizzly-neutron.json > allinoneinone.json.original

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

pub_network = get_network(interface='eth0')
network = get_network(interface='eth2')

with open('allinoneinone.json.original', 'rb') as rcbops:
    env = json.loads(rcbops.read())

env['name'] = 'allinoneinone'
env['description'] = 'OpenStack Test All-In-One Deployment in One Server'
override = env['override_attributes']
users = override['keystone']['users']
users['admin']['password'] = 'secrete'
override['glance']['image_upload'] = True
override['nova']['virt_type'] = "qemu"
override['developer_mode'] = True
override['osops_networks']['management'] = network
override['osops_networks']['public'] = pub_network
override['osops_networks']['nova'] = network
override['mysql']['root_network_acl'] = "%"

override.pop('hardware', None)
override.pop('enable_monit', None)
override.pop('monitoring', None)

with open('allinoneinone.json', 'wb') as rcbops:
    rcbops.write(json.dumps(env, indent=2))

EOF

# Upload Environment
knife environment from file allinoneinone.json

# Export Chef URL
export CHEF_SERVER_URL=https://$(ohai ipaddress | awk '/^ / {gsub(/ *\"/, ""); print; exit}'):4000

# Begin Cooking
knife bootstrap localhost -E allinoneinone -r 'role[allinone]'
