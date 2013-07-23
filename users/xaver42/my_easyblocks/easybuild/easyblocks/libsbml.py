##
# Copyright 2013 Nils Christian, University of Luxembourg/Luxembourg Centre for Systems Biomedicine
#
# This file is part of EasyBuild,
# originally created by the HPC team of Ghent University (http://ugent.be/hpc/en),
# with support of Ghent University (http://ugent.be/hpc),
# the Flemish Supercomputer Centre (VSC) (https://vscentrum.be/nl/en),
# the Hercules foundation (http://www.herculesstichting.be/in_English)
# and the Department of Economy, Science and Innovation (EWI) (http://www.ewi-vlaanderen.be/en).
#
# http://github.com/hpcugent/easybuild
#
# EasyBuild is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation v2.
#
# EasyBuild is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with EasyBuild.  If not, see <http://www.gnu.org/licenses/>.
##
"""
EasyBuild support for libsbml, to set the PATHs of the different language bindings.
"""
import os

from easybuild.easyblocks.generic.cmakemake import CMakeMake
import easybuild.tools.filetools
import easybuild.easyblocks.generic.pythonpackage
import easybuild.easyblocks.perl

## FIXME helper functions belong into perl.py
def get_perl_archname():
    """
    Returns the archname as seen by the perl binary in the current path
    """
    cmd = "perl -MConfig -e 'print $Config::Config{archname}'"
    (perlarchname, _) = easybuild.tools.filetools.run_cmd(cmd, log_all=True, log_output=True, simple=False)
    return perlarchname

def get_perl_version():
    """"
    Returns the version of the perl binary in the current path
    """
    cmd = "perl -MConfig -e 'print $Config::Config{version}'"
    (perlversion, _) = easybuild.tools.filetools.run_cmd(cmd, log_all=True, log_output=True, simple=False)
    return perlversion
## end of FIXME

## FIXME helper function that somehow be integrated into pythonpackage or python
def osdep_det_pylibdir():
    """Determine Python library directory when Python is in osdependencies (e.g. when compiling with dummy toolchain)."""
    cmd = "python -V"
    (pyver, _) = easybuild.tools.filetools.run_cmd(cmd, log_all=True, log_output=True, simple=False)
    pyver=pyver.replace("Python ","") # strip 'Python' in front of version string
    short_pyver = '.'.join(pyver.split('.')[:2])
    return "lib/python%s/site-packages" % short_pyver
## end of FIXME


class EB_libsbml(CMakeMake):
    """Support for libsbml"""

    def __init__(self, *args, **kwargs):
        """Initialize custom class variables."""
        super(EB_libsbml, self).__init__(*args, **kwargs)

        self.matlabpath = None
        self.javaclasspath = None
        self.perlmajorversion = None
        self.libsbmlperl5lib = None
        self.pythonlibdir = None
        self.rlibs = None

    def my_det_pylibdir(self):
        # FIXME this workaround is needed to provide a proper path when using the dummy toolchain
        if 'Python' in self.cfg.dependencies():
            return easybuild.easyblocks.generic.pythonpackage.det_pylibdir()
        return osdep_det_pylibdir()

    def __setPaths(self):
        """internal function used by prepare_step() and prerun() to avoid code duplication"""
        self.matlabpath = 'lib'
        self.javaclasspath = 'share/java/libsbmlj.jar'
        self.perlmajorversion = easybuild.easyblocks.perl.get_major_perl_version()
        # the installation directory of the perl library as libsbml sees fit
        # (see libSBML-5.8.0-Source/src/bindings/perl/CMakeLists.txt)
        cmakeInstallLibdir="lib" # FIXME can we predict that CMAKE_INSTALL_LIBDIR == "lib", or should we extract it?
        self.libsbmlperl5lib = '%s/perl%s/site_perl/%s/%s' %(cmakeInstallLibdir,self.perlmajorversion,get_perl_version(),get_perl_archname())
        self.pythonlibdir = self.my_det_pylibdir() + '/libsbml'
        self.rlibs = 'lib'

    def prepare_step(self):
        """Prepare easyblock by determining Perl, Python and other's languanges paths."""
        super(EB_libsbml, self).prepare_step()
        self.__setPaths()

    def prerun(self):
        """Prepare extension by determining Perl, Python and other's languanges paths."""
        super(EB_libsbml, self).prerun()
        self.__setPaths()

    def make_module_extra(self):
        """Add path for various language bindings"""
        deps = [dep['name'] for dep in self.cfg.dependencies()]
        deps += self.cfg['osdependencies']
        txt = super(EB_libsbml, self).make_module_extra()
        if 'Java' in deps:
            txt += self.moduleGenerator.prepend_paths("CLASSPATH"  , [self.javaclasspath])
        if 'MATLAB' in deps:
            txt += self.moduleGenerator.prepend_paths("MATLABPATH" , [self.matlabpath])
        if 'Perl' in deps:
            txt += self.moduleGenerator.prepend_paths("PERL%sLIB" % self.perlmajorversion, [self.libsbmlperl5lib])
        if 'Python' in deps:
            txt += self.moduleGenerator.prepend_paths("PYTHONPATH" , [self.pythonlibdir])
        if 'R' in deps:
            txt += self.moduleGenerator.prepend_paths("R_LIBS_USER", [self.rlibs])
        return txt
