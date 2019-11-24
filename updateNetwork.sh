#!/bin/bash
# Script to move all VM NICs from one network to another (online and preserving MAC addresses)
# Author: Jirah Cox @Nutanix
# With appreciation to Magnus and Arthur's script located at: https://github.com/magander3/misc/blob/master/AHV-VM-change_virtual_nic.sh
#
# Version 1.0 - Initial release

clear
echo "            _    ___      __"
echo "      /\   | |  | \ \    / /"
echo "     /  \  | |__| |\ \  / / "
echo "    / /\ \ |  __  | \ \/ /  "
echo "   / ____ \| |  | |  \  /   "
echo "  /_/    \_\_|  |_|   \/    "
echo

####
# Determine source network and then display confirmation
####

echo "#####"
echo "Choose Source Network"
echo "#####"

echo
read -ep "List available networks? y/n: " "list"
if [ $list == "N" ] || [ $list == "n" ]
	then
		echo
		read -ep "Enter the Virtual Network name to migrate (case sensitive): " "oldvmnet"
	else
                echo
		echo "This cluster has the following networks:"
		echo
		/usr/local/nutanix/bin/acli net.list | awk  -F'[a-zA-Z0-9]+-[a-zA-Z0-9]+-[a-zA-Z0-9]+-[a-zA-Z0-9]+-[a-zA-Z0-9]' '{print $1}' | sed -n '1!p'
		echo
		read -ep "Enter the Virtual Network name to migrate (case sensitive): " "oldvmnet"
	fi

echo
echo "These VM(s) are currently on that network and their NIC(s) and associated MAC address will be changed:"
echo
/usr/local/nutanix/bin/acli net.list_vms $oldvmnet
# Capture VM UUIDs to act on
vmuuidstomove=`acli net.list_vms $oldvmnet | awk -F' {2,}' 'NR-1 {print $1}'`
echo

####
# Determine target network and then display confirmation
####

echo "#####"
echo "Choose Target Network"
echo "#####"

echo
read -ep "List available networks? y/n: " "list"
if [ $list == "N" ] || [ $list == "n" ]
	then
		echo
		read -ep "Enter the new Virtual Network name to move to (case sensitive): " "newvmnet"
	else
                echo
		echo "This cluster has the following networks:"
		echo
		/usr/local/nutanix/bin/acli net.list | awk  -F'[a-zA-Z0-9]+-[a-zA-Z0-9]+-[a-zA-Z0-9]+-[a-zA-Z0-9]+-[a-zA-Z0-9]' '{print $1}' | sed -n '1!p'
		echo
		read -ep "Enter the new Virtual Network name to move to (case sensitive): " "newvmnet"
	fi

echo
read -ep "Final confirmation - move all VM NICs from ** $oldvmnet ** to ** $newvmnet ** ?: y/n " "confirmmove"
if [ $confirmmove == "Y" ] || [ $confirmmove == "y" ]
	then
		echo "Moving VM NICs"
		for uuid in $vmuuidstomove; do
			# Null out some variables to make sure they're fresh for each loop
			loopvmname=0
			loopmacaddress=0
			# Find the name of the VM in question since vm.nic_update wants a VM name to act on
			loopvmname=`/usr/local/nutanix/bin/acli vm.list | grep $uuid | awk -F' {2,}' '{print $1}'`
			# Find the first MAC address (if multiple) of the VM in question on the network in question
			loopmacaddress=`/usr/local/nutanix/bin/acli net.list_vms $oldvmnet | grep $loopvmname -m 1 | awk '{ print $3}'`
			# Perform the NIC update
			echo "Moving VM $loopvmname with MAC address $loopmacaddress"
			/usr/local/nutanix/bin/acli vm.nic_update $loopvmname $loopmacaddress network=$newvmnet
		done
	else
		echo
		echo "Script cancelled - no action taken"
		echo
	fi
