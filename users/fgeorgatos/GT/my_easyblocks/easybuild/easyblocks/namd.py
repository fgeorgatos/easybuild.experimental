"""
EasyBuild support for installing NAMD
implemented as an easyblock
"""

import shutil

from easybuild.framework.easyconfig import CUSTOM
from easybuild.easyblocks.generic.configuremake import ConfigureMake
from easybuild.tools.modules import get_software_root
from easybuild.tools.filetools import run_cmd
import os

class EB_NAMD(ConfigureMake):
    """
    Support for installing NAMD.
    """

    def extra_options(extra = None):
        extra_vars = [
                      ('charm_opts', ['', "", CUSTOM]),
                      ('namd_charm_opts', ['', "", CUSTOM]),
                      ('cuda_prefix', ['', "", CUSTOM]),
                      ('namd_arch', ['', "", CUSTOM])
                     ]
        return extra_vars

    def patch_step(self):
        run_cmd("tar xf charm-6.4.0.tar") ###### FIXME ######
        cmd = "./build charm++ " + self.cfg["charm_opts"] 
        cmd += " -j" + str(self.cfg['parallel'])
        cmd += " --with-production"
        run_cmd(cmd, path = "charm-6.4.0")

    def configure_step(self):
        cmd = "./config " + self.cfg["namd_arch"]  
        cmd += " --charm-arch " + self.cfg["namd_charm_opts"]
        if len(self.cfg["cuda_prefix"]) > 0 :
                cmd += " --with-cuda --cuda-prefix " + self.cfg["cuda_prefix"]

        # FFTW, TCL
        for dep in ["FFTW", "Tcl"]:
            deproot = get_software_root(dep)
            if deproot:
                self.cfg.update('configopts', '--%s-prefix %s' % (dep.lower(), deproot))
        ## cmd += " --tcl-prefix $EBROOTTCL --fftw-prefix $EBROOTFFTW" ##
        cmd += " --tcl-prefix /home/users/fgeorgatos/.local/easybuild/software/Tcl/8.5.12 --fftw-prefix /home/users/fgeorgatos/.local/easybuild/software/FFTW/2.1.5-GCC-4.6.3"

        run_cmd(cmd, path = self.src[0]['finalpath'])

    def build_step(self):
        cmd = "LIBRARY_PATH=$LD_LIBRARY_PATH:$LIBRARY_PATH "
        cmd += "make -j" + str(self.cfg['parallel'])
        run_cmd(cmd, path = self.src[0]['finalpath'] + "/" + self.cfg["namd_arch"])

    def install_step(self):
        run_cmd("mkdir -p " + self.installdir)
        run_cmd("cp -aL " + self.src[0]['finalpath'] + "/" + self.cfg["namd_arch"] + "/* "+self.installdir)   

    def make_module_extra(self):

        txt = super(EB_NAMD, self).make_module_extra()
        txt += self.moduleGenerator.prepend_paths("PATH", [""])
#        txt += self.moduleGenerator.prepend_paths("LD_LIBRARY_PATH", [self.dir])
        self.log.debug("make_module_extra added %s" % txt)
        return txt


