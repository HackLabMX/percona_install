#!/bin/bash
#====================================================================#
#  MagenX                                                            #
#  PERCONA DATABASE INSTALLATION                                     #
#  admin@magenx.com                                                  #
#====================================================================#
# Simple colors
RED="\e[31;40m"
GREEN="\e[32;40m"
YELLOW="\e[33;40m"
WHITE="\e[37;40m"
BLUE="\e[0;34m"
# Background
DGREYBG="\t\t\e[100m"
BLUEBG="\e[44m"
REDBG="\t\t\e[41m"
# Styles
BOLD="\e[1m"
# Reset
RESET="\e[0m"
# quick-n-dirty settings
function WHITETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${WHITE}${MESSAGE}${RESET}"
}
function BLUETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${BLUE}${MESSAGE}${RESET}"
}
function REDTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${RED}${MESSAGE}${RESET}"
} 
function GREENTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${GREEN}${MESSAGE}${RESET}"
}
function YELLOWTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${YELLOW}${MESSAGE}${RESET}"
}
function BLUEBG() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${BLUEBG}${MESSAGE}${RESET}"
}
clear
echo
# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "------> ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
  REDTXT "------> USE SUPER-USER PRIVILEGES."
  exit 1
  else
  GREENTXT "------> PASS: ROOT!"
fi
# do we have CentOS?
if [ -f /etc/redhat-release ]; then
  GREENTXT "------> PASS: CENTOS RELEASE"
  else
  echo
  REDTXT "------> ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  REDTXT "------> THIS CONFIGURATION FOR CENTOS"
  echo
  exit 1
fi
# check if memory is enough
TOTALMEM=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
if [ "${TOTALMEM}" -gt "3000000" ]; then
  GREENTXT "------> PASS: YOU HAVE ${TOTALMEM} kB OF RAM"
  else
  REDTXT "------> WARNING: YOU HAVE LESS THAN 3GB OF RAM"
fi
# some selinux, sir?
SELINUX=$(awk '/^SELINUX=/'  /etc/selinux/config)
if [ "${SELINUX}" != "SELINUX=disabled" ]; then
  echo
  REDTXT "------> ERROR: SELINUX IS ENABLED"
  REDTXT "------> PLEASE CHECK YOUR SELINUX SETTINGS"
  echo
  exit 1
  else
  GREENTXT "------> PASS: SELINUX IS DISABLED"
fi
# network is up?
host1=74.125.24.106
host2=208.80.154.225
RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "------> PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  echo
  REDTXT "------> ERROR: NETWORK IS DOWN?"
  REDTXT "------> PLEASE CHECK YOUR NETWORK SETTINGS."
  echo
  echo
  exit 1
fi
echo
echo
echo "============================================================================="
echo
echo -n "---> START PERCONA REPOSITORY AND PERCONA DATABASE INSTALLATION? [y/n][n]:"
read repo_percona_install
if [ "${repo_percona_install}" == "y" ];then
  echo
  yum -q -y install bc wget > /dev/null 2>&1
  YELLOWTXT "---> INSTALLATION OF PERCONA REPOSITORY:"
  echo
  echo -n "---> IS THIS SERVER DEDICATED FOR DATABASE ONLY?  [y/n][y]:"
    read dedicated
    if [ "${dedicated}" == "y" ];then
       DEDICATED="0.8"
       else
       DEDICATED="0.5"
     fi
       rpm -Uvh http://www.percona.com/redir/downloads/percona-release/redhat/latest/percona-release-0.1-3.noarch.rpm
       rpm -q percona-release
     if [ "$?" = 0 ] # if repository installed then install package
        then
          echo
            GREENTXT "---> REPOSITORY HAS BEEN INSTALLED  -  OK"
              echo
              echo
              YELLOWTXT "---> INSTALLATION OF PERCONA 5.6 DATABASE:"
              echo
              yum -y install Percona-Server-client-56 Percona-Server-server-56
              rpm -q Percona-Server-client-56 Percona-Server-server-56
        if [ "$?" = 0 ] # if package installed then configure
          then
            echo
              GREENTXT "---> PERCONA DATABASE HAS BEEN INSTALLED  -  OK"
              echo
              chkconfig mysql on
              echo
              WHITETXT "---> DOWNLOADING my.cnf FILE FROM MAGENX GITHUB REPOSITORY"
              wget -qO /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
              echo
                echo
                 YELLOWTXT "---> WE NEED TO CORRECT YOUR innodb_buffer_pool_size"
                 IBPS=$(echo "${DEDICATED}*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
                 sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${IBPS}G/" /etc/my.cnf
                 echo
                 WHITETXT "---> YOUR innodb_buffer_pool_size = ${YELLOW} ${IBPS}G"
                echo
              echo
              MYSQL_ROOT_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9~!@$%&'  | fold -w 15 | head -n 1)
              BLUETXT "#############################################################"
              YELLOWTXT "---> Generated MySQL root password: ${RED} ${MYSQL_ROOT_PASSGEN} "
              YELLOWTXT "---> KEEP IT SAFE!"
              BLUETXT "#############################################################"
              echo
                echo
                mysql_secure_installation
                echo
              echo
              wget -qO /etc/mysqltuner.pl https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl
              chmod +x /etc/mysqltuner.pl
              echo
              YELLOWTXT "---> PLEASE USE THIS SCRIPT TO CHECK AND FINETUNE YOUR DATABASE:"
              echo "perl /etc/mysqltuner.pl"
              echo
                else
                  echo
                  REDTXT "---> DATABASE INSTALLATION ERROR"
          exit # if package is not installed then exit
        fi
          else
            echo
            REDTXT "---> REPOSITORY INSTALLATION ERROR"
        exit # if repository is not installed then exit
      fi
        else
          echo
          REDTXT "---> PERCONA REPOSITORY INSTALLATION WAS ABORTED"
fi
exit
