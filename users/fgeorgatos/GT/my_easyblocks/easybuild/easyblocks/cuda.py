# This file is an EasyBuild recipy as per https://github.com/hpcugent/easybuild
#
# Copyright:: Copyright (c) 2012 Cyprus Institute / CaSToRC, University of Luxembourg / LCSB
#
# This work is part of HPCBIOS project and is a component of policy:
# http://hpcbios.readthedocs.org/en/latest/HPCBIOS_2012-99.html
#
# Author::    George Tsouloupas <g.tsouloupas@cyi.ac.cy>, Fotis Georgatos <fotis.georgatos@uni.lu>
# License::   MIT/GPL


### TODO:
### * ensure modulefile adds also CUDA_HOME: . 
### * ensure modulefile adds also CPATH: include
### * ensure modulefile adds also PATH: open64/bin 
### * ensure modulefile adds also LD_LIBRARY_PATH: lib64
### * propose a default value for CUDA_NVCC_FLAGS, if not already defined???
### ** CUDA_NVCC_FLAGS='-gencode;arch=compute_20,code=sm_20;-use_fast_math;' # conservative, to permit TV debugging
### * Verify with: https://speakerdeck.com/ajdecon/introduction-to-the-cuda-toolkit-for-building-applications

"""
EasyBuild support for CUDA, implemented as an easyblock
"""
import glob
import os
import stat

import easybuild.tools.environment as env
from easybuild.easyblocks.generic.binary import Binary
from easybuild.tools.filetools import run_cmd_qa, run_cmd
from distutils.version import LooseVersion


class EB_CUDA(Binary):
    """
    Support for installing CUDA.
    """

    def __init__(self, *args, **kwargs):
        super(EB_CUDA, self).__init__(*args, **kwargs)
        self.bindir = None

    def extract_step(self):
        cmd = self.src[0]['path']
        run_cmd("chmod +x " + cmd)
        run_cmd(cmd + " --noexec --nox11 --target " + self.builddir)
        self.src[0]['finalpath'] = self.builddir

    def install_step(self):

        run_cmd("mkdir -p "+self.installdir)

        # Define how to run the installer
        if LooseVersion(self.version) <= LooseVersion("5"):
          cmd = os.path.join(self.builddir, "install-linux.pl --prefix=" + self.installdir)
        else:
          cmd = os.path.join(self.builddir, "cuda-installer.pl -verbose -silent -samplespath=%s/samples/ -toolkitpath=%s -samples -toolkit" % (self.installdir, self.installdir))

        qanda = {
                 "A previous version of CUDA was found in /usr/local/cuda\nWould you like to remove all CUDA files under /usr/local/cuda? (yes/no/abort): ": "no",
                 }
        noqanda = [r"Installation Complete"]

        run_cmd_qa(cmd, qanda, no_qa = noqanda, log_all = True, simple = True)

        try:
            os.chmod(self.installdir, stat.S_IRWXU | stat.S_IXOTH | stat.S_IXGRP | stat.S_IROTH | stat.S_IRGRP)
        except OSError, err:
            self.log.exception("Can't set permissions on %s: %s" % (self.installdir, err))

    def make_module_req_guess(self):
        """Specify CUDA TotalView custom values for PATH etc."""

        guesses = super(EB_CUDA, self).make_module_req_guess()

        if LooseVersion(self.version) <= LooseVersion("5"):
          guesses.update({
                          'PATH': ['bin', 'open64/bin'],
                          'LD_LIBRARY_PATH': ['lib64'],
                          'CPATH': ['include'],
                          'CUDA_HOME': ['.'] # or, self.rootpack_dir?
                         })
        else:
          guesses.update({
                          'PATH': ['toolkit/bin', 'toolkit/open64/bin'],
                          'LD_LIBRARY_PATH': ['toolkit/lib64'],
                          'CPATH': ['toolkit/include'],
                          'CUDA_HOME': ['toolkit'],
                         })
                         
        guesses.update({'CUDA_NVCC_FLAGS': ['-gencode;arch=compute_20,code=sm_20;-use_fast_math']})

        return guesses
                       
#    def make_module_extra(self):
#        """Add extra environment variables for CUDA_HOME and anything else."""
#
#        txt = super(EB_CUDA, self).make_module_extra()
#        txt += "prepend-path\t%s\t\t%s\n" % ('CUDA_HOME', self.rootpack_dir)
#        self.log.debug("make_module_extra added %s" % txt)
#        return txt



