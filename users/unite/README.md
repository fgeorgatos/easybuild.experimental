UNITE EasyBuild Package
=======================

This is a prototype implementation of the UNITE meta installer based on EasyBuild config files.
The goal of UNITE is to provide a robust, portable, and integrated environment for the debugging and performance analysis
of parallel MPI, OpenMP, and hybrid MPI/OpenMP programs on high-performance compute clusters.
It consists of a set of well-accepted portable, mostly open-source tools. 
For more details on UNITE see http://apps.fz-juelich.de/unite/

The files in this directory represent about the same set of tools as provided by the version 1.1 of the UNITE package
with the exception that the deprecated MARMOT tools is replaced by its successor MUST.

The files were only tested with GCC-4.7.3 and OpenMPI-1.6.5.
The directory "AdaptedEBconfigs/" contains some EasyConfigs I adapted to have a minimal test environment.

The config files follow a "minimal dependency" policy, i.e. non-parallel (non-MPI) components were only build with GCC not with the full gompi toolchain.
If you do not like this, there should be no problem rebuilding these components with the gompi toolchains.

There are still some issues and non-portable aspects in this version of the files.
I tried to document everything with structured comments of the following form:

1) # --- BM CONFIGOPTS ---

   Some packages require extra/different configure lines when compiled with different toolchains.
   Basic information is provided in the comments, for full documentation see the component documentation

2) # --- BM ISSUE ---

   Some open issue which works in the original UNITE package but is not specified correctly in the easyconfig file.
   See comment for explanations

3) # --- BM LIB64 ---

   Special issue where on different Linux distros libraries get created in different paths (lib vs. lib64 vs. libexec)
   This affects mostly sanity_checks but also other items. Look for these if you see errors related to lib/lib64 issues.

4) # --- BM EXTENSIONS ---

   Extra stuff that also could be implemented like CUDA support, basic information on how to get it started provided
   by the comment


Any feedback, additions, corrections, requests, comments on this package welcome!

Bernd Mohr
b.mohr@fz-juelich.de
