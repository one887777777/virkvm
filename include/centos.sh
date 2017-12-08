create_kvm(){
	path=$1
	vmname=$2
	cpunum=$3
	memorysize=$4
	base_image=$5
    data_image=$6
	macaddr="52:54:$(dd if=/dev/urandom count=1 2>/dev/null | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4/')"
	UUID=`uuidgen`
	image_path="${path}/${vmname}.qcow2"
    data_path="${path}/${vmname}_data.qcow2"
	if [[ "${path}x" = "x" ]] || [[ "${vmname}x" = "x" ]] || [[ "${cpunum}x" = "x" ]] || [[ "${memorysize}x" = "x" ]] || [[ "${macaddr}x" = "x" ]] || [[ "${UUID}x" = "x" ]] || [[ "${data_image}x" = "x" ]] || [[ "${base_image}x" = "x" ]]
        then
        echo "parameter ERROR:path=${path},vmname=${vmname},cpunum=${cpunum},memorysize=${memorysize},macaddr=${macaddr},UUID=${UUID},data_image=${data_image},base_image=${base_image}"
        exit 1
        fi
	[ -d $path ] || mkdir -p $path
	/usr/bin/qemu-img create -F qcow2 -b ${base_image} -f qcow2 ${image_path}
    /usr/bin/qemu-img create -F qcow2 -b ${data_image} -f qcow2 ${data_path}
	cat <<EOF >/tmp/${vmname}.xml
<domain type='kvm'>
  <name>${vmname}</name>
  <uuid>${UUID}</uuid>
  <memory unit='KiB'>${memorysize}</memory>
  <currentMemory unit='KiB'>${memorysize}</currentMemory>
  <vcpu placement='static'>${cpunum}</vcpu>
  <cputune>
    <shares>${cpunum}</shares>
  </cputune>
  <os>
    <type arch='x86_64' machine='rhel6.6.0'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/libexec/qemu-kvm</emulator>
    <disk type='file' device='disk' snapshot='external'>
      <driver name='qemu' type='qcow2' cache='writeback'/>
      <source file='${image_path}'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </disk>
    <disk type='file' device='disk' snapshot='external'>
      <driver name='qemu' type='qcow2' cache='writeback'/>
      <source file='${data_path}'/>
      <target dev='vdb' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <target dev='hdc' bus='ide'/>
      <readonly/>
      <address type='drive' controller='0' bus='1' target='0' unit='0'/>
    </disk>
    <controller type='usb' index='0' model='ich9-ehci1'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x7'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <master startport='0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0' multifunction='on'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <master startport='2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <master startport='4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x2'/>
    </controller>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='bridge'>
      <mac address='${macaddr}'/>
      <source bridge='br0'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <input type='tablet' bus='usb'/>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'>
      <listen type='address' address='0.0.0.0'/>
    </graphics>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </memballoon>
  </devices>
</domain>
EOF
if [[ -f "$image_path" && -f "$base_image" ]];then
    virsh define /tmp/${vmname}.xml
fi
}

update_ip(){
vmname=$1
path=$2
ip=$3
pattern01="192.168.1.[0-9]{1,3}"
pattern70="192.168.0.[0-9]{1,3}"
pattern10="10.10.10.[0-9]{1,3}"
if [[ $ip =~ ${pattern01} ]];then
    gateway='192.168.1.1'
    netmask='255.255.0.0'
    echo -e "options timeout:1 attempts:1 rotate \nnameserver 192.168.2.125" >/tmp/resolv.conf-$vmname
elif [[ $ip =~ ${pattern70} ]];then
    gateway='192.168.0.1'
    netmask='255.255.255.0'
    echo -e "options timeout:1 attempts:1 rotate \nnameserver 192.168.2.125" >/tmp/resolv.conf-$vmname
elif [[ $ip =~ ${pattern10} ]];then
    gateway='10.10.10.1'
    netmask='255.255.255.0'
    echo -e "options timeout:1 attempts:1 rotate \nnameserver 192.168.2.125" >/tmp/resolv.conf-$vmname
fi

while true; do
  #virsh list --all|grep $vmname |grep "shut of" >>/dev/null
  virsh list --all|grep $vmname >>/dev/null
  if [[ $? == 0 ]]; then

echo "DEVICE=\"eth0\"
BOOTPROTO=\"static\"
IPADDR=$ip
NETMASK=$netmask
ONBOOT=\"yes\"
TYPE=\"Ethernet\"
GATEWAY=\"$gateway\"" >/tmp/ifcfg-eth0-$vmname
echo -e "NETWORKING=yes \nHOSTNAME=$vmname" >/tmp/network-$vmname

guestfish --rw -a ${path}/${vmname}.qcow2 -i << EOF >/dev/null 2>&1
upload /tmp/ifcfg-eth0-$vmname /etc/sysconfig/network-scripts/ifcfg-eth0
upload /tmp/network-$vmname /etc/sysconfig/network
upload /tmp/resolv.conf-$vmname /etc/resolv.conf
command 'sed -i /\/dev\/vdb/d /etc/fstab'
command 'sed -i \$a\/dev/vdb\t\t\t\t/data\t\t\text4\tdefaults,noatime,nodiratime\t1\t2 /etc/fstab'
mkdir /root/.ssh
write /root/.ssh/authorized_keys "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwi9CGoH3c9GkZfCSLd1LYAYLBpotv8c3hxiRbC+4kxenyRHDadAnTgM+ZFiu4Oo4ALOu86EghkzthCc+UjBF3EC+db35WN/sbpNzYj7Tj2jSeg1PFQjhdfofd7KSiDRIPGQNDNTlN1U1KdbBnf2QvaTZcMLJxF1xmI/pZ0N4fDawufm3QvGYENI2GDWZFV1ELkuxSPehECPFOE7yQKxkYrdZUehhgh/djXM6O9IrjA+2CNjzg9Wg5jNnraojJBmrE+ZsJcv8NkMC9GqOWCxT8Jq8EFQ4i5Jy+0ZX6abVv/XwBBQpgdVqAkSfSNZmNZ/l4Tcuuxeu8ZFL6UYOrLeVpQ== root@iZ23o583y4aZ"
EOF
  fi
  if [[ $? == 0  ]]; then
      echo "update ip config file success"
      break
  fi
done
}