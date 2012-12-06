# This file is an EasyBuild recipy as per https://github.com/hpcugent/easybuild
#
# Copyright:: Copyright (c) 2012 University of Luxembourg / LCSB
# Author::    Cedric Laczny <cedric.laczny@uni.lu>, Fotis Georgatos <fotis.georgatos@uni.lu>
# License::   MIT/GPL
# File::      $File$ 
# Date::      $Date$


##
# Copyright 2009-2012 Stijn De Weirdt, Dries Verdegem, Kenneth Hoste, Pieter De Baets, Jens Timmerman
#
# This file is part of EasyBuild,
# originally created by the HPC team of the University of Ghent (http://ugent.be/hpc).
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
# import os
# import shutil
# from easybuild.framework.application import Application
# from easybuild.tools.filetools import unpack, patch, run_cmd, convertName


import fileinput
import glob
import re
import os
import shutil
import sys
from distutils.version import LooseVersion

import easybuild.tools.toolchain as toolchain
from easybuild.framework.easyblock import EasyBlock
from easybuild.framework.easyconfig import CUSTOM
from easybuild.tools.filetools import run_cmd
from easybuild.tools.modules import get_software_root, get_software_version

class EB_Cufflinks(EasyBlock):
    """
    Support for building cufflinks (Transcript assembly, differential expression, and differential regulation for RNA-Seq)
    """

    def build_step(self):
	"""
	First we need to rename a few things, s.a. http://wiki.ci.uchicago.edu/Beagle/BuildingSoftware -> "Cufflinks"
	"""
	cmd = "for x in src/*.cpp src/*.h; do sed \'s/foreach/for_each/\' $x > src/x; mv src/x $x; done"
	run_cmd(cmd, log_all=True, simple=True)

	cmd = "sed \'s/#include <boost\/for_each.hpp>/#include <boost\/foreach.hpp>/\' src/common.h > src/x && mv src/x src/common.h"
	run_cmd(cmd, log_all=True, simple=True)

	super(EB_Cufflinks, self).build_step()


    def sanity_check_step(self):
        pass

