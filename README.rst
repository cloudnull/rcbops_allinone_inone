RCBOPS Stack in a BOX
#####################
:date: 2013-11-06 09:51
:tags: rackspace, openstack, private cloud, development, chef, cookbooks
:category: \*nix


So you want to try Openstack?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Want to build a cloud? Want to try Openstack? Curious how the Openstack Cloud ecosystem all works? In the past you, the cloud operator, had to have a lot of tribal knowledge to simply stand Openstack up. In later releases, Openstack became more robust and better documented, but the process to build all of the components of Openstack into a working system was still arduous. Today the general community is vibrant with eager people who want to help spread the goodness of Openstack around, and we have a myriad of methods for installing Openstack and consuming the fruits of the communal labor.


Cloud as an Instance!
^^^^^^^^^^^^^^^^^^^^^

The Openstack cloud has grown to encompass some amazing projects. These projects allow for authentication, imaging, orchestration, monitoring, and many more. If you were curious how all this works together, you'd have a few ready made options. One is Devstack, another is PackStack, and then there is this one. As you are reading you may think to yourself, what method is this one? The method for deployment I have alluded to is an "AIO" installation, which is simply a scripted "All In One" install. The deployment script builds Openstack and all of its core services into a single server and then allows you, the user, to play with the services. With the script, you can have a ready made Openstack testing node in about 7 minutes (1). The script is easy to understand and hack on but allows for a robust deployment of Openstack. The real mustard behind this single script is the Open Source Chef cookbooks project produced by the Rackspace Private Cloud Development Team (2). The cookbooks serve as the basis for the deployment mechanism, but the script allows all of the bits to come together and work seamlessly.


Getting Cloudy
^^^^^^^^^^^^^^

To begin using the script you have have to have a Linux operating system available to you with a 15GB Hard disk and 2GB or RAM. Your Linux operating system must be either Ubuntu 12.04 or CentOS/RHEL 6. I mention these OS restrictions because I have not tested anything other than these two Operating Systems.

* If you are using CentOS/RHEL you are going to need to upgrade your Kernel to the RDO Kernel which is provided by RedHat. While this Kernel is not required in ALL circumstances, I am not going to cover what those circumstances are and I'm simply going to say that you have to have the RDO kernel in place for CentOS/RHEL boxes. For instructions on how to install the RDO Kernel please go to the `RDO Kernel Install`_ section of this doc and read it.
* When using Ubuntu the stock 3.2 Kernel works out of the box but it may be wise to upgrade to the 3.8 kernel as it's a better code base and has better support for Neutron networking and some hypervisors such as LXC and Docker.  To upgrade to the 3.8 Kernel in Ubuntu please go to the `Raring Kernel in Precise`_ section of this doc and read it.

I have tested this installation on Rackspace Public Cloud, HP Cloud, VMFusion 6, Virtual Box 4.3.x, Amazon Ubuntu 12.04 AMI, Parallels Desktop, and KVM.


Once your Ubuntu or CentOS/RHEL box is up and running, you now have to get the script and execute it on your system.


Execute the script::

    wget https://github.com/cloudnull/rcbops_allinone_inone/raw/master/rcbops_allinone_inone.sh
    bash rcbops_allinone_inone.sh
  

Now simply sit back and enjoy my hard work and watch cloud cook. In about 7 minutes (1) you will have a functional Openstack Cloud.


But Wait There's More!
^^^^^^^^^^^^^^^^^^^^^^

In true nerd fashion, I could not simply create a one size fits all deployment system which was not flexible enough to do interesting things with, and I would never build an application which had a single purpose and could be out moded so easily. I go full retard on all my projects, and this is no exception.  The script has a whole bunch of options which allow you, the cloud builder, the ability to specify and or consume different aspects of the cloud.  In my github repo found here::

  https://github.com/cloudnull/rcbops_allinone_inone

I created several "RC" files which have been built as examples for configuring the "All In One In One" installer.  These "RC" files allow you to create an Openstack cloud installing neutron, heat, ceiolmeter or all of the above. They also allow you to take control of the installation such that you can specify the virtualization type, network interfaces, CIDRs, run lists, what images will be installed by default and more. In truth, using this script allows you to build a fairly robust system out of the box.


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

Enable or Disable the auto creation of neutron networks
  NEUTRON_CREATE_NETWORKS=True || False

Set the Interface for Neutron
  NEUTRON_INTERFACE=""

Set the name of the Service
  NEUTRON_NAME="quantum or neutron"

Enable Load Balancer as a Service
  LBAAS_ENABLED=True or False

Enable VPN as a Service
  VPNAAS_ENABLED=True or False

Enable Firewall as a Service
  FWAAS_ENABLED=True or False

Chef Server Override for Package URL
  CHEF_SERVER_PACKAGE_URL=""

Override the runlist with something different
  RUN_LIST=""

