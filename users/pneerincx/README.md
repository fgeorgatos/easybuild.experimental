# EasyConfig generator for R #

This dir contains an R script **generateEasyconfig.R** which can create an EasyConfig from an existing R installation.
The generated EasyConfig will contain any packages you had installed and which are available from CRAN or BioConductor repo's.
Dependencies of R packages on other R packages are resolved and the generated EasyConfig will list them in the correct order.
If you have R packages from elsewhere you may have to tweak the generator.

## Graphics capabilities - plotting ##

The generator assumes you will want an R with graphics capabilities for plotting. Therefore it includes dependencies on EasyConfigs for various libs. 

## Graphics capabilities - X11 ##

Support for X11 was disabled as the required libs are often missing from "headless" compute nodes in a cluster, 
which will cause trouble when you compile on a user interface / login node with X11 libs and then try to execute a job on an execution node without X11. 
If you do want X11 capabilities and the required libs are available on all machines in your compute environment you can enable X11 and it should work without problems.
You'll need to modify generateEasyconfig.R to enable X11 support by removing ''--with-x=no'' from the configopts.

## System / OS dependencies ##

The generator resolves installed R packages, but it does not resolve System / OS dependencies... 
Hence you may have to tweak the currently hardcoded ''dependencies'' section to add/update additional dependencies.

## EasyConfig dependencies ##

The generated EasyConfig for R will have dependencies on a bunch of other EasyConfigs.
 * The ones that are already available from the official EasyBuild repos / releases at the time of writing are not included here.
 * The ones that are not (yet) available from the official EasyBuild repos / releases are included here; 
   These can either be completely new or patched compared to what is available from the EasyBuild repos.

