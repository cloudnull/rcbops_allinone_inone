Run Openstack all In One
########################
:date: 2013-09-05 09:51
:tags: rackspace, openstack,
:category: \*nix

Run an RCBOPS All In One Deployment In One Server
=================================================


General Overview
~~~~~~~~~~~~~~~~


This script was create to allow for rapid deployment of a **testing** node based on the Rackspace Private Cloud Chef Cookbooks.

This will stand up an Openstack in minutes and once the installation is complete, you will be able to test drive Openstack while seeing what the Rackspace Private Cloud Software is capable of.

This is a VERY simple script but does allow for some control into the setup and configuration process, please see the **Configuration Options** section for more information.

This script is presently using the v4.1.2 TAG by default from the rcbops-cookbooks repo : (https://github.com/rcbops/chef-cookbooks). See the **Configuration Options** section on available options if you would like to try a different version of the Rackspace Private Cloud Software.

This script assumes you will have at least 2 networks installed on the AIO instance. **IE you should have setup eth0 and eth1.**. If you are not sure, run `ip a` to see what networks you have on your proposed AIO instance.


This script works with Ubuntu 12.04 and CentOS6/RHEL6
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


MINIMUM SYSTEM REQUIREMENTS
---------------------------

* Linux Operating System (*CentOS/RHEL or Ubuntu*)
* Dual Core Processor
* 2GB or RAM
* 10GB of Storage



OVERVIEW
--------

This script will install and configure the following:

* Openstack Controller
* Openstack Compute
* Horizon
* Cinder
* Nova-Network
* Cirros Image
* Fedora Image
* Ubuntu Image
* Qemu is used for the Virt Driver
* The Latest Stable Chef Server
* Chef Client
* Knife


NOTICE
------

This installation scrip has **ONLY** been tested on the following platforms:

* KVM
* Physical Server
* Rackspace Cloud Server
* Amazon AWS
* VMWare Fusion (*EXTRAS MUST BE INSTALLED*)


========


Configuration Options
~~~~~~~~~~~~~~~~~~~~~


The script has a bunch of override variables that can be set in script or as environment variables.


Set this to override the RCBOPS Developer Mode, DEFAULT is False:
  DEVELOPER_MODE=True or False

Set this to Enable or Disable Package Upgrades, DEFAULT is False
  DO_PACKAGE_UPGRADES=True or False
  
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

Set this to set the Neutron Interface, Only Set if you want to use Neutron
  NEUTRON_ENABLED=True or False

Set the Interface for Neutron
  NEUTRON_INTERFACE=""

Set the name of the Service
  NEUTRON_NAME="quantum or neutron"

Chef Server Override for Package URL
  CHEF_SERVER_PACKAGE_URL=""

Override the runlist with something different
  RUN_LIST=""

Disable roll back on Failure (NOTICE LETTER CASE)
  DISABLE_ROLL_BACK=true or false

========


Here is how you can get Started
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


1. Provision Server with a minimum of 2GB of ram and 10GB of hard disk space.
2. Login to server as root
3. Set any of your environment variables that you may want to use while running the script.
4. execute::

    curl https://raw.github.com/cloudnull/rcbops_allinone_inone/master/rcbops_allinone_inone.sh | bash

5. Go to the IP address of your server, login to Horizon, have fun with Openstack.


NOTICE: I WOULD NOT RECOMMEND USING THIS IN PRODUCTION!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


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

