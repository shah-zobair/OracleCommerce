FROM tutum/centos:centos6

MAINTAINER Shah Zobair <szobair@redhat.com>


#######################################
#
# Creating necessary environment for Oracle Universal Installer
#
RUN groupadd oracle && mkdir /tmp/ora && chmod -R 777 /tmp/ora 
RUN echo 'inventory_loc=/tmp/ora' > /etc/oraInst.loc && echo 'inst_group=oracle' >> /etc/oraInst.loc


#######################################
#
# folders located outside the container to get necessary dependencies
#
ENV REMOTE_PACKAGES_PATH installables
ENV REMOTE_SCRIPTS_PATH scripts
ENV REMOTE_SUPPORTS_PATH support

# folders for copying dependencies into initially
ENV BASE_CONTAINER_TMP_PATH /tmp/endeca
ENV BASE_CONTAINER_PACKAGES_PATH $BASE_CONTAINER_TMP_PATH/packages

# folders for final installation of endeca programs
ENV BASE_INSTALL_PATH /apps/opt/weblogic
ENV BASE_ENDECA_PATH $BASE_INSTALL_PATH/endeca
ENV BASE_INSTALL_CUSTOM_SCRIPT_PATH $BASE_ENDECA_PATH/bin

#######################################
# install necessary OS packages
#RUN yum --disablerepo='*' --enablerepo=rhel-7-server-rpms install openssh-server openssh-clients epel-release wget nc pwgen which libaio glibc.i686 sudo tar unzip.x86_64 openssl hostname -y
RUN yum -y install openssh-server epel-release && \
    yum -y install openssh-clients && \
    yum -y install wget && \
    yum -y install nc && \
    yum -y install sudo && \
    yum -y install which && \
    yum -y install libaio && \
    yum -y install pwgen && \
    yum -y install glibc.i686 && \
    yum -y install unzip.x86_64 && \
    yum -y install tar

# Creating SSH Keys for endeca
RUN rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && \
    sed -i "s/UsePAM.*/UsePAM yes/g" /etc/ssh/sshd_config

#######################################
# create directories for copying initial endeca packages
RUN mkdir -p $BASE_CONTAINER_PACKAGES_PATH && chmod -R 777 $BASE_CONTAINER_TMP_PATH

# directory for final install of endeca
RUN mkdir -p $BASE_INSTALL_CUSTOM_SCRIPT_PATH
#RUN chmod 755 /opt/endeca/bin/*.sh

# Directory for CAS Appl
#RUN mkdir /appl && chmod -R 777 /appl

#######################################
# start copying across all endeca packages
#
# ACC OCACC11.1.bin
#ADD $REMOTE_PACKAGES_PATH/V45999-01.zip $BASE_CONTAINER_PACKAGES_PATH/V45986-01.zip

# P&S OCplatformservices11.1.0-Linux64.bin
ADD $REMOTE_PACKAGES_PATH/V45999-01.zip $BASE_CONTAINER_PACKAGES_PATH/V45999-01.zip

# MDEX OCmdex6.5.1-Linux64_829811.sh
ADD $REMOTE_PACKAGES_PATH/V46002-01.zip $BASE_CONTAINER_PACKAGES_PATH/V46002-01.zip

# Tools And Frameworks 
ADD $REMOTE_PACKAGES_PATH/V46389-01.zip $BASE_CONTAINER_PACKAGES_PATH/V46389-01.zip

# CAS OCcas11.1.0-Linux64.sh
ADD $REMOTE_PACKAGES_PATH/V46393-01.zip $BASE_CONTAINER_PACKAGES_PATH/V46393-01.zip

#######################################
# Copy script that creates unique password for root and other scripts
#
ADD $REMOTE_SCRIPTS_PATH/setupEndecaUser.sh $BASE_CONTAINER_TMP_PATH/setupEndecaUser.sh
RUN chmod +x $BASE_CONTAINER_TMP_PATH/setupEndecaUser.sh

#######################################
# Copy silent install scripts
#
ADD $REMOTE_SUPPORTS_PATH/platformservices-silent.txt $BASE_CONTAINER_TMP_PATH/platformservices-silent.txt

