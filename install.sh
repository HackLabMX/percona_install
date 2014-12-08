#!/bin/bash
#====================================================================#
#  MagenX                                                            #
#  PERCONA DATABASE INSTALLATION                                      #
#  admin@magenx.com                                                  #
#====================================================================#
clear
echo
# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  echo "ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
  echo "------> USE SUPER-USER PRIVILEGES."
  exit 1
  else
  echo "PASS: ROOT!"
fi
# do we have CentOS 6?
if grep "CentOS Linux release 6" /etc/redhat-release  > /dev/null 2>&1; then
  echo "PASS: CENTOS RELEASE 6"
  else
  echo
  echo "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  echo "------> THIS CONFIGURATION FOR CENTOS 6."
  echo
  exit 1
fi
echo
echo
echo
echo "============================================================================="
echo
echo -n "---> START PERCONA REPOSITORY AND PERCONA DATABASE INSTALLATION? [y/n][n]:"
read repo_percona_install
if [ "${repo_percona_install}" == "y" ];then
  echo
  echo "---> INSTALLATION OF PERCONA REPOSITORY:"
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
            echo "---> REPOSITORY HAS BEEN INSTALLED  -  OK"
              echo
              echo
              echo "---> INSTALLATION OF PERCONA 5.6 DATABASE:"
              echo
              yum -y install Percona-Server-client-56 Percona-Server-server-56
              rpm -q Percona-Server-client-56 Percona-Server-server-56
        if [ "$?" = 0 ] # if package installed then configure
          then
            echo
              echo "---> PERCONA DATABASE HAS BEEN INSTALLED  -  OK"
              echo
              chkconfig mysql on
              echo
              echo "---> DOWNLOADING my.cnf FILE FROM MAGENX GITHUB REPOSITORY"
              wget -qO /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
              echo
                #######################################################################################################################################
                echo
                 echo "---> WE NEED TO CORRECT YOUR innodb_buffer_pool_size"
                 IBPS=$(echo "${DEDICATED}*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
                 sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${IBPS}G/" /etc/my.cnf
                 echo
                 echo "---> YOUR innodb_buffer_pool_size = ${IBPS}G"
                echo
                #######################################################################################################################################
              echo
              MYSQL_ROOT_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9~!@$%&'  | fold -w 15 | head -n 1)
              echo "######################################################"
              echo "---> Generated MySQL root password: ${MYSQL_ROOT_PASSGEN} "
              echo "---> KEEP IT SAFE!"
              echo "######################################################"
              echo
                echo
                mysql_secure_installation
                echo
              echo
              wget -qO /etc/mysqltuner.pl https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl
              chmod +x /etc/mysqltuner.pl
              echo
              echo "---> PLEASE USE THIS SCRIPT TO CHECK AND FINETUNE YOUR DATABASE:"
              echo "perl /etc/mysqltuner.pl"
              echo
                else
                  echo
                  echo "---> DATABASE INSTALLATION ERROR"
          exit # if package is not installed then exit
        fi
          else
            echo
            echo "---> REPOSITORY INSTALLATION ERROR"
        exit # if repository is not installed then exit
      fi
        else
          echo
          echo "---> PERCONA REPOSITORY INSTALLATION WAS ABORTED"
fi
exit
