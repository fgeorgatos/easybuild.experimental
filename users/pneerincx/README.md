# EasyConfig generator for R #

This dir contains an R script **generateEasyconfig.R** which can create an EasyConfig from an existing R installation.
The generated EasyConfig will contain any packages you had installed and which are available from CRAN or BioConductor repo's.
Dependencies of R packages on other R packages are resolved and the generated EasyConfig will list them in the correct order.
If you have R packages from elsewhere you may have to tweak the generator.

## Graphics capabilities - plotting ##

The generator assumes you will want an R with graphics capabilities for plotting. 
File formats supported include PNG, JPEG, TIFF and PDF.
Therefore it includes dependencies on EasyConfigs for various graphics and compression libs.

## Graphics capabilities - X11 ##

Support for X11 was disabled as the required libs are often missing from *"headless"* compute nodes in a cluster, 
which will cause trouble when you compile on a user interface / login node with X11 libs and then try to execute a job on an execution node without X11. 
If you do want X11 capabilities and the required libs are available on all machines in your compute environment you can enable X11 and it should work without problems.
You'll need to modify generateEasyconfig.R to enable X11 support by removing `--with-x=no` from the configopts.

## System / OS dependencies ##

The generator resolves installed R packages, but it does not resolve System / OS dependencies or dependencies on other EasyConfigs... 
Hence you may have to tweak the currently hardcoded ''dependencies'' section to add/update additional dependencies.

## EasyConfig dependencies ##

The generated EasyConfig for R will have dependencies on a bunch of other EasyConfigs.
 * The ones that are already available from the official EasyBuild repos / releases at the time of writing are not included here.
 * The ones that are not (yet) available from the official EasyBuild repos / releases are included here; 
   These can either be completely new or patched compared to what is available from the EasyBuild repo @ https://github.com/hpcugent/easybuild-easyconfigs.

## R package repo URLs ##

The generator will fetch the CRAN and BioConductor repo URLs from which the packages can be downloaded. Some may be http URLs whereas others may be https URLs by default.
The https URLs are automatically converted into http URLs, because the https ones may give SSL verification errors when your Python version is too old.
If you do want to use https, you can disable the http -> https conversion in the generator and supply a more modern version of Python as build dependency.

## Creating an EasyConfig for a new R version

There's more than one way to do it. Below is the checklist used @ UMCG. This checklist assumes you have 
 * Already installed EasyBuild
 * A cloned copy of the easybuild-easyconfigs repo in `${HOME}/git/`.

In the steps below **bash>** and **R>** are prompts for bash and R sessions, respectively.
The steps below are based on an example to create an EasyConfig for R 3.3.3 based on an existing one for R 3.2.1:

 * Create a temporary development version (that will be deleted afterwards) based on an existing EasyConfig for the most current R version.
   Therefore copy an existing EasyConfig and add `dev` as version suffix to the file name
   ```
   bash> cd git/easybuild-easyconfigs/easybuild/easyconfigs/
   bash> cp r/R/R-3.2.1-foss-2015b.eb  r/R/R-3.3.3-dev-foss-2015b.eb
   ```
 * Use text editor of your choice to update the version number and add `versionsuffix = '-dev'` in r/R/R-3.3.3-dev-foss-2015b.eb.
   ```
   version = '3.3.3'
   versionsuffix = '-dev'
   ```
 * Load EasyBuild and deploy development R version.
   ```bash
   bash> module load EasyBuild
   bash> eb --robot --robot-paths="${HOME}/git/easybuild-easyconfigs/easybuild/easyconfigs/" r/R/R-3.3.3-dev-foss-2015b.eb
   ```
 * Load the temporary ''dev'' R version and start an R session
   ```bash
   bash> module load R/3.3.3-dev-foss-2015b
   bash> R
   ```
 * Update R packages from CRAN
   ```R
   R> update.packages(ask = FALSE, checkBuilt = TRUE)
   ```
 * Optionally add additional R packages from CRAN
   ```R
   R> install.packages(c('someRpackage', 'anotherPackage', 'oneMore'),  dependencies = TRUE)
   ```
 * Update R packages from BioConductor
   ```R
   R> source('https://bioconductor.org/biocLite.R')
   R> biocLite('BiocUpgrade')
   ```
 * Optionally add additional R packages from BioConductor
   ```R
   R> biocLite(c('bioConductoRpackage', 'anotherBioConPackage'))
   ```
 * With the development R version loaded, generate a new easyconfig
   ```bash
   bash> ./generateEasyConfig.R --tc foss-2015b --od ${HOME}
 * Review the generated easyconfig and if Ok, move to repo dir
   ```bash
   bash> mv ${HOME}/R-3.3.3-foss-2015b.eb ${HOME}/git/easybuild-easyconfigs/easybuild/easyconfigs/
   ```
 * Deploy new R
   ```bash
   bash> module load EasyBuild
   bash> eb --robot --robot-paths="${HOME}/git/easybuild-easyconfigs/easybuild/easyconfigs/" r/R/R-3.3.3-foss-2015b.eb
   ```
 * Delete development version.
   Exact commands will depend on how your environment is configured, but make sure to delete both the directory in which the development R version was installed as well as the generated module file (and optionally symlinks) for your module system.
   If you use Lmod as module system and use caches make sure to also update the cache.
