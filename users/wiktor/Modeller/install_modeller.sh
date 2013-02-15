tar -zxf modeller-9.11.tar.gz
cd modeller-9.11/
#configure installation dir
export MODELLERBIN=/home/users/wjurkowski/bin/modeller9.11
#run installation
./Install

#Interactive part 
#
#Q/A
#"Select the type of your computer from the list above [3]: "
#"3\r"
#Full directory name in which to install MODELLER 9.11	
$MODELLERBIN
#begin instalation: Press <Enter> to begin the installation:    
#finish: Press <Enter> to continue:

#configure paths
export PYTHONPATH=$PYTHONPATH:$MODELLERBIN/lib/x86_64-intel8/python2.5/:$MODELLERBIN/modlib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MODELLERBIN/lib/x86_64-intel8
