#!/bin/bash
##
# SCRIPT: add_member_to_domain.sh
#
# AUTOR: Elismar Luz, feluz@stefanini.com
# DATE: 11-2016
#
# PURPOSE: Install the realm package and add the server to a domain
#
# set -x # Uncomment to debug this script
# set -n # Uncomment to check command syntax without any execution
#
############################## VARIABLES ##############################
# Colors for joy on the black screen
Error=`tput setaf 1`
Success=`tput setaf 2`
Info=`tput setaf 6`
rst=`tput sgr0`

shortname=$(hostname -s)
fullname=$(hostname)

# Parameters for configuring system access
group_login='users_ssh'       # User group that can log in to the host
group_ssh='users_ssh'         # Group of users who can log in via ssh on the host
group_sudo='users_ssh_admin'  # Group of users who can use the sudo command

domain_name="cia.stefanini.local"
domain_realm="CIA.STEFANINI.LOCAL"
#----------------------------------------------------------------------

############################### FUNCTIONS ###############################

# realmd installation function.
function install_realm {
  clear
  # Checks if sudo is not installed
  if ! rpm -q sudo &> /dev/null; then
    echo ${Error}"sudo is required to continue this operation"${rst}
    exit
  fi

  # Verify that you have realm installed
  if  rpm -q realmd &> /dev/null; then
    echo "${Info} [INFO] ${rst}You already have the package ${Success}$(rpm -q realmd)${rst} installed"
  else
    echo "${Info}Installing the realm package${rst}"
    sudo yum install -qy realmd &> /dev/null
      if [ $? -eq 0 ]; then
        echo ""
        echo "${Success} [ OK ]  $(rpm -q realmd)${rst} has been installed!"
      else
        echo "${Error} [ERROR] ${rst}Problem with realm installation, leaving..."
        exit
      fi
  fi

  # Install required packages
  required_package=$(sudo realm discover $domain_name | grep required-package| awk '{print $2}')
  echo ""
  echo "${Info}Packages required by realm: ${rst}"
    for app in $required_package
      do
        if ! rpm -q $app &> /dev/null; then # <- checks if the package has not been installed.
          sudo yum install -qy $app &> /dev/null
            if [ $? -eq 0 ]; then
              echo "${Success} [ OK ]${rst} $(rpm -q $app) has been installed."
            else
              echo "${Error} [ERROR]${rst} $(rpm -q $app) was not installed."
            fi
          else
            echo "${Info} [INFO] ${rst}${Success} $(rpm -q $app)${rst} was already installed."
          fi
      done
  echo ""
}
#----------------------------------------------------------------------

# Function to add the server to the domain
function add_to_domain{
  echo ""
  echo "We will add${Info}$shortname${rst} in domain ${Info}$domain_realm${rst}"
  read -p 'User: ' domain_user
  sudo realm join $domain_name --user $domain_user
    if [ $? -eq 0 ]; then
      echo "${Success} [ OK ] ${rst}The ${Info}$shortname${rst} a was added to the domain $domain_realm"
    else
      echo "${Error} [ERROR]${rst} Problems..."
      exit
    fi
}
#----------------------------------------------------------------------

# Function to configure settings: files, sudo, ssh
function configure_system {
  if ! grep "simple_allow_groups = users_ssh@cia.stefanini.local" /etc/sssd/sssd.conf &> /dev/null; then
  realm permit -g $group_ssh@$domain_name
  echo "${Success} [ OK ]${rst}We allow users in the $group_ssh, login to this server."
  fi
}
#----------------------------------------------------------------------

# Function to record the operation
function record_operation {
  echo ""
}
# ---------------------------------------------------------------------

# Install the realm, if the installation is successful,
# Install the packages required by it,
# Add the server to the domain
# Make final settings: ssh, sudo, sssd etc...
# Logging operation.

install_realm && add_to_domain && configure_system && record_operation
