#!/usr/bin/env Rscript

#
# Hard-coded list of R package repositories.
#
#  * Active URLs are used for checking if a package may have been retrieved from that repo.
#  * Archive URLs cannot be used by R commands to query the repo, 
#    but will be added to the EasyConfig and will be used by EasyBuild to try to download packages from.
#
repos = list()
repos$cran$active = c('http://cran.r-project.org/src/contrib/')
repos$cran$archive = c('http://cran.r-project.org/src/contrib/Archive/%(name)s')
repos$bioconductor$active = c('http://www.bioconductor.org/packages/release/bioc/src/contrib/',
    'http://www.bioconductor.org/packages/release/data/annotation/src/contrib/',
    'http://www.bioconductor.org/packages/release/data/experiment/src/contrib/')

#
##
### Setup environment
##
#
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(logging))
logging::basicConfig()

#
##
### Custom functions
##
#
usage <- function() {
    cat("
Description: 
    Generates an EasyBuild EasyConfig file from an existing R environment.
    Optionally you can first load a specific version of R using module load before generating the *.eb EasyConfig

Example usage:
    module load EasyBuild
    module load R
    generateEasyConfig.R  --tc  goolf/1.7.20 \\
                          --od  /path/to/my/EasyConfigs/r/R/ \\
                          --ll  WARNING 

Explanation of options:
    --tc toolchain/version  EasyBuild ToolChain (required).
                               To get a list of available toolchains (may or may not be already installed):
                                   module load EasyBuild
                                   eb --list-toolchains
                               To check if a toolchain is already installed and if yes which version is the default:
                                   module -r -t avail -d '^name_of_toolchain$'
    --od path               Output Directory where the generated *.eb EasyConfig file will be stored (optional).
                               Will default to the current working directory as determined with getwd().
                               Name of the output file follows strict rules 
                               and is automatically generated based on R version and toolchain.
    --ll LEVEL              Log level (optional).
                               One of FINEST, FINER, FINE, DEBUG, INFO (default), WARNING, ERROR or CRITICAL.
")
    q()
}

#
# For a list of R packages:
#  * Retrieve from a working R installation the package versions
#  * Re-order the packages based on their dependencies based on "Depends", "LinkingTo" and "Imports"
#  * Try to figure out which repo (or mirror) the package originated from using a list of known repos. 
#
# Arguments:
#  * packages: A vector with package names (i.e. c('ggplot2', 'RMySQL', 'stringer'))
#  * repos:    One or more repositories used by packageStatus() to retrieve information on available packages.

getPackageTree <- function(packages, repos) {
    
    #
    # Local helper function to extract plain package names 
    # from "Depends", "LinkingTo" and "Imports" statements like for example:
    #    Depends: R (≥ 3.0.2)
    #    Imports: evaluate (≥ 0.6), digest, formatR, highr, markdown, stringr (≥ 0.6), yaml (≥ 2.1.5), tools
    #
    getNamesOnly <- function(string) {
        messyPackages <- strsplit(string, ',\\s*', perl=TRUE)
        packageNames <- lapply(messyPackages[[1]], function(x) {return(strsplit(x, '[\\s(]', perl=TRUE)[[1]][1])})
        return(unlist(packageNames))
    }
    
    #
    # Local helper function to extract repo name from one of the repo URLs.
    getRepoName = function(repo.url) {
        repo.name = str_match(repo.url, '(cran)|(bioconductor)')[[1]][1]
        return(repo.name)
    }
    
    #
    # Local helper function to recursively retrieve a list of all dependencies for a given R package.
    #
    # Arguments:
    #  * packageName:            Name of a single package.
    #  * packageStatusOverview:  The object returned by packageStatus()
    # Returns:
    #  * packageTree:            Character vector with package names, their versions and the repo in which the package was found.
    
    getDependencies <- function (packageName, packageStatusOverview) {
        
        packageIndex <- match(packageName, names(packageStatusOverview$inst$Package))  
        if (is.na(packageIndex)) {
            logging::levellog(loglevels[['FATAL']], paste('Package', packageName, 'is not installed. Aborting!'))
            usage()
        }
        
        dependencies <- c(getNamesOnly(packageStatusOverview$inst$Depends[packageIndex]), 
                          getNamesOnly(packageStatusOverview$inst$Imports[packageIndex]), 
                          getNamesOnly(packageStatusOverview$inst$LinkingTo[packageIndex]))
        dependencies <- dependencies[!is.na(dependencies)] 
        
        logging::levellog(loglevels[['FINE']], paste('Package name:', packageName))
        logging::levellog(loglevels[['FINE']], paste('Dependencies:', paste(dependencies, collapse=', ')))
        logging::levellog(loglevels[['FINE']], '-----------------------------------------------')
        
        # don't need the base packages
        packageID <- match(dependencies, packageStatusOverview$inst$Package)
        isBase <- packageStatusOverview$inst$Priority[packageID] == 'base'
        isBase[is.na(isBase)] <- FALSE
        
        # take out 'R'
        cleanDeps <- dependencies[!isBase & dependencies != 'R']
        
        # let's recurse 
        if (length(cleanDeps) == 0) {
            # no more dependencies. We terminate returning package name
            return(packageName)
        } else {
            # recurse
            deps <- unlist(lapply(cleanDeps, getDependencies, packageStatusOverview))
            allDeps <- unique(c(deps, packageName))
            return (allDeps)
        }
    }
    
    logging::levellog(loglevels[['DEBUG']], 'Retrieving status overview of all installed packages...')
    
    #
    # Change available_packages_filters.
    #
    # Default: options(available_packages_filters = c("R_version", "OS_type", "subarch", "duplicates"))
    # This will fail to report packages when
    #  * They have been updated in the repo's after they were installed locally 
    #  * and the updated version of the packages has a dependency on a more recent R version.
    # The older version of the package as installed locally may still be available from a sub folder of the repo
    # like for example http://cran.r-project.org/src/contrib/Archive/... 
    # but these archive folders lack a PACKAGES.gz file, 
    # which is required for packageStatus() to figure out what is available.
    #
    options(available_packages_filters = c("OS_type", "duplicates"))
    
    #
    # Get status of all packages (installed and available) and append column for repo.
    #
    flattenedNames <- names(unlist(repos, recursive = FALSE, use.names = TRUE))
    activeRepoURLs <- unlist(subset(unlist(repos, recursive = FALSE, use.names = TRUE), grepl('.active', flattenedNames)), use.names=FALSE)
    packageStatusOverview <- packageStatus(repositories = activeRepoURLs)
    packageStatusOverview$inst$Repo <- rep(NA, nrow(packageStatusOverview$inst))
    logging::levellog(loglevels[['DEBUG']], 'Trying to figure out which repo(s) the installed package originated from...')
    
    for (this.package in rownames(packageStatusOverview$inst)) {
        logging::levellog(loglevels[['DEBUG']], paste('This package name:', this.package))
        isBase <- packageStatusOverview$inst$Priority[this.package] == 'base'
        isBase[is.na(isBase)] <- FALSE
        if (isBase) {
            packageStatusOverview$inst[this.package,]$Repo = 'base'
        } else {
            for (this.repo in names(summary(packageStatusOverview)$Repos)) {
                logging::levellog(loglevels[['FINEST']], paste(':       repo URL:', this.repo))
                logging::levellog(loglevels[['FINEST']], paste(':          names:', paste(names(summary(packageStatusOverview)$Repos[[this.repo]]), collapse=', ')))
                packages.installed_from_this_repo = as.list(summary(packageStatusOverview)$Repos[[this.repo]])$installed
                if (is.element(this.package, packages.installed_from_this_repo)) {
                    logging::levellog(loglevels[['FINE']], paste(':     found pkg in:', this.repo))
                    packageStatusOverview$inst[this.package,]$Repo = getRepoName(this.repo)
                }
            }
        }
        logging::levellog(loglevels[['DEBUG']], paste(':            repo:', packageStatusOverview$inst[this.package,]$Repo))
    }
    
    #
    # Recursively find installed packages and their dependencies (Names only).
    #
    allPackages.names <- unique(unlist(lapply(packages, getDependencies, packageStatusOverview)))
    allPackages.IDs = match(allPackages.names, packageStatusOverview$inst$Package)
    
    #
    # Report packages.
    #
    colsOfInterest <- c("Package", "Version", "Repo")
    colIDs <- match(colsOfInterest, names(packageStatusOverview$inst))
    allPackages.df <- packageStatusOverview$inst[allPackages.IDs, colIDs]
    
    return(allPackages.df)
}

writeEC <- function (fh, version, packages, repos, toolchain.name, toolchain.version) {
    
    writeLines("
#
# This EasyBuild config file for R was generated with generateEasyConfig.R
#
", fh)
    writeLines("name = 'R'", fh)
    writeLines(paste("version = '", version, "'", sep=''), fh)
    writeLines("homepage = 'http://www.r-project.org/'", fh)
    writeLines('description = """R is a free software environment for statistical computing and graphics."""', fh)
    writeLines("moduleclass = 'lang'", fh)
    this.line = paste("toolchain = {'name': '", toolchain.name, "', 'version': '", toolchain.version, "'}", sep='')
    writeLines(this.line, fh)
    writeLines("
sources = [SOURCE_TAR_GZ]
source_urls = ['http://cran.us.r-project.org/src/base/R-%(version_major)s']

#
# Configure options.
#
# NOTE: LAPACK support is built into BLAS, which will be detected correctly when LAPACK_LIBS is *not* specified.
#       The summary at the end of the configure output should contain:
#           External libraries: ...., BLAS(OpenBLAS), LAPACK(in blas), ....
#
#preconfigopts = 'BLAS_LIBS=\"$LIBBLAS\" LAPACK_LIBS=\"$LIBLAPACK\"'
preconfigopts = 'BLAS_LIBS=\"$LIBBLAS\"'
configopts = '--with-lapack --with-blas --with-pic --enable-threads --with-x=no --enable-R-shlib'
configopts += ' --with-tcl-config=$EBROOTTCL/lib/tclConfig.sh --with-tk-config=$EBROOTTK/lib/tkConfig.sh '

#
# Enable graphics capabilities for plotting.
#
configopts += ' --with-cairo --with-libpng --with-jpeglib --with-libtiff'
#
# Some recommended packages may fail in a parallel build (e.g. Matrix) and we're installing them anyway below.
#
configopts += ' --with-recommended-packages=no'

#
# You may need to include a more recent Python to download R packages from HTTPS based URLs
# when the Python that comes with your OS is too old and you encounter:
#     SSL routines:SSL23_GET_SERVER_HELLO:sslv3 alert handshake failure
# In that case make sure to include a Python as builddependency. 
# This Python should not be too new: it's dependencies like for example on ncursus should be compatible with R's dependencies.
# For example Python 2.7.11 is too new as it requires ncurses 6.0 whereas our R requires ncurses 5.9.
# The alternative is to replace the https URLs with http URLs in the generated EasyConfig.
#
#builddependencies = [
#    ('Python', '2.7.10')
#]

dependencies = [
    ('libreadline', '6.3'),
    ('ncurses', '5.9'),
    ('bzip2', '1.0.6'),
    ('XZ', '5.2.2'),
    ('libpng', '1.6.21'),            # For plotting in R
    ('libjpeg-turbo', '1.4.2'),      # For plotting in R
    ('LibTIFF', '4.0.4'),            # For plotting in R
    ('Tcl', '8.6.4'),                # For Tcl/Tk
    ('Tk', '8.6.4', '-no-X11'),      # For Tcl/Tk
    ('cURL', '7.47.1'),              # For RCurl
    ('libxml2', '2.9.2'),            # For XML
    ('cairo', '1.14.6'),             # For plotting in R
    ('Java', '1.8.0_45', '', True),  # Java bindings are built if Java is found, might as well provide it.
    ('PCRE', '8.38'),                # For rphast package.
    ('GMP', '6.1.1'),                # for igraph
]

package_name_tmpl = '%(name)s_%(version)s.tar.gz'
", fh)
    
    for (this.repo in names(repos)) {
        writeLines(paste(this.repo, '_options = {', sep=''), fh)
        writeLines("    'source_urls': [", fh)
        forget.this = lapply(unlist(repos[this.repo]), 
                function(url) {
                    #
                    # Switch any https URLs to insecure http.
                    # If you do want to use https make sure you have a recent Python in your build environment.
                    # See also note on builddependencies above...
                    #
                    url = sub('https:', 'http:', url)
                    writeLines(sprintf("        '%s',", url), fh)
                }
        )
        writeLines("    ],
    'source_tmpl': package_name_tmpl,
}
", fh)
    }
    
    writeLines("
#
# R package list.
#   * Order of packages is important!
#   * Packages should be specified with fixed versions!
#
exts_list = [
        # 
        # Default libraries; only here to sanity check their presence.
        #", fh)
    
    forget.this = lapply(unlist(subset(packages, Repo == 'base')$Package), function(pkg) {writeLines(sprintf("        '%s',", pkg), fh)})
    
    writeLines("        #
        # Other packages.
        #", fh)
    
    forget.this = apply(subset(packages, Repo != 'base', select=c('Package', 'Version', 'Repo')), 1,
            function(this.pkg) {
                this.pkg <- as.list(this.pkg);
                writeLines(sprintf("        ('%s', '%s', %s_options),", this.pkg$Package, this.pkg$Version, this.pkg$Repo), fh)
            }
    )
    writeLines(']',fh)

}

#
##
### Main.
##
#

#
# Read script arguments
#
cargs <- commandArgs(TRUE)
args=NULL
if(length(cargs)>0) {
    flags = grep("^--.*",cargs)
    values = (1:length(cargs))[-flags]
    args[values-1] = cargs[values]
    if(length(args)<tail(flags,1)) {
        args[tail(flags,1)] = NA
    }
    names(args)[flags]=cargs[flags]
}
arglist = c("--od", "--tc", "--ll", NA)

#
# Handle arguments required to setup logging first.
#
if (is.element('--ll', names(args))) {
    log_level = args['--ll']
    log_level.position <- which(names(logging::loglevels) == log_level)
    if(length(log_level.position) < 1) {
        logging::levellog(loglevels[['WARN']], paste('Illegal log level ', log_level, ' specified.', sep=''))
        # Use default log level.
        log_level = 'INFO'
    }
    # Use the given log level.
} else {
    # Use default log level.
    log_level = 'INFO'
}

#
# Change the log level of both the root logger and it's default handler (STDOUT).
#
logging::setLevel(log_level)
logging::setLevel(log_level, logging::getHandler('basic.stdout'))
logging::levellog(loglevels[['INFO']], paste('Log level set to ', log_level, '.', sep=''))

#
# Check other arguments.
#
wrong.flags = length(args) == 0
if (!wrong.flags) wrong.flags = !all(names(args) %in% arglist)
if (!wrong.flags) wrong.flags = is.na(args['--tc'])

if(wrong.flags) {
	if (!all(names(args) %in% arglist)) {
        logging::levellog(loglevels[['FATAL']], paste('Illegal parameter name or bad syntax for ', names(args)[!(names(args) %in% arglist)], '!', sep=''))
    }
    usage()
}

#
# Process other arguments.
#
output.dir = args['--od']
toolchain  = args['--tc']

if (is.na(args['--od'])) {
    output.dir = getwd() # default
}
if (is.na(args['--tc'])) {
    logging::levellog(loglevels[['FATAL']], 'Tool chain must be specified with --tc name/version.')
    usage()
} else { 
    toolchain <- strsplit(toolchain, '/')
    toolchain.name    = toolchain[[1]][1]
    toolchain.version = toolchain[[1]][2]
    if (is.na(toolchain.version) || is.na(toolchain.version)) {
        logging::levellog(loglevels[['FATAL']], 'Tool chain must be specified with --tc name/version.')
        usage()
    }
}

#
# Get R version.
#
R.version <- version
R.version.full = paste(get('major', R.version), get('minor', R.version), sep='.')

#
# Create a file handle.
#
logging::levellog(loglevels[['DEBUG']], 'Compiling paths and filehandles for output files...')
output.path = paste(output.dir, '/R-', R.version.full, '-', toolchain.name, '-', toolchain.version, '.eb', sep='')
logging::levellog(loglevels[['INFO']], paste('Will store EasyConfig in', output.path))
fh = file(output.path, 'w')

#
# Get list all installed packages (in alphabetic order).
#
installedPackages <- rownames(installed.packages(lib.loc = NULL, priority = NULL, noCache = TRUE))

#
# Supplement list of BioConductor repository URLs, which already contains the 'release' URLs, 
# with the repo URLs for the specific BioConductor version that is compatible with this version of R.
#
source("http://bioconductor.org/biocLite.R")
biocRepos <- biocinstallRepos()
biocVersionedRepos <- subset(biocRepos, grepl('bioconductor', biocRepos))
biocVersionedRepoURLs <- paste(biocVersionedRepos, '/src/contrib/', sep='')
repos$bioconductor$active <- append(repos$bioconductor$active, biocVersionedRepoURLs)

#
# Supplement list of all installed versioned packages with
#  * their version numbers
#  * their repos
# and re-order based on dependencies where applicable.
#
installedPackages   = getPackageTree(installedPackages, repos)

#
# Calculate R package stats.
#
repolessPackages    = subset(installedPackages, is.na(installedPackages$Repo))
packagesTotal       = nrow(installedPackages)
packagesUnavailable = nrow(repolessPackages)
packagesResolved    = packagesTotal - packagesUnavailable
if (packagesUnavailable > 0) {
    lapply(as.list(repolessPackages)$Package, function(repolessPackage) {
            logging::levellog(loglevels[['WARN']], paste('Failed to determine repo origin for package', repolessPackage, '.'))
        }
    )
    if (packagesUnavailable > 1) {
        logging::levellog(loglevels[['WARN']], paste('Failed to determine repo origin for', packagesUnavailable, 'packages!'))
    } else { 
        logging::levellog(loglevels[['WARN']], paste('Failed to determine repo origin for', packagesUnavailable, 'package!'))
    }
}

#
# Report R package stats.
#
nsmall = 2
numberwidth = floor(log(packagesTotal,10))+1
logging::levellog(loglevels[['INFO']], paste('=======================================================================', paste(rep('=', numberwidth), collapse=''), sep=''))
logging::levellog(loglevels[['INFO']], paste(': Total R packages processed:                                ', format(packagesTotal, width = numberwidth), sep=''))
this.percentage = round(packagesResolved / packagesTotal * 100, 2)
logging::levellog(loglevels[['INFO']], paste(':  * Resolved packages    (will be added to EasyConfig):     ', format(packagesResolved, width = numberwidth), '  (', format(this.percentage, width = 6, nsmall = nsmall), '%)', sep=''))
this.percentage = round(packagesUnavailable / packagesTotal * 100, 2)
logging::levellog(loglevels[['INFO']], paste(':  * Unavailable packages (missing from EasyConfig):         ', format(packagesUnavailable, width = numberwidth), '  (', format(this.percentage, width = 6, nsmall = nsmall), '%)', sep=''))
logging::levellog(loglevels[['INFO']], paste('=======================================================================', paste(rep('=', numberwidth), collapse=''), sep=''))

#
# Create EasyBuild EasyConfig
#
writeEC(fh, R.version.full, installedPackages, repos, toolchain.name, toolchain.version)

#
# Close file handle.
#
close(fh)

#
# We are done!
#
logging::levellog(loglevels[['INFO']], 'Finished!')

