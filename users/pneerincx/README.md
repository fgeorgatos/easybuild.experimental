# EasyConfig generator for R #

This dir contains an R script **generateEasyconfig.R** which can create an EasyConfig from an existing R installation.
The generated EasyConfig will contain any packages you had installed and which are available from CRAN or BioConductor repo's.
Dependencies of R packages on other R packages are resolved and the generated EasyConfig will list them in the correct order.
If you have R packages from elsewhere you may have to tweak the generator.

## Graphics capabilities - plotting ##

The generator assumes you will want an R with graphics capabilities for plotting. Therefore it includes dependencies on easyconfigs for various libs. 
For libpng-1.6.17 and freetype-2.6 I had to create new easyconfigs and patches as these libs contain bugs and some R packages fail to compile with the plain vanilla libs.
I'll create a pull request for these new easyconfigs, but it will take some time before these are available from the latest and greatest EasyBuild release...
For the impatient I've added the additional EasyConfigs to this this repo. Finally I've added the R-3.2.1-goolf-1.7.20.eb, which I created with generateEasyConfig.R for our cluster as an example of what the generated EasyConfig looks like.

## Graphics capabilities - X11 ##

I disabled X11 as the required libs are often missing from "headless" compute nodes in a cluster, 
which will cause trouble when you compile on a user interface / login node with X11 libs and then try to execute a job on an execution node without X11. 
The issue is that X11 packages install various "add-ons" for example with regard to font handling. 
Once you compile with that enabled you will also need it when you create plots on a node and save them directly to a file.
If you do want X11 capabilities and the required libs are available on all machines in your compute environment you can enable X11 and it should work without problems.
You'll need to modify generateEasyconfig.R to enable X11 support by removing ''--with-x=no'' from the configopts.

## System / OS dependencies ##

The generator resolves installed R packages, but it does not resolve System / OS dependencies... 
Hence you may have to tweak the currently hardcoded ''dependencies'' section to add/update additional dependencies on other EasyConfigs.


