INSTALLATION (Jul03)             deitab             INSTALLATION (Jul03)



                   DEITAB: DEIMOS TABLE FORMAT TOOLS
              Release Notes and Installation Instructions



SUMMARY
The  DEITAB  external package is used to convert Deimos pipeline reduced
2D table format to multiextension image format.  It also allows applying
the 2D pipeline reduced dispersion solution to extracted 1D spectra.



RELEASE INFORMATION
The  following  summary  only  highlights the major changes.  There will
also be minor changes and bug fixes.


V1.1: July 30, 2003
    The keyword CUNIT1="Angstroms" is added to each extension  extracted
    from the table in order to correctly propagate the units.

V1.1: July 25, 2003
    The  table  header  keywords, excluding table specific ones, are now
    copied to the image header.

V1.0: July 16, 2003
    First version.


INSTALLATION INSTRUCTIONS
Installation of this external package consists of obtaining  the  files,
creating  a  directory to contain the package, compiling the executables
or installing precompiled executables, and defining the  environment  to
load  and  run  the package.  The package may be installed for a site or
as a personal installation.  If you need help  with  these  installation
instructions   contact   iraf@noao.edu  or  call  the  IRAF  HOTLINE  at 
520-318-8160.

[arch]
    In the following steps you will need to know the  IRAF  architecture
    identifier  for  your IRAF installation.  This identifier is similar
    to the host operating system type.  The identifiers are things  like
    "ssun"  for  Solaris, "alpha" for Dec Alpha, and "linux" or "redhat"
    for  most  Linux  systems.   The  IRAF  architecture  identifier  is 
    defined when you run IRAF.  Start the CL and then type
    
        cl> show arch
        .ssun
    
    This is the value you need to know without the leading '.'; i.e. the
    IRAF architecture is "ssun" in the above example.

[1-site]
    If you are installing the package for site use, login  as  IRAF  and
    edit the IRAF file defining the packages.
    
        % cd $hlib
    
    Define  the  environment  variable  deitab to be the pathname to the
    deitab package root directory.  The '$' character  must  be  escaped
    in  the  VMS  pathname  and UNIX pathnames must be terminated with a
    '/'.  Edit extern.pkg to include the following.
    
        reset deitab = /local/deitab/
        task  deitab.pkg = deitab$deitab.cl
    
    Near the end of the hlib$extern.pkg file, update the  definition  of
    helpdb  so  it includes the deitab help database, copying the syntax
    already  used  in  the  string.   Add  this  line  before  the  line 
    containing a closing quote:
    
        ,deitab$lib/helpdb.mip\

[1-personal]
    If  you  are  installing  the package for personal use define a host
    environment variable with the pathname of the  directory  where  the
    package  will  be located (needed in order to build the package from
    the source code).  Note that  pathnames  must  end  with  '/'.   For
    example:
    
        % setenv deitab /local/deitab/
    
    In your login.cl or loginuser.cl file make the following definitions
    somewhere before the "keep" statement.
    
        reset deitab = /local/deitab/
        task  deitab.pkg = deitab$deitab.cl
        printf ("reset helpdb=%s,deitab$lib/helpdb.mip\nkeep\n",
            envget("helpdb")) | cl
        flpr
    
    If you will be compiling the package, as  opposed  to  installing  a
    binary  distribution,  then  you  need to define various environment
    variables.   The  following  is  for  Unix/csh  which  is  the  main 
    supported environment.
    
        # Example
        % setenv iraf /iraf/iraf/             # Path to IRAF root (example)
        % source $iraf/unix/hlib/irafuser.csh # Define rest of environment
        % setenv IRAFARCH ssun                # IRAF architecture
    
    where   you  need  to  supply  the  appropriate  path  to  the  IRAF 
    installation root in  the  first  step  and  the  IRAF  architecture
    identifier for your machine in the last step.

[2] Login  into  IRAF.   Create a directory to contain the package files
    and the  instrument  database  files.   These  directory  should  be
    outside the standard IRAF directory tree.
    
        cl> mkdir deitab$
        cl> cd deitab

[3] The  package is distributed as a tar archive for the sources and, as
    an optional convenience,  a  tar  archive  of  the  executables  for
    select  host  computers.  Note that IRAF includes a tar reader.  The
    tar file(s) are most commonly obtained via anonymous ftp.  Below  is
    an  example  from a Unix machine where the compressed files have the
    ".Z"  extension.   Files  with  ".gz"  or  ".tgz"  can  be   handled 
    similarly.
    
        cl> ftp iraf.noao.edu (140.252.1.1)
        login: anonymous
        password: [your email address]
        ftp> cd iraf/extern
        ftp> get deitab.readme
        ftp> binary
        ftp> get deitab.tar.Z
        ftp> get deitab-bin.<arch>.Z  (optional)
        ftp> quit
        cl> !uncompress deitab.tar
        cl> !uncompress deitab-bin.<arch> (optional)
    
    The  readme  file  contains  these  instructions.  The <arch> in the
    optional  executable  distribution   is   replaced   by   the   IRAF 
    architecture identification for your computer.
    
    Upon  request  the  tar file(s) may be otained on tape for a service
    charge.  In this case you would mount the tape use rtar  to  extract
    the tar files.

[4] Extract the source files from the tar archive using 'rtar".
    
        cl> softools
        so> rtar -xrf deitab.tar
        so> bye
    
    On  some  systems, an error message will appear ("Copy 'bin.generic'
    to './bin fails") which can be  ignored.   Sites  should  leave  the
    symbolic  link  'bin'  in  the  package  root  directory pointing to
    'bin.generic' but can delete any of the bin.<arch> directories  that
    won't  be  used.  If there is no binary directory for the system you
    are installing it will be  created  when  the  package  is  compiled
    later or when the binaries are installed.
    
    If the binary executables have been obtained these are now extracted
    into the appropriate bin.<arch> directory.
    
        # Example of sparc installation.
        cl> cd deitab
        cl> rtar -xrf deitab-bin.sparc      # Creates bin.sparc directory
    
    The  various  tar  file  can  be  deleted  once   they   have   been 
    successfully installed.

[5] For  a  source  installation  you  now  have  to  build  the package
    executable(s).  The "tables" package must be installed first if  not
    already   available.   First  you  configure  the  package  for  the 
    particular architecture.
    
        cl> cd deitab
        cl> mkpkg <arch>            # Substitute sparc, ssun, alpha, etc.
    
    This will change the bin link from bin.generic to  bin.<arch>.   The
    binary  directory  will  be  created  if  not  present.  If an error
    occurs in setting the architecture then  you  may  need  to  add  an
    entry to the file "mkpkg".  Just follow the examples in the file.
    
    To create the executables and move them to the binary directory
    
        cl> mkpkg -p deitab                 # build executables
        cl> mkpkg generic           # optionally restore generic setting
    
    Check  for  errors.   If the executables are not moved to the binary
    directory then step [1] to define the path for the package  was  not
    done  correctly.   The  last  step restores the package to a generic
    configuration.  This is not necessary if  you  will  only  have  one
    architecture for the package.

This  should  complete  the  installation.  You can now load the package
and begin testing and use.
