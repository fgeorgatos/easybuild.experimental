mkdir openmm_build
cd openmm_build
cmake ../OpenMM5.0-Source -OPENMM_BUILD_CUDA_LIB=ON -OPENMM_BUILD_OPENCL_LIB=OFF -DCMAKE_INSTALL_PREFIX=/home/users/wjurkowski/openmm
make 
make install
