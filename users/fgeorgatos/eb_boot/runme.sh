#!/bin/bash --posix -fx
#
# This script relies upon a fake modulecmd using canned (surrogate) responses,
# and allows you to setup EasyBuild without needing env-modules as a prereq
#
# Copyright:: Copyright 2014 NTUA
# Authors::   Fotis Georgatos <fotis@cern.ch>
# License::   MIT/GPL
# $Id$

EASYBUILD_FORCE=yes
PATH=$HOME/bin:$PATH

#export PYTHONPATH=$HOME/.local/easybuild/software/EasyBuild/1.16.1/lib/python2.7/site-packages
export PYTHONPATH=$HOME/.local/easybuild/software/EasyBuild/2.0.0/lib/python2.7/site-packages

curl -O https://raw.githubusercontent.com/hpcugent/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py
python bootstrap_eb.py $HOME/.local/easybuild

##echo '$PYTHONPATH='$PYTHONPATH
##modulecmd avail
