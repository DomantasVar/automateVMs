#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

#This function is called either after VM is successfully created or process fails and it unmounts partitions which have been mounted in the process. 
cleanup()
{
	echo_string_white "Cleaning up.. Unmounting media.."
	if /bin/grep -qs /mnt/proc /proc/mounts; then
		/bin/umount /mnt/proc
	fi
	if /bin/grep -qs /mnt/dev /proc/mounts; then
		/bin/umount /mnt/dev
	fi
	if /bin/grep -qs /mnt/sys /proc/mounts; then
		/bin/umount /mnt/sys
	fi
	if /bin/grep -qs /mnt /proc/mounts; then
		/bin/umount /mnt
	fi
		/sbin/losetup -d $DEVICE
}

#Control function which is invoked after every step which could have failed
check_exit_status() 
{
	if [ $? -eq 0 ]; then
		echo_string_green "Success. Proceeding."
	else
		echo_string_red "Failed. Exiting."
		if [[ $DISKSMOUNTED == 1 ]]; then
			cleanup
		fi		
		exit 1
	fi
}

#function gets a string and array as arguments and checks if a string is a part of array
validate_options()
{
local e
  for e in "${@:3}"; do 
	if [[ "$e" == "$1" ]];then 
	return 0;
	fi 
  done
  echo_string_red "Unrecognized option $1 in $2"
  exit 1
}

#Function to validate IP addresses. 
validate_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local OIFS=$IFS
        local IFS='.'
        local ip=($ip)
        local IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

#Checks if path is a directory
validate_dir()
{
	if [[ ! -d $1 ]]; then
   	echo_string_red "$1 - directory not found"
   	exit 1
	fi
}

#Printing text in different colors
echo_string_red()
{
	echo -e "\033[0;31m${bold}$1${normal}\033[0m"
}

echo_string_green()
{
	echo -e "\033[0;32m${bold}$1${normal}\033[0m"
}

echo_string_white()
{
	echo -e "${bold}$1${normal}"
}

