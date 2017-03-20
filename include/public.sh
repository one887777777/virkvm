public_install(){
    #public arg
    cd ${current_dir}

    if [ $disksize -eq '20' -o $disksize -eq '50' -o $disksize -eq '100' -o $disksize -eq '10' ];then
        echo "/data disk is ${disksize}G"
    else
        echo "/data disk is wrong,only support 20,50,100"
        exit
    fi

    data_image=$(echo "${images_dir}/centos6.5_data_20G.qcow2" |sed s/20/$disksize/g )
    if [[ "${toip}x" = "x" ]]; then
	    toip=$fromip
    fi

    #检查ip
    check_ip_format $fromip
    check_ip_format $toip

    #ip数字
    fromipnum=`ip2num $fromip`
    toipnum=`ip2num $toip`

    #装软件
    guestfish -V >>/dev/null
    if [[ $? != 0 ]]; then
        yum install libguestfs-tools -y
    fi

    #判文件
    if [[ ! -f ${base_image} ]] ;then
        wget -S http://s0.diycode.me/centos6.5_root_10G_v2.qcow2 -O ${base_image}
    fi
    if [[ ! -f ${data_image} ]] ;then
        wget -S http://s0.diycode.me/"$(echo ${data_image} | awk -F'/' '{ print $NF }')".gz -O ${data_image}.gz
        gunzip ${data_image}.gz
    fi
}

check_ip_format(){
    echo -e "\e[32m The function is to check ipaddress $1  \e[m"
    echo $1|grep "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$" > /dev/null;
    if [ $? != 0 ];then
        echo -e "\e[32m The addr ipaddr not number,please try again use other ipaddr. \e[m"
        exit 1
    fi
    ipaddr=$1
    a=`echo $ipaddr|awk -F . '{print $1}'`
    b=`echo $ipaddr|awk -F . '{print $2}'`
    c=`echo $ipaddr|awk -F . '{print $3}'`
    d=`echo $ipaddr|awk -F . '{print $4}'`
    for num in $a $b $c $d
    do
    if [ $num -gt 255 ] || [ $num -lt 0 ];then
        echo -e "\e[32m You load Error ipaddr.please try again use other ipaddr. \e[m"
        exit 1
    fi
    done
}

check_ip_use(){
    ipaddr=$1
    ping -c 1 -w 1 ${ipaddr} >/dev/null 2>&1
    if [ $? -eq '0' ];then
        echo -e "\e[32m ${ipaddr}:this ip has been used!  \e[m"
        break 2
    fi
}

ip2num(){
	ipaddr=$1
	a=`echo $ipaddr|awk -F . '{print $1}'`
	b=`echo $ipaddr|awk -F . '{print $2}'`
	c=`echo $ipaddr|awk -F . '{print $3}'`
	d=`echo $ipaddr|awk -F . '{print $4}'`
	ipnum=$((a*256*256*256+b*256*256+c*256+d))
	echo $ipnum
}

num2ip(){
	ipnum=$1
	a=$(($ipnum/256/256/256));
	b=$(($ipnum/256/256-$a*256));
	c=$(($ipnum/256-$a*256*256-$b*256));
	d=$(($ipnum-a*256*256*256-$b*256*256-$c*256))
	numip="${a}.${b}.${c}.${d}"
	echo $numip
}

num2vmname(){
	ipnum=$1
	a=$(($ipnum/256/256/256));
	b=$(($ipnum/256/256-$a*256));
	c=$(($ipnum/256-$a*256*256-$b*256));
	d=$(($ipnum-a*256*256*256-$b*256*256-$c*256))
	vmname="${a}_${b}_${c}_${d}"
	echo $vmname
}

check_vm() {
    vmname=$1
    line=`virsh list --all | awk '{ if ( $2=="'$vmname'") print $0 }' | wc -l`
    if [[ $line -gt '0' ]];then
        echo "$vmname has already defined "
        exit 1
    fi
}


