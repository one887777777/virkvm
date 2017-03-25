#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================#
#   System Required:  CentOS/RadHat 5+                                          #
#   Description: Auto Install KVM( Centos6.8 )                                  #
#   Author: GufengWang <cn.wangbj@icloud.com>                                   #
#   Intro:  https://diycode.me                                                  #
#===============================================================================#
cur_dir=`pwd`

#defult config
cpunum=2
memorysize=$(expr 2048 \* 1024 )
disksize=20
installpath="/data/system"
images_dir="/home/imgcache"

#include virkvm module
include(){
    local include=$1
    if [[ -s ${cur_dir}/include/${include}.sh ]];then
        . ${cur_dir}/include/${include}.sh
    else
        echo "Error:${cur_dir}/include/${include}.sh not found, shell can not be executed."
        exit 1
    fi
}

while getopts :f:t:c:m:i:d: ARG
do
    case $ARG in
        f) fromip=$OPTARG
            ;;
        t) toip=$OPTARG
            ;;
        c) cpunum=$OPTARG
            ;;
        m) memorysize=$(expr ${OPTARG} \* 1024 )
            ;;
        i) installpath=$OPTARG
            ;;
        d) disksize=$OPTARG
            ;;
    esac
done

#public config
public(){
    include config
    load_config
    include public
    public_install
    include centos
}

#virkvm main process
virkvm(){
    echo "Game is over!";
    clear
    echo "#####################################################################"
    echo "# Auto Install KVM( Centos6.8 )                                     #"
    echo "# Intro:  https://diycode.me                                        #"
    echo "# Author: GufengWang <cn.wangbj@icloud.com>                         #"
    echo "#####################################################################"
    cd ${current_dir}
    for (( i = $fromipnum; i <= $toipnum; i++ )); do
        getnumip=`num2ip $i`
        getvmname=`num2vmname $i`
        check_vm $getvmname
        check_ip_use $getnumip
        echo "start create_vm $installpath $getvmname $cpunum $memorysize $base_image $data_image"
        create_kvm $installpath $getvmname $cpunum $memorysize $base_image $data_image
        echo "start replace ip :update_ip $getvmname $installpath $getnumip"
        update_ip $getvmname $installpath $getnumip
        virsh start $getvmname
    done
    cd ${current_dir}
    echo ""
}

#Run it
public
virkvm

