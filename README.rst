RCBOPS All In One In One
########################
:date: 2013-09-05 09:51
:tags: rackspace, openstack, 
:category: \*nix

Run an RCBOPS All In One Deployment In One
==========================================

General Overview
----------------

This is a VERY simple script which will build you an environment based on the Rackspace Private Cloud Software.
This script is presently using the v4.1.0 TAG from the rcbops-cookbooks repo : (https://github.com/rcbops/chef-cookbooks).


As noted the script is simple and makes some assumptions for you. 


Chiefly: 
  * Developer Mode is enabled
  * Quantum is being used
  * Images Cirros / Ubuntu 12.04 are installed
  * Qemu is used for Virt Driver.


I made this script such that you can stand up an Openstack environment in minutes and play with it.


I WOULD NOT RECOMMEND USING THIS IN PRODUCTION!
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
