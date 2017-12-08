load_config(){
    current_dir=`pwd`

    #Download URL
    download_root_url="http://s0.diycode.me"

    #defult config
    base_image="${images_dir}/centos6.5_root_10G_v2.qcow2"
    mkdir -p ${images_dir}
    mkdir -p ${installpath}
    if [[ "${fromip}x" = "x" ]]; then
        help
    fi
}

#help help help
help(){
	echo "use $0 -f fromip -t toip [ -c cpunum] [ -m memorysize] [ -d disksize] [ -i installpath]
	sh $0 -f 192.168.0.8 -t 192.168.0.8 -c 2 -m 2048 -d 20 -i /data/system
	defult:
	cpunum=${cpunum}
	memorysize=$(expr $memorysize / 1024 )M
	installpath=${installpath}
	disksize=${disksize} G"
    exit 0
}