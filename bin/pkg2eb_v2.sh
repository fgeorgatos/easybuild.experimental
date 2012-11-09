#!/bin/bash
# This file is a tool to produce EasyBuild recipies as per https://github.com/hpcugent/easybuild
# There is no warranty, provided AS-IS, etc
#
# Copyright:: Copyright (c) 2012 University of Luxembourg / LCSB
# Author::    Fotis Georgatos <fotis.georgatos@uni.lu>
# License::   MIT/GPL
# Date::      20121109
# File::      pkg2eb_v2.sh

# Disclaimer:
# This code is NOT to be used as an example in anything; it is just quick'n'dirty prototype work to produce easybuild files using as source any pkgsrc Makefile

OUTPUTDIR=$HOME/arena/pkg2eb/outdir_v2

# Source initial information from file indicated by $1 parameter

EXTRACT_SUFX=.tar.gz
eval `grep ^HOMEPAGE $1     | sed "s/[[:space:]]//g"|tr / ^`
eval `grep ^EXTRACT_SUFX $1 | sed "s/[[:space:]]//g"`
eval `grep ^COMMENT $1      | tr ' ()""' '_____'|tr "'" "_"|sed "s/[[:space:]]//g" `
eval `grep ^PKGNAME $1      | sed "s/[[:space:]]//g"`
eval `grep ^DISTNAME $1     | sed "s/[[:space:]]//g"`

# This could be a way to ensure a DISTNAME as alternative to PKGNAME
# - commented out for now since it has been proven to be not reliable enough
# [ "$PKGNAME" ] && DISTNAME=$PKGNAME

# The following ones are fairly critical since they define the package name, version and output file
# Unfortunately, the code has to make some poor assumption as regards the format of the name at source
export PKGNAME=${PKGNAME:-"`echo $DISTNAME|cut -d- -f1`"}
export PKGVERSION=${PKGVERSION:-"`echo $DISTNAME|cut -d- -f2-`"}

export DISTFILE=$DISTNAME.eb
export FIRSTLETTER=`echo $DISTFILE|cut -c1|tr 'A-Z0-9!@#$%^&*()_+' 'a-z0000000000000000000000000'` # This ensures that information gets distributed a bit across directories
export OUTPUTFILE=$OUTPUTDIR/$FIRSTLETTER/$DISTFILE

(
cat <<EOF1
# This file is an EasyBuild recipy as per https://github.com/hpcugent/easybuild
# It has been automatically produced by $0 ; ie. there is no warranty, given AS-IS, etc
#  
#  #######                     ######                                    ### 
#  #         ##    ####  #   # #     # #    # # #      #####     # ##### ### 
#  #        #  #  #       # #  #     # #    # # #      #    #    #   #   ### 
#  #####   #    #  ####    #   ######  #    # # #      #    #    #   #    #  
#  #       ######      #   #   #     # #    # # #      #    #    #   #       
#  #       #    # #    #   #   #     # #    # # #      #    #    #   #   ### 
#  ####### #    #  ####    #   ######   ####  # ###### #####     #   #   ###
#  
# Copyright:: Copyright (c) 2012 University of Luxembourg / LCSB
# Author::    Fotis Georgatos <fotis.georgatos@uni.lu>
# License::   MIT/GPL
# File::      $DISTFILE
# Date::      `date`

EOF1

echo "# The following values are best-guess, which may be further overriden on"
echo "name = '$PKGNAME'"
echo "version = '$PKGVERSION'"
echo "versionsuffix = '-"`date --rfc-3339=date`"'" # Put the timestamp of the current day, in order to organize better multiple successive builds
echo

echo "# The following are automatically calculated - cross fingers"
cat $1 \
  |sed "s/[[:space:]]*//g" \
  |sed "s/^PKGNAME=\([[:alnum:]]*\)-\(.*\)/__version = '\2' __name = '\1'/g" \
  |sed "s/^DISTNAME=\(.*\)/__sources = \['\1$EXTRACT_SUFX'\]/g" \
  |sed "s/^MASTER_SITES=\(.*\)\\\\/MASTER_SITES=\1/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_SOURCEFORGE:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_SOURCEFORGE_JP:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_GNU:=\(.*\)}/MASTER_SITES=http:\/\/ftp.gnu.org\/gnu\/$PKGNAME/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_PERL_CPAN:=\(.*\)}/MASTER_SITES=http:\/\/ftp.nluug.nl\/languages\/perl\/CPAN\/\1/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_XORG:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_GNOME:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_LOCAL:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_KDE_I18N:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_SUNSITE:=\(.*\)}/MASTER_SITES=http:\/\/ftp.nluug.nl\/sunsite\/\1/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_XCONTRIB:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_DEBIAN:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_BACKUP:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_APACHE:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_KDE:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_GENTOO:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_FREEBSD:=\(.*\)}/MASTER_SITES=http:\/\/ftp.nluug.nl\/os\/FreeBSD\/\1/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_TEX_CTAN:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\${MASTER_SITE_MOZILLA_ALL:=\(.*\)}/MASTER_SITES=http:\/\/sourceforge.net\/projects\/\1\/files', 'download/g" \
  |sed "s/^MASTER_SITES=\(.*\)/MASTER_SITES=\['\1'\]/g" \
  |sed "s/^MASTER_SITES=/__source_urls = /g" \
  |sed "s/^HOMEPAGE=\(.*\)/__homepage = '\1'/g" \
  |sed "s/\${HOMEPAGE}/$HOMEPAGE/g" \
  |grep ^__ \
  |sed 's/^__//g;s/ __/%/g' \
  |sed "s/\/\/files/\/files/g" \
  |tr '^%' '/\n'

cat <<EOF2

toolchain = {'name': 'goalf', 'version': '1.1.0-no-OFED'}
toolchainopts = {'optarch': True, 'pic': True}

# This has eventually to be amended with the real values of files/directories, as needed on a per package basis
# Such incomplete easyconfigs are OK for repo https://github.com/fgeorgatos/easybuild.experimental but not for production EasyBuild
# In case you decide to commit/push your experimental easyconfigs, remember to place them under users/$YourGithubUsername

sanity_check_paths = {
                  'files': [],
                  'dirs': ['.']
                 }

description = "$DISTNAME description: $COMMENT"

# we play conservative in compilation parallelism, to maximize chances of success on the compilation step

parallel = 1 
maxparallel = 1 

moduleclass = 'base'

EOF2

echo ###### The appended information is the pkgsrc sourcefile: $1 ######
sed "s/^/# /g" $1

) |tee $OUTPUTFILE| wc -l | ( echo Resulting file has `cat` lines and is available at: $OUTPUTFILE)

# That's all folks!