#######################################
#Run commands to create endeca user and modify sudoers
#
RUN $BASE_CONTAINER_TMP_PATH/setupEndecaUser.sh

#######################################
# Unzip all packages to get install scripts and files
#
#RUN unzip $BASE_CONTAINER_PACKAGES_PATH/V45986-01.zip -d $BASE_CONTAINER_TMP_PATH
RUN unzip $BASE_CONTAINER_PACKAGES_PATH/V45999-01.zip -d $BASE_CONTAINER_TMP_PATH
RUN unzip $BASE_CONTAINER_PACKAGES_PATH/V46002-01.zip -d $BASE_CONTAINER_TMP_PATH
RUN unzip $BASE_CONTAINER_PACKAGES_PATH/V46389-01.zip -d $BASE_CONTAINER_TMP_PATH
RUN unzip $BASE_CONTAINER_PACKAGES_PATH/V46393-01.zip -d $BASE_CONTAINER_TMP_PATH

#######################################
# Set scripts to be executable
RUN chmod +x $BASE_CONTAINER_TMP_PATH/*


#######################################
# Install mdex 6.5.1

RUN $BASE_CONTAINER_TMP_PATH/OCmdex6.5.1-Linux64_829811.sh --silent --target $BASE_INSTALL_PATH

RUN touch /home/endeca/.bashrc
RUN cat $BASE_INSTALL_PATH/endeca/MDEX/6.5.1/mdex_setup_sh.ini >> /home/endeca/.bashrc
RUN source /home/endeca/.bashrc

# Variables needed to install other applications.  List comes from previous mdex_setup_sh.ini script
#ENV ENDECA_MDEX_ROOT=/opt/endeca/endeca/MDEX/6.5.1

#######################################
# Install platform services
#
#OCplatformservices11.1.0-Linux64.bin
RUN $BASE_CONTAINER_TMP_PATH/OCplatformservices11.1.0-Linux64.bin --silent --target $BASE_INSTALL_PATH < $BASE_CONTAINER_TMP_PATH/platformservices-silent.txt

RUN cat $BASE_INSTALL_PATH/endeca/PlatformServices/workspace/setup/installer_sh.ini >> /home/endeca/.bashrc
#RUN source /home/endeca/.bashrc

#RUN cat $BASE_INSTALL_PATH/endeca/PlatformServices/workspace/setup/installer_sh.ini

# Variables needed to install other applications.  List comes from previous mdex_setup_sh.ini script
ENV VERSION=11.1.0
ENV BUILD_VERSION=11.1.0.842407
ENV ARCH_OS=x86_64pc-linux
ENV PRODUCT=IAP
#ENV ENDECA_INSTALL_BASE=/opt
ENV ENDECA_INSTALL_BASE=$BASE_ENDECA_PATH

#  Environment variables required to run the Endeca Platform Services software.
ENV ENDECA_ROOT=$BASE_ENDECA_PATH/PlatformServices/11.1.0
ENV PERLLIB=$ENDECA_ROOT/lib/perl:$ENDECA_ROOT/lib/perl/Control:$ENDECA_ROOT/perl/lib:$ENDECA_ROOT/perl/lib/site_perl:$PERLLIB
ENV PERL5LIB=$ENDECA_ROOT/lib/perl:$ENDECA_ROOT/lib/perl/Control:$ENDECA_ROOT/perl/lib:$ENDECA_ROOT/perl/lib/site_perl:$PERL5LIB
ENV ENDECA_CONF=$BASE_ENDECA_PATH/PlatformServices/workspace

#  ENDECA_REFERENCE_DIR points to the directory the reference implementations
#  are installed in.  It is not required to run any Oracle Commerce software.
ENV ENDECA_REFERENCE_DIR=$BASE_ENDECA_PATH/PlatformServices/reference

#######################################
# install Tools and Frameworks
#
# set prerequisite environment variables.
#ENV ENDECA_TOOLS_ROOT /usr/local/endeca/ToolsAndFrameworks/<version>
#ENV ENDECA_TOOLS_CONF /usr/local/endeca/ToolsAndFrameworks/<version>/server/workspace


ENV ENDECA_TOOLS_ROOT $BASE_INSTALL_PATH/endeca/ToolsAndFrameworks/11.1.0
ENV ENDECA_TOOLS_CONF $BASE_INSTALL_PATH/endeca/ToolsAndFrameworks/11.1.0/server/workspace

#Ensure that you have SWAP space on the running Node. Otherwise installation will fail
#RUN dd if=/dev/zero of=/swapfile bs=1M count=1024
#RUN mkswap /swapfile
#RUN chown root:root /swapfile
#RUN chmod 0600 /swapfile
#RUN swapon /swapfile
#RUN echo '/swapfile    swap    swap   defaults 0 0' >> /etc/fstab

#RUN free -m

#RUN chown -R endeca.endeca $ENDECA_INSTALL_BASE


#Tools And Frameworks install
RUN chmod -R 777 $BASE_INSTALL_PATH
USER endeca

RUN $BASE_CONTAINER_TMP_PATH/cd/Disk1/install/silent_install.sh $BASE_CONTAINER_TMP_PATH/cd/Disk1/install/silent_response.rsp ToolsAndFrameworks $BASE_INSTALL_PATH/endeca/ToolsAndFrameworks admin

#RUN $BASE_CONTAINER_TMP_PATH/cd/Disk1/install/silent_install.sh $BASE_CONTAINER_TMP_PATH/cd/Disk1/install/silent_response.rsp ToolsAndFrameworks-ets $BASE_INSTALL_PATH/ToolsAndFrameworks-ets2 admin
#RUN $BASE_CONTAINER_TMP_PATH/cd/Disk1/install/silent_install.sh $BASE_CONTAINER_TMP_PATH/cd/Disk1/install/silent_response.rsp -invPtrLoc /etc/oraInst.loc ToolsAndFrameworks $BASE_INSTALL_PATH/ToolsAndFrameworks admin

#######################################
# install CAS

ENV CAS_PORT 8500
ENV CAS_SHUTDOWN_PORT 8506
ENV CAS_HOST localhost

#create silent install text file
RUN echo $CAS_PORT > $BASE_CONTAINER_TMP_PATH/cas-silent.txt && \
    echo $CAS_SHUTDOWN_PORT >> $BASE_CONTAINER_TMP_PATH/cas-silent.txt && \
    echo $CAS_HOST >> $BASE_CONTAINER_TMP_PATH/cas-silent.txt

#CHANGE IP: text file used or silent install of platform services
#ADD tools/cas-silent.txt $BASE_CONTAINER_TMP_PATH/cas-silent.txt

RUN $BASE_CONTAINER_TMP_PATH/OCcas11.1.0-Linux64.sh --silent --target $BASE_INSTALL_PATH < $BASE_CONTAINER_TMP_PATH/cas-silent.txt



#############################################################################


#######################################
# create apps directory
#RUN mkdir /appl/endeca/apps
RUN mkdir $BASE_INSTALL_PATH/endeca/apps

#######################################
# set user and permissions to endeca
#RUN chown -R endeca.endeca /appl/endeca/

#######################################
# install is done start cleanup to remove initial packages
#RUN rm -rf /tmp/endeca
RUN rm -rf BASE_CONTAINER_TMP_PATH
##RUN rm setup*.sh

#RUN printenv

ENV AUTHORIZED_KEYS **None**

EXPOSE 22 8888 8500 8506 8006
USER root

ADD $REMOTE_SCRIPTS_PATH/start.sh /start.sh
RUN chmod 777 /start.sh
RUN /start.sh
RUN sed -i s/^exec.*//g run.sh /run.sh
RUN echo '/apps/opt/weblogic/endeca/PlatformServices/11.1.0/tools/server/bin/startup.sh &' >> /run.sh
RUN echo '/apps/opt/weblogic/endeca/ToolsAndFrameworks/11.1.0/server/bin/startup.sh &' >> /run.sh
RUN echo 'exec /usr/sbin/sshd -D' >> /run.sh

CMD ["/run.sh"]
