Run Openstack all In One
########################
:date: 2013-09-05 09:51
:tags: rackspace, openstack, 
:category: \*nix

Run an RCBOPS All In One Deployment In One Server
=================================================

General Overview
----------------

This is a VERY simple script which will build you an environment based on the Rackspace Private Cloud Software.
This script is presently using the v4.1.0 TAG from the rcbops-cookbooks repo : (https://github.com/rcbops/chef-cookbooks).


As noted the script is simple and makes some assumptions for you. 


This script will install the following:

1. Openstack Controller
2. Openstack Compute
3. Horizon
4. Cinder
5. Cinder is built on a loop file
*. Nova-Network
*. ubuntu 12.04 LTS Image
*. cirros Image
*. Developer Mode is enabled
*. Quantum is NOT being used
*. Qemu is used for the Virt Driver
*. The Latest Stable Chef Server
*. Chef Client
*. Knife


I made this script such that you can stand up an Openstack environment in minutes and play with it.


I WOULD NOT RECOMMEND USING THIS IN PRODUCTION!
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Here is how you can use this right now. 

1. Login to server as root
2. execute::

    curl https://raw.github.com/cloudnull/rcbops_allinone_inone/master/rcbops_allinone_inone.sh | bash


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
