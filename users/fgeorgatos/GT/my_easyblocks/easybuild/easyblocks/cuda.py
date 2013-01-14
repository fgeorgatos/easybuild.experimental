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

    def make_module_extra(self):

        txt = super(EB_CUDA, self).make_module_extra()
        self.log.debug("make_module_extra added %s" % txt)
        return txt

