import urllib2
import os
import time, paramiko
import subprocess
import re
import xml.etree.ElementTree as ET

url_qcow2 = 'http://engine-web.appsec.spirent.com/download/builds/integration/19.4.0/7502/cfv-data-breach-19.4.0.7502-micro.qcow2'
url_xml = 'http://engine-web.appsec.spirent.com/download/builds/integration/19.4.0/7502/cfv-data-breach-19.4.0.7502-micro.xml'

image_name = url_qcow2.split('/')[-1]
cfg_name = url_xml.split('/')[-1]



# Download the qcow2 file and xml 	file
print "Downloading the config file: " + cfg_name + "..."
if os.path.isfile('/home/lyang/tmp/'+cfg_name):
    print (cfg_name + " exist")
else:
    xml_url = urllib2.urlopen(url_xml)
    xml_file = xml_url.read()
    with open('/home/lyang/tmp/'+cfg_name, 'wb') as fcfg:
        fcfg.write(xml_file)
print "Done!" 

print "Downloading the qcow2 file: " + image_name + "..."
if os.path.isfile('/home/lyang/tmp/' + image_name):
    print (image_name + " exist")
else:
    qcow2_url = urllib2.urlopen(url_qcow2)
    qcow2_file = qcow2_url.read()
    with open('/home/lyang/tmp/'+image_name, 'wb') as fqcow2:
        fqcow2.write(qcow2_file)
print "Done!"


print "Moving the qcow2 file to /var/lib/libvirt/images/"

if os.path.isfile("/home/lyang/tmp/" + image_name):
    os.system("sudo cp -rf /home/lyang/tmp/" + image_name + " /var/lib/libvirt/images/")
else:
    print image_name + "doesn't exist!   exiting..."
    exit(1)
print "Done!"


print "Setting up virtual machine with " + image_name + " and " + cfg_name
p0 = subprocess.Popen(["virsh", "create", "/home/lyang/tmp/"+cfg_name])

while p0.poll() is None:
	print "..."
	time.sleep(1)
print "VM creation is Done!"

print "the domain name of the virtual machine:"
vm_name = ''
with open('/home/lyang/tmp/'+cfg_name, 'r') as fcfg:
	for line in fcfg:
		if "<name>" in line:
			vm_name = re.sub('<name>|</name>','',line)
			vm_name = vm_name.strip()
print vm_name

#Get the mac address of the admin interface as it is the password of the admin

print "The initial password of the admin user:"
vm_xml = subprocess.check_output(['virsh', 'dumpxml', vm_name])
os.system("sudo rm /home/lyang/tmp/vm_xml")
with open("/home/lyang/tmp/vm_xml",'w') as f_xml:
	f_xml.write(vm_xml)

admin_passwd = ''
tree = ET.parse("/home/lyang/tmp/vm_xml")
root = tree.getroot()
for interface in root.findall('./devices/interface'):
	target = interface.find('./target')
	if target != None:
		if "vnet0" == target.get('dev'):
			mac_label = interface.find('./mac')
	 		admin_passwd = mac_label.get('address')
	 		admin_passwd = re.sub(':','',admin_passwd)  
print "The initial password of the admin user:" + admin_passwd

#p1 = subprocess.Popen(["virsh","console", "cfv-data-breach-19.4.0.7502-micro"],)

cfv_ip = ''
with open("/home/lyang/tmp/console.log","w") as fout:
	p1=subprocess.Popen(["virsh","console", "cfv-data-breach-19.4.0.7502-micro"],stdout=fout)
	
print "Waiting for VM bootup..."	
time.sleep(30)   

#doLoop = True
#while doLoop:
time.sleep(2)
with open("/home/lyang/tmp/console.log","r") as fr:		
	for line in fr.readlines():			
		if "CFV IP Addr" in line:
			cfv_ip = line
			#doLoop = False

cfv_ip = cfv_ip[cfv_ip.find(':') + 1 : ]
cfv_ip = cfv_ip.strip()

print cfv_ip

os.system('ssh admin@'+cfv_ip)

exit(0)
