# This file is an EasyBuild recipy as per https://github.com/hpcugent/easybuild
#
# Copyright:: Copyright (c) 2012 University of Luxembourg / LCSB
# Author::    Cedric Laczny <cedric.laczny@uni.lu>, Fotis Georgatos <fotis.georgatos@uni.lu>
# License::   MIT/GPL
# File::      $File$ 
# Date::      $Date$

import os
import shutil

from easybuild.framework.easyblock import EasyBlock
from easybuild.tools.filetools import run_cmd

class EB_Cufflinks(EasyBlock):
    """
    Support for building cufflinks (Transcript assembly, differential expression, and differential regulation for RNA-Seq)
    """

    def patch_step(self):
	"""
	First we need to rename a few things, s.a. http://wiki.ci.uchicago.edu/Beagle/BuildingSoftware -> "Cufflinks"
	"""
	cmd = "for x in src/*.cpp src/*.h; do sed \'s/foreach/for_each/\' $x > src/x; mv src/x $x; done"
	run_cmd(cmd, log_all=True, simple=True)

	cmd = "sed \'s/#include <boost\/for_each.hpp>/#include <boost\/foreach.hpp>/\' src/common.h > src/x && mv src/x src/common.h"
	run_cmd(cmd, log_all=True, simple=True)

	super(EB_Cufflinks, self).patch_step()


    def sanity_check_step(self):
        pass

