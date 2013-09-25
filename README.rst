Run Openstack all In One
########################
:date: 2013-09-05 09:51
:tags: rackspace, openstack,
:category: \*nix

Run an RCBOPS All In One Deployment In One Server
=================================================


General Overview
~~~~~~~~~~~~~~~~


I made this script such that you can stand up an Openstack based on Rackspace Private Cloud Software in minutes and play with it. This is a VERY simple script which will build you an environment based on the Rackspace Private Cloud Software. This script is presently using the v4.1.2 TAG by default from the rcbops-cookbooks repo : (https://github.com/rcbops/chef-cookbooks) though an override can be set to use any and all RCBOPS releases.


This script will install the following:

* Openstack Controller
* Openstack Compute
* Horizon
* Cinder
* Nova-Network
* ubuntu 12.04 LTS Image
* Cirros Image
* Fedora Image
* Ubuntu Image
* Qemu is used for the Virt Driver
* The Latest Stable Chef Server
* Chef Client
* Knife


========


Configuration Options
~~~~~~~~~~~~~~~~~~~~~


The script has a bunch of override variables that can be set in script or as environment variables.


Set this to override the RCBOPS Developer Mode, DEFAULT is False:
  DEVELOPER_MODE=True or False

Set this to override the chef default password, DEFAULT is "Random Things":
  CHEF_PW=""

Set this to override the RabbitMQ Password, DEFAULT is "Random Things":
  RMQ_PW=""

Set this to override the Openstack Admin Pass, DEFAULT is "Random Things":
  NOVA_PW=""

Set this to override the Cookbook version, DEFAULT is "v4.1.2":
  COOKBOOK_VERSION=""

Set this to override the Management Interface, DEFAULT is "eth0":
  MANAGEMENT_INTERFACE=""

Set this to override the Nova Interface, DEFAULT is "eth0":
  NOVA_INTERFACE=""

Set this to override the Public Interface, DEFAULT is "eth0":
  PUBLIC_INTERFACE=""

Set this to override the Virt Type, DEFAULT is "qemu":
  VIRT_TYPE=""

Set this to override the Cinder Device, DEFAULT is "/opt/cinder.img":
  CINDER=""


========


Here is how you can get Started.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


1. Provision Server with a minimum of 2GB of ram and 10GB of hard disk space.
2. Login to server as root
3. Set any of your environment variables that you may want to use while running the script.
4. execute::

    curl https://raw.github.com/cloudnull/rcbops_allinone_inone/master/rcbops_allinone_inone.sh | bash


5. Go to the IP address of your server, login to Horizon, have fun with Openstack.


NOTICE: I WOULD NOT RECOMMEND USING THIS IN PRODUCTION!
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


License:
  Copyright [2013] [Kevin Carter]

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
