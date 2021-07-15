import subprocess
import os
import sys

def show_help():
    print ('usage:\n\tpython %s [y1.5 or y2.5 or y3.0] \n\tdefault is y1.5'%(__file__))
    print ('\tmake sure you input a valid DIR!')

def clone_yocto15(work_dir):
    print ('clone yocto1.5 code to %s...'%work_dir)
    #subprocess.call(['git', 'clone', '-b', 'yocto-1.5', 'git@github.com:SpirentCom/yocto-1.5-poky.git', 'poky'], stdout=subprocess.PIPE)
    #subprocess.call(['git', 'clone', '-b', 'yocto-1.5', 'git@github.com:SpirentCom/yocto-1.5-meta-intel.git', 'meta-intel'], stdout=subprocess.PIPE)
    #subprocess.call(['git', 'clone', '-b', 'yocto-1.5', 'git@github.com:SpirentCom/yocto-1.5-meta-openembedded.git', 'meta-openembedded'], stdout=subprocess.PIPE)
    #subprocess.call(['git', 'clone', '-b', 'yocto-1.5', 'git@github.com:SpirentCom/yocto-1.5-meta-virtualization.git', 'meta-virtualization'], stdout=subprocess.PIPE)
    #subprocess.call(['git', 'clone', '-b', 'yocto-unified', 'git@github.com:SpirentCom/yocto-meta-spirent.git', 'meta-spirent'], stdout=subprocess.PIPE)
    subprocess.call(['mkdir', '-p', 'build-dora-gf/conf'])
    os.chdir('./build-dora-gf/conf')

    subprocess.call(['ln', '-sf', '../../meta-spirent/build_configs/$BUILD_TARGET/bblayers.conf.sample', 'bblayers.conf'])
    subprocess.call(['ln', '-sf', '../../meta-spirent/build_configs/$BUILD_TARGET/local.conf.sample', 'local.conf'])


def clone_yocto25(work_dir):
    print ('clone yocto2.5 code to %s...'%work_dir)    


def clone_yocto30(work_dir):
    print ('clone yocto3.0 code to %s...'%work_dir) 

clone_repo={'y1.5':clone_yocto15,'y2.5':clone_yocto25, 'y3.0':clone_yocto30}

if len(sys.argv) == 3:
    if clone_repo.has_key(sys.argv[1]) and os.path.isdir(sys.argv[2]):
        os.chdir(sys.argv[2])
        clone_repo[sys.argv[1]](sys.argv[2])
    else:
        show_help()
else:
    show_help()
