##
# This file is an EasyBuild recipy as per https://github.com/hpcugent/easybuild
#
# Copyright:: Copyright (c) 2012-2013 Cyprus Institute / CaSToRC, University of Luxembourg / LCSB
# Author::    George Tsouloupas <g.tsouloupas@cyi.ac.cy>, Fotis Georgatos <fotis.georgatos@uni.lu>
# License::   MIT/GPL
# $Id$
#
# This work implements a part of the HPCBIOS project and is a component of the policy:
# http://hpcbios.readthedocs.org/en/latest/HPCBIOS_2012-99.html
##

"""
EasyBuild support for CUDA, implemented as an easyblock

Ref: https://speakerdeck.com/ajdecon/introduction-to-the-cuda-toolkit-for-building-applications
"""
import glob
import os
import stat

from easybuild.easyblocks.generic.binary import Binary
from easybuild.tools.filetools import run_cmd_qa, run_cmd
from distutils.version import LooseVersion


class EB_CUDA(Binary):
    """
    Support for installing CUDA.
    """

    def extract_step(self):
        execpath = self.src[0]['path']
        run_cmd("/bin/sh " + execpath + " --noexec --nox11 --target " + self.builddir)
        self.src[0]['finalpath'] = self.builddir

    def install_step(self):

        run_cmd("mkdir -p "+self.installdir)

        # Define how to run the installer
        if LooseVersion(self.version) <= LooseVersion("5"):
          cmd = os.path.join(self.builddir, "install-linux.pl --prefix=" + self.installdir)
        else:
	      ## The following would require to setup: osdependencies = 'libglut'
	      ## installparams = "-samplespath=%s/samples/ -toolkitpath=%s -samples -toolkit" % (self.installdir, self.installdir))
	      installparams = "-toolkitpath=%s -toolkit" % self.installdir)
          cmd = os.path.join(self.builddir, "cuda-installer.pl -verbose -silent " + installparams)

        qanda = {
                 "".join("A previous version of CUDA was found in /usr/local/cuda\n", 
		 "Would you like to remove all CUDA files under /usr/local/cuda? (yes/no/abort): "): "no",
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

        guesses.update({
                        'PATH': ['open64/bin', 'bin'],
                        'LD_LIBRARY_PATH': ['lib64'],
                        'CPATH': ['include'],
                        'CUDA_HOME': [''],
                        'CUDA_PATH': [''],
                       })

        return guesses

