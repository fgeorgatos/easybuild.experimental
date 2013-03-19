tar -zxf rosetta3.4_source.tgz
cd rosetta_source
#1. uncomment  the "program_path" line and import os in  tools/build/user.settings to let scons search for intel compilers
~/scons/bin/scons bin mode=release

