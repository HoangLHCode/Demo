#!/bin/bash
# Usage: bash create-high-availability-vm-with-sets.sh hoang812-test-rg

RgName=$1

date
# Create a Virtual Network for the VMs
echo '------------------------------------------'
echo 'Creating a Virtual Network for the VMs'
az network vnet create \
    --resource-group hoang812-test-rg \
    --name hoang812-PortalVnet \
    --subnet-name hoang812-PortalSubnet 

# Create a Network Security Group
echo '------------------------------------------'
echo 'Creating a Network Security Group'
az network nsg create \
    --resource-group hoang812-test-rg \
    --name hoang812-PortalNSG 
# Create a network security group rule for port 22.
echo '------------------------------------------'
echo 'Creating a SSH rule'
az network nsg rule create \
    --resource-group hoang812-test-rg \
    --nsg-name hoang812-PortalNSG \
    --name hoang812-NetworkSecurityGroupRuleSSH \
    --protocol tcp \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*'  \
    --destination-address-prefix '*' \
    --destination-port-range 22 \
    --access allow \
    --priority 1000

# Add inbound rule on port 80
echo '------------------------------------------'
echo 'Allowing access on port 80'
az network nsg rule create \
    --resource-group hoang812-test-rg \
    --nsg-name hoang812-PortalNSG \
    --name Allow-80-Inbound \
    --priority 200 \
    --source-address-prefixes '*' \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 80 \
    --access Allow \
    --protocol Tcp \
    --direction Inbound \
    --description "Allow inbound on port 80."
    
# Create the NIC
for i in `seq 1 3`; do
  echo '------------------------------------------'
  echo 'Creating hoang812-webNic'$i
  az network nic create \
    --resource-group hoang812-test-rg \
    --name hoang812-webNic$i \
    --vnet-name hoang812-PortalVnet \
    --subnet hoang812-PortalSubnet \
    --network-security-group hoang812-PortalNSG
done 

# Create an availability set
echo '------------------------------------------'
echo 'Creating an availability set'
az vm availability-set create -n hoang812-portalAvailabilitySet -g hoang812-test-rg

# Create 3 VM's from a template
for i in `seq 1 3`; do
    echo '------------------------------------------'
    echo 'Creating hoang812-webVM'$i
    az vm create \
        --admin-username hoanglh \
        --admin-password Admin123456789@ \
        --resource-group hoanglh-test-rg \
        --name hoang812-webVM$i \
        --nics hoang812-webNic$i \
        --image win2019datacenter \
        --availability-set hoang812-portalAvailabilitySet \
        --generate-ssh-keys \
        --custom-data cloud-init.txt
done

# Done
echo '--------------------------------------------------------'
echo '             VM Setup Script Completed'
echo '--------------------------------------------------------'