Disable roll back on Failure (NOTICE LETTER CASE)
  DISABLE_ROLL_BACK=true or false

Default Images True||False, DEFAULT is False
  FEDORA_IMAGE=False

  UBUNTU_IMAGE=False

  CIRROS_IMAGE=False

If these are not set, the script will attempt to determine the cidr of the interface or 127.0.0.0/24 will be used. **Setting these overrides the interface variables**.
  MANAGEMENT_INTERFACE_CIDR="Network Cidr"

  NOVA_INTERFACE_CIDR="Network Cidr"

  PUBLIC_INTERFACE_CIDR="Network Cidr"

This is used for Testing Cookbooks. If you want to use a non-stock cookbook you can specify them in this variable. The format is "name=branch=url" This is a space seperated list.
  TESTING_COOKBOOKS="name=branch=url"


Another Word about the available Options
----------------------------------------

The script has been built to accept Environment Varibales as methods of input as well as direct input by editing the script. All of the options can be found in the top of the script and are well documented. But if you dont feel like editing the script every time you want to deploy a new box you can simply export the options you want into an environment variable and the script will read it as direct input. As previously mentioned, I have built a couple sample "RC" which can be directly executed or sourced prior to running the script.

Example:
  If you wanted to run the master branch of the Rackspace Private Cloud Software, wanted to use Neutron, and were happy with the options I use, here's how you could go about the installation.

  Get the repo from github::

    git clone https://github.com/cloudnull/rcbops_allinone_inone


  Now change your directory to `rcbops_allinone_inone`::

    cd rcbops_allinone_inone


  Finally `source` the `master_neutron_dev.rc` file::

    source master_neutron_dev.rc

  Once you have sourced the file, all of the exports being set in the source file will be made available to your local shell and you are ready to install::

    bash rcbops_allinone_inone.sh


While this example is working as of **TODAY**, I make no guarantees that the "Master" branch of the cookbooks will work tomorrow, or that the options wont need some adjusting for your environment. This configuration is simply an example and I encourage you to make your own configuration files. Having prebuilt configuration "RC" files assist you in not only standing up Openstack but also allowing you to be lazy when deploying new test Nodes.  If you do make your own "RC" files I would love to see them and add them to this repo. So pull requests are always welcome.


========


*RDO Kernel Install*
--------------------

Decide if you are going to use the Havana or Grizzly version of Openstack and then run the following.

If Havana::

   sudo yum install -y http://rdo.fedorapeople.org/openstack-havana/rdo-release-havana.rpm


If Grizzly::

  sudo yum install -y http://rdo.fedorapeople.org/openstack-grizzly/rdo-release-grizzly.rpm


Once the REPO is installed run::

  yum -y update


Reboot the System::

  reboot


*Raring Kernel in Precise*
--------------------------

Update your Repositories::

  sudo apt-get update


Install the new Kernel Image and headers::

  sudo apt-get install linux-image-generic-lts-raring linux-headers-generic-lts-raring


Reboot the System::

  sudo reboot


========


NOTES
~~~~~

* This script was create to allow for rapid deployment of a testing node based on the Rackspace Private Cloud Chef Cookbooks.
* This script is presently using the v4.1.2 TAG by default from the rcbops-cookbooks repo : (https://github.com/rcbops/chef-cookbooks). See the Configuration Options section on available options if you would like to try a different version of the Rackspace Private Cloud Software.
* This script assumes you will have at least 2 networks installed on the Target Instance. You should have setup eth0 and eth1 when provisioning your operating system. If you are not sure, run `ip a` to see what networks and interfaces you have on your proposed AIO instance.
* If you are using Neutron/Quantum in your installation, You will need a minimum of 2 Network Interfaces.
* If you use the v4.1.2 tag for your installation and would like to use Openstack Networking, the name of the project is "quantum" and you will need to `export NEUTRON_NAME="quantum"` to change the name in the installation script.
* Neutron Installation has only ever been tested on the master branch of the cookbooks which is the development branch for v4.2.x of the Rackspace Private Cloud Software.


Foot Notes
~~~~~~~~~~

1) The 7 minute installation was done on a Rackspace using a Flavor Size of 6 or greater. This is the installation time after the Operating System is already available. The build process used for the time only includes, Keystone, Nova, Glance, Cinder, and Horizon.  The recorded time for installing Ceilometer, Heat, and Neutron on the same sized Cloud Server was 15 minutes.

2) I work for Rackspace on the Rackspace Private Cloud Team and am a member of the development group responsible for the Chef cookbooks used in this installation process. While I am a Racker and this Installation script uses The Rackspace Private Cloud Software I have contributed to this installation process and procedure is not an official installation process. I built this installation process for myself and have on my own decided to share it with the world.  By no means does this installation application contain proprietary data and or access to anything which may be considered proprietary.



I WOULD NOT RECOMMEND USING THIS IN PRODUCTION!
-----------------------------------------------


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