#Validating arguments
if [ $# -gt 1 ]; then
	echo_string_white "Author: Domantas Varapnickas (domantas.varapnickas@mif.stud.vu.lt)"
	echo_string_white " "
	echo_string_white " "
	echo_string_white "This script creates creates VirtualBox VM in fully automated manner."
	echo_string_white "Usage: $0 <path to configuration file>"
	exit 1
fi

echo_string_white "Importing variables.."
	source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/global_variables.cfg
	check_exit_status



echo_string_white "Importing configuration file.."
	if [ $# == 1 ]; then
		source $1
		check_exit_status
	else
		echo_string_red "Usage: $0 <path to configuration file>"
	fi


echo_string_white "Validating directories.."
	if [ "$FILEPATH" == "" ]; then 
		$FILEPATH == $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	fi
	if [ "$BASEFOLDER" == "" ]; then 
		$BASEFOLDER == $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	fi

echo_string_white "Validating filepath.."	
	validate_dir "$FILEPATH"
	check_exit_status

echo_string_white "Validating basefolder.."
	validate_dir "$BASEFOLDER"
	check_exit_status

if [ $INSTALLOPTION == DIR ]; then 
	validate_dir $RESOURCE
fi

echo_string_white "Setting additional variables.."
	RAWIMAGE="${FILEPATH}"${FILENAME}.img
	VDIIMAGE="${FILEPATH}"${FILENAME}.vdi
	DISKSMOUNTED=0

echo_string_white "Validating variables.."
#USERNAME,INSTALLOPTION,DISTRIBUTION,ARCH,OSTYPE
INSTALLOPTION_ARRAY=(DIR URL);
validate_options $INSTALLOPTION INSTALLOPTION "${INSTALLOPTION_ARRAY[@]}"
DISTRIBUTION_ARRAY=(xenial trusty precise wily jessie wheezy squeeze lenny)
validate_options $DISTRIBUTION DISTRIBUTION "${DISTRIBUTION_ARRAY[@]}"
ARCH_ARRAY=(amd64 i386);
validate_options $ARCH ARCH "${ARCH_ARRAY[@]}"
OSTYPE_ARRAY=(Debian_64 Debian_32 Ubuntu_64 Ubuntu_32)
validate_options $OSTYPE OSTYPE "${OSTYPE_ARRAY[@]}"

echo_string_white "Checking SSH public key.."
if [ -z "$SSH_PUBLIC_KEY" ]; then
	echo_string_red "Missing host's SSH public key. Will not proceed without it!"
	exit 1
fi
check_exit_status

echo_string_white "Creating disk image..."
	/bin/dd if=/dev/zero of="$RAWIMAGE" bs=1024 count=1 seek=10239k
	check_exit_status

echo_string_white "Partitioning disk.."
	echo $(sudo /sbin/parted -s "$RAWIMAGE" -- mklabel msdos mkpart primary 1m 10g toggle 1 boot)
	check_exit_status
#creates md-dos label (most common)
#primary partition
#set boot flag on 

echo_string_white "Setting up virtual disk as block device.."
	DEVICE=$(sudo /sbin/losetup --show -f "$RAWIMAGE")
	check_exit_status
	echo_string_green "$DEVICE was set up."

echo_string_white "Rereading partition table.."
	/sbin/partprobe $DEVICE
	check_exit_status

echo_string_white "Creating ext4 file system.."
	mkfs.ext4 -F ${DEVICE}p1 
	check_exit_status 

echo_string_white "Mounting ${DEVICE}p1 on /mnt.."
	mount ${DEVICE}p1 /mnt
	check_exit_status

#python and ssh-server required for ansible to work
PACKETS_TO_INSTALL="grub-pc,openssh-server,python2.7,wget,curl"
if [ ! ADDITIONAL_PACKETS == "" ]; then
	PACKETS_TO_INSTALL=${PACKETS_TO_INSTALL},${ADDITIONAL_PACKETS}
fi

if [[ $RESOURCE == *"debian"* ]]; then
 	PACKETS_TO_INSTALL=${PACKETS_TO_INSTALL},linux-image-amd64,sudo,rsync
fi

if [[ $RESOURCE == *"ubuntu"* ]]; then
 	PACKETS_TO_INSTALL=${PACKETS_TO_INSTALL},linux-image-generic
fi

if [[ $ROLE == "MASTER" ]]; then
 	PACKETS_TO_INSTALL=${PACKETS_TO_INSTALL},make,python-dev,gcc,build-essential,libssl-dev,libffi-dev
elif [[ $ROLE == "CLIENT" ]]; then
	PACKETS_TO_INSTALL=${PACKETS_TO_INSTALL},task-gnome-desktop
elif [[ $ROLE == "WEBSERVER" ]]; then
	PACKETS_TO_INSTALL=${PACKETS_TO_INSTALL},nginx
elif [[ $ROLE == "DATABASE" ]]; then
	PACKETS_TO_INSTALL=${PACKETS_TO_INSTALL},libaio1,libnuma-dev,libaio-dev
fi


if [[ $INSTALLOPTION == DIR ]]; then
	echo_string_white "Copying base system to disk.."
	/bin/cp -a ${RESOURCE}/* /mnt 
	check_exit_status 
elif [[ $INSTALLOPTION == URL ]]; then
	echo_string_white "Downloading new base system.." 
	/usr/sbin/debootstrap --arch $ARCH --include=${PACKETS_TO_INSTALL} $DISTRIBUTION /mnt
	check_exit_status
fi

echo_string_white "Installing grub.."
	/usr/sbin/grub-install --boot-directory=/mnt/boot --modules=part_msdos $DEVICE
	check_exit_status

#Preventing OS from giving dynamic names to network interfaces
if [[ $RESOURCE == *"ubuntu"* ]]; then
 	echo_string_white "Modifying Ubuntu network interface naming system.."
 	sed -i 's/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\"/g' /mnt/etc/default/grub
fi

echo_string_white "Mounting required directories.."
echo_string_white "Mounting /proc"
  	mount --bind /proc /mnt/proc
	check_exit_status
	DISKSMOUNTED=1
echo_string_white "Mounting /dev"
  	mount --bind /dev /mnt/dev
	check_exit_status
echo_string_white "Mounting /sys"
  	mount --bind /sys /mnt/sys
	check_exit_status

echo_string_white "Configuring boot loader.."
  	chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
	check_exit_status

#Configuring settings by modifying some of the system files ( sets ir as "root")
echo_string_white "Configuring root password.."
  	sed -i 's/root:[^:]*/root:$6$XMAs\/o1j$HU\.hWopHK5i0D2RLfF2rWmAzPL\.Tf6VrLLOsv6c2lCfa7nShLsdyJbLXy0\/sSqcGASbJEocsZEHsTWZrLKDqh\./g' /mnt/etc/shadow
	check_exit_status


echo_string_white "Configuring hostname.."
  	echo $HOSTNAME > /mnt/etc/hostname
echo_string_white "Configuring ssh.."
echo_string_white "Creating directory.."
	chroot /mnt mkdir /root/.ssh
	check_exit_status
echo_string_white "Creating authorized keys file.."
	chroot /mnt touch /root/.ssh/authorized_keys
	check_exit_status
echo_string_white "Inserting public key.."
	echo ${SSH_PUBLIC_KEY} > /mnt/root/.ssh/authorized_keys
	check_exit_status
echo_string_white "Configuring directory permissions"
  	chroot /mnt chmod 700 /root/.ssh
	check_exit_status
echo_string_white "Configuring file permissions"
  	chroot /mnt chmod 600 /root/.ssh/authorized_keys
	check_exit_status
echo_string_white "Configuring ssh permissions for root.."
	if [ ENABLE_ROOT_SSH_LOGIN == 1 ]; then
	  	chroot /mnt sed -i "s/PermitRootLogin yes/PermitRootLogin without-password/g" /etc/ssh/sshd_config
	else
		chroot /mnt sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
	fi
	check_exit_status

#Configuration depending on VM role
if [ $ROLE == "MASTER" ]; then
	echo_string_white "Downloading Ansible.."
	chroot /mnt wget http://releases.ansible.com/ansible/ansible-latest.tar.gz
	check_exit_status

	echo_string_white "Extracting Ansible.."
	chroot /mnt tar xzf ansible-latest.tar.gz
	check_exit_status
	
	echo_string_white "Downloading pip.."
	chroot /mnt curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py
	check_exit_status

	echo_string_white "Installing pip.."
	chroot /mnt /usr/bin/python2.7 get-pip.py
	check_exit_status

	echo_string_white "Creating python symlink.."
	chroot /mnt ln -s /usr/bin/python2.7 /usr/bin/python 

	echo_string_white "Installing Ansible.."
	echo "#!/bin/bash
	cd /$LATEST_ANSIBLE
	make
	make install"  > /mnt/root/script.sh
	chmod +x /mnt/root/script.sh
	chroot /mnt bash /root/script.sh
	check_exit_status
	
	echo_string_white "Installing zabbix-api.."
	chroot /mnt pip install zabbix-api
	check_exit_status	

	echo_string_white "Configuring master SSH key.."
		chroot /mnt ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
		check_exit_status
	echo_string_white "Saving master SSH key in host machine.."
		cp /mnt/root/.ssh/id_rsa.pub $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/master_pub_key
		check_exit_status 
	echo_string_white "Copying Ansible config files to master.."
		mkdir /mnt/etc/ansible
		cp -a $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/ansible/* /mnt/etc/ansible/
	check_exit_status  
else
	echo_string_white "Adding master's SSH key to authorized keys.."
	cat $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/master_pub_key >> /mnt/root/.ssh/authorized_keys
	check_exit_status
fi

#Add user for client (User / root)
if [ ${ROLE} == "CLIENT" ]; then
	chroot /mnt useradd -m -s /bin/bash test
	sed -i 's/test:[^:]*/test:$6$XMAs\/o1j$HU\.hWopHK5i0D2RLfF2rWmAzPL\.Tf6VrLLOsv6c2lCfa7nShLsdyJbLXy0\/sSqcGASbJEocsZEHsTWZrLKDqh\./g' /mnt/etc/shadow
	echo "10.10.10.1	www.example.com" >> /mnt/etc/hosts
fi

#Download MySQL cluster for database VM
if [ ${ROLE} == "DATABASE" ]; then

	chroot /mnt apt-get update && apt-get install -y python-dev libmysqlclient-dev build-essential

	echo_string_white "Downloading MySQL cluster archive.."
	if [ $ARCH == "i386" ]; then
 		wget --continue -P /root/ http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.5/mysql-cluster-gpl-7.5.4-linux-glibc2.5-i686.tar.gz
		check_exit_status
	elif [ $ARCH == "amd64" ]; then
		wget --continue -P /mnt/root/ http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.5/mysql-cluster-gpl-7.5.4-linux-glibc2.5-x86_64.tar.gz
		check_exit_status
	fi
fi

echo_string_white "Installing OS specific (zabbix-agent and iptables).."
chroot /mnt echo iptables-persistent iptables-persistent/autosave_v4 boolean true |  debconf-set-selections
chroot /mnt echo iptables-persistent iptables-persistent/autosave_v6 boolean true |  debconf-set-selections
chroot /mnt echo iptables iptables/autosave_v4 boolean true |  debconf-set-selections
chroot /mnt echo iptables iptables/autosave_v6 boolean true |  debconf-set-selections

if [[ $OSTYPE == *"Ubuntu"* ]]; then
    if [[ $ROLE != "MASTER" ]]; then
	sleep 3
	chroot /mnt wget http://repo.zabbix.com/zabbix/3.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.0-1+${DISTRIBUTION}_all.deb
	chroot /mnt dpkg -i zabbix-release_3.0-1+${DISTRIBUTION}_all.deb
 	chroot /mnt apt-get update 
	chroot /mnt apt-get install -y iptables 
	chroot /mnt apt-get install -y zabbix-agent
     fi
elif [[ $OSTYPE == *"Debian"* ]]; then
    if [[ $ROLE != "MASTER" ]]; then
	chroot /mnt wget http://repo.zabbix.com/zabbix/3.0/debian/pool/main/z/zabbix-release/zabbix-release_3.0-1+jessie_all.deb
	chroot /mnt dpkg -i zabbix-release_3.0-1+${DISTRIBUTION}_all.deb
	chroot /mnt apt-get update 
	chroot /mnt apt-get install -y iptables-persistent
 	chroot /mnt apt-get install -y zabbix-agent
    fi
fi
check_exit_status

#configure fstab
echo_string_white "Setting UUID in fstab.."
	UUID=$(blkid | grep ${DEVICE}p1 | awk {' print $2 '} | tr -d \" )
	echo "${UUID} / ext4 errors=remount-ro 0 1" >> /mnt/etc/fstab
	check_exit_status


#Validate provided IPs and set them as static if they are valid (only for intnet)
COUNT=0
echo_string_white "Vaidating and configuring network settings"
for i in {1..4}
do
	if [ ! -z ${NIC[$i]+x} ]; then
		echo "auto eth${COUNT}" >> /mnt/etc/network/interfaces
		if [ ${NICNETW[$i]} == "static" ]; then
			echo "iface eth${COUNT} inet static" >> /mnt/etc/network/interfaces
			if validate_ip ${NICIP[$i]}; then 
				stat='good'; else stat='bad'; 
			fi

			if [ $stat == "good" ]; then 	
				echo "address ${NICIP[$i]}" >> /mnt/etc/network/interfaces
			else 
				echo_string_white "IP address ${NICIP[$i]} not valid, so not set"
			fi
         		
			if validate_ip ${NETMASK[$i]}; then 
				stat='good'; else stat='bad'; 
			fi
         		if [ $stat == "good" ]; then 	
				echo "netmask ${NETMASK[$i]}" >> /mnt/etc/network/interfaces
			else 
				echo_string_white "Netmask ${NETMASK[$i]} not valid, so 255.255.0.0 set instead"
				echo "NETMASK 255.255.255.0" >> /mnt/etc/network/interfaces
			fi
			echo "dns-nameservers 8.8.8.8" >> /mnt/etc/network/interfaces
		else 
			echo "iface eth${COUNT} inet dhcp" >> /mnt/etc/network/interfaces
		fi
        ((COUNT++))
	fi
done
check_exit_status

cleanup
DISKSMOUNTED=0

echo_string_white "Converting raw image to VDI.."
	/usr/bin/vboxmanage convertfromraw --format vdi $RAWIMAGE "$VDIIMAGE"
	check_exit_status

echo_string_white "Creating VM.."
	/usr/bin/vboxmanage createvm --name $VMNAME --register --ostype $OSTYPE --basefolder "$BASEFOLDER"
	check_exit_status
echo_string_white "Modifying VM.."
	/usr/bin/vboxmanage modifyvm $VMNAME --memory $MEMORY --cpus $CPUS
	check_exit_status

echo_string_white "Setting up network interface card(s).."
	for i in {1..4}
	do
		if [ -z ${NICTYPE[$i]+xxx} ]; then
			NICTYPE[$i]=82540EM
		fi 
		if [ -n ${NIC[$i]} ]; then
			if [ ${NIC[$i]} == "bridged" ]; then
				echo_string_white "Setting up $i network interface card (bridged).." 	
				/usr/bin/vboxmanage modifyvm $VMNAME --nic$i ${NIC[$i]}  --nictype$i ${NICTYPE[$i]} --bridgeadapter$i wlp8s0 --macaddress$i auto 
				check_exit_status
			elif [ ${NIC[$i]} == "intnet" ]; then
				echo_string_white "Setting up $i network interface card (internal).."
				/usr/bin/vboxmanage modifyvm $VMNAME --nic$i ${NIC[$i]}  --nictype$i ${NICTYPE[$i]} --intnet$i ${NICINETNAME[$i]}
				check_exit_status
			else 
				echo_string_red "Entered networking type ${NIC[$i]} is not supported. Skipping"
			fi
		fi
done


echo_string_white "Configuring VM storage options"
	/usr/bin/vboxmanage storagectl $VMNAME --name SATA --add sata --bootable on
	check_exit_status

echo_string_white "Attaching disk to new VM.."
	/usr/bin/vboxmanage storageattach $VMNAME --storagectl SATA --port 0 --device 0 --type hdd --medium "$VDIIMAGE"
	check_exit_status

echo_string_white "Registering.."
	/usr/bin/vboxmanage registervm "${BASEFOLDER}"${VMNAME}/${VMNAME}.vbox

if [[ $KEEP_IMG_DISK==0 ]];then
echo_string_white "Deleting .img disk file"	
	rm $RAWIMAGE
	check_exit_status
fi


#echo_string_white "Starting VM.."
#VBoxManage startvm $VMNAME --type gui #change to headless later

echo_string_white "Configuring permissions.."
	chown -R $USERNAME:$USERNAME "${BASEFOLDER}"${VMNAME}
	check_exit_status
	chown $USERNAME:$USERNAME "$VDIIMAGE"
	check_exit_status

	chmod +x $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/startVMs.sh && chown $USERNAME:$USERNAME $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/startVMs.sh 
	chmod +x $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/stopVMs.sh && chown $USERNAME:$USERNAME $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/stopVMs.sh 
	chmod +x $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/registerVMs.sh && chown $USERNAME:$USERNAME $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/registerVMs.sh

	echo "vboxmanage registervm '${BASEFOLDER}${VMNAME}/${VMNAME}.vbox'" >> $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/registerVMs.sh
	echo "vboxmanage startvm ${VMNAME}" >> $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/startVMs.sh
	echo "vboxmanage controlvm ${VMNAME} poweroff" >> $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/stopVMs.sh



