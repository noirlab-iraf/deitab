include	<error.h>
include	<tbset.h>
include	<imhdr.h>
include "whatfile.h"

# TXNDIMAGE  --  Extract ND images from 3D table row.
# This is a minor revision of tables.ttools.tximage.


procedure t_txndimage()

char	tablist1[SZ_LINE]		# Input table list
char	imlist2[SZ_LINE]		# Output image list
bool	verbose				# Print operations ?

char	table1[SZ_PATHNAME]		# Input table name
char	image2[SZ_PATHNAME]		# Output table name
char	rootname[SZ_PATHNAME]		# Root name
char	dirname[SZ_PATHNAME]		# Directory name

int	list1, list2, root_len
pointer	sp

int	imtopen(), imtgetim(), imtlen()
int	fnldir(), isdirectory()
bool	clgetb(), streq()

begin
	# Get input and output table template lists.

	call clgstr ("intable", tablist1, SZ_LINE)
	call clgstr ("output",  imlist2, SZ_LINE)
	verbose = clgetb ("verbose")

	# Check if the output string is a directory.

	if (isdirectory (imlist2, dirname, SZ_PATHNAME) > 0) {
	    list1 = imtopen (tablist1)	
	    while (imtgetim (list1, table1, SZ_PATHNAME) != EOF) {
		call smark (sp)

		# Place the input table name without a directory in
		# string rootname.

		call get_root (table1, image2, SZ_PATHNAME)
		root_len = fnldir (image2, rootname, SZ_PATHNAME)
		call strcpy (image2[root_len + 1], rootname, SZ_PATHNAME)

		call strcpy (dirname, image2, SZ_PATHNAME)
		call strcat (rootname, image2, SZ_PATHNAME)

		iferr (call txndimage (table1, image2, verbose))
		    call erract (EA_WARN)

		call sfree (sp)
	    }
	    call imtclose (list1)

	} else {
	    # Expand the input and output table lists.

	    list1 = imtopen (tablist1)
	    list2 = imtopen (imlist2)

	    if (imtlen (list1) != imtlen (list2)) {
	        call imtclose (list1)
	        call imtclose (list2)
	        call error (1, "Number of input and output files not the same")
	    }

	    # Expand each table.

	    while ((imtgetim (list1, table1, SZ_PATHNAME) != EOF) &&
		   (imtgetim (list2, image2, SZ_PATHNAME) != EOF)) {

		call smark (sp)

		if (streq (table1, image2)) {
		    call eprintf ("can't expand table to itself:  %s\n")
			call pargstr (table1)
		    next
		}
		iferr (call txndimage (table1, image2, verbose))
		    call erract (EA_WARN)

		call sfree (sp)
	    }

	    call imtclose (list1)
	    call imtclose (list2)
	}
end


procedure txndimage (input, output, verbose)

char	input[ARB]	# i: input table name
char	output[ARB]	# i: output table name
bool	verbose		# i: print operations ?
#--
int     i, npix, numrow, numcol, numptr, irow, nrows
int     colnum, datatype, lendata, lenfmt
pointer	sp, root, extend, rowselect, colselect, colname, colunits, colfmt
pointer errmsg, icp, itp, im, colptr, pcode 
pointer	newname
bool	suffix

string	noarray  "No valid image data in %s"
string	nocols   "Column name not found (%s)"
string	manycols "Too many columns (%s)"
string	nofile   "Input file is not a table (%s)"

errchk	tbtopn, trsopen, trseval

bool	trseval()
int	tbpsta(), whatfile(), selrows()
pointer	tbtopn(), tcs_column, trsopen(), immap()

begin
	# Allocate memory for temporary strings.
	call smark (sp)
	call salloc (root,      SZ_FNAME,    TY_CHAR)
	call salloc (newname,   SZ_FNAME,    TY_CHAR)
	call salloc (extend,    SZ_FNAME,    TY_CHAR)
	call salloc (rowselect, SZ_FNAME,    TY_CHAR)
	call salloc (colselect, SZ_FNAME,    TY_CHAR)
        call salloc (colname,   SZ_COLNAME,  TY_CHAR)
        call salloc (colunits,  SZ_COLUNITS, TY_CHAR)
        call salloc (colfmt,    SZ_COLFMT,   TY_CHAR)
	call salloc (errmsg,    SZ_LINE,     TY_CHAR)

	# Only tables allowed as input.
	if (whatfile (input) != IS_TABLE) {
	    call sprintf (Memc[errmsg], SZ_LINE, nofile)
	    call pargstr (input)
	    call error (1, Memc[errmsg])
	}

	# Break input file name into bracketed selectors.
	call rdselect (input, Memc[root], Memc[rowselect], 
                       Memc[colselect], SZ_FNAME)

	# Open input table and get some info about it.
	itp = tbtopn (Memc[root], READ_ONLY, NULL)
	numrow = tbpsta (itp, TBL_NROWS)
	numcol = tbpsta (itp, TBL_NCOLS)

	# Find how many rows were requested by row selector.
	# If only one, turn off suffixing. 
	nrows = selrows (itp, Memc[rowselect])
	if (nrows == 1)
	    suffix = false
	else
	    suffix = true

	# Create array of column pointers from column selector.
        # This is necessary to avoid segv in case more than one
        # column selector is passed to the task.
	call malloc (colptr, numcol, TY_INT)
	call tcs_open (itp, Memc[colselect], Memi[colptr], numptr, numcol)

	# Take an error exit if either no columns were matched or
        # more than one column was matched.
	if (numptr == 0) {
	    call sprintf (Memc[errmsg], SZ_LINE, nocols)
	        call pargstr (input)
	        call error (1, Memc[errmsg])
	} else if (numptr != 1) {
	    call sprintf (Memc[errmsg], SZ_LINE, manycols)
	        call pargstr (input)
	        call error (1, Memc[errmsg])
	}

	# Loop over selected rows on input table,
	# creating an image for each row.
	pcode = trsopen (itp, Memc[rowselect])
	do irow = 1, numrow {
	    if (trseval (itp, irow, pcode)) {

	        # Append suffix to output name.
	        if (suffix)
	            call txisuff (output, Memc[newname], irow)
	        else
	            call strcpy (output, Memc[newname], SZ_FNAME)

		if (verbose) {
		    call eprintf ("%s row=%d  -> %s\n")
			call pargstr (input)
			call pargi (irow)
			call pargstr (Memc[newname])
		}

	        # Get column information.
	        icp = tcs_column (Memi[colptr])
	        call tbcinf (icp, colnum, Memc[colname], Memc[colunits], 
                             Memc[colfmt], datatype, lendata, lenfmt)

	        # Take error exit if scalar or invalid type.
	        if ((lendata < 2) || (datatype < 0) || (datatype == TY_BOOL)){
	            call sprintf (Memc[errmsg], SZ_LINE, noarray)
	                call pargstr (input)
	                call error (1, Memc[errmsg])
	        }

	        # Open output image
	        im = immap (Memc[newname], NEW_IMAGE, NULL)
		call tcs_shape (Memi[colptr], IM_LEN(im,1), IM_NDIM(im),
		    IM_MAXDIM)
		IM_PIXTYPE(im) = datatype

		# Copy header to image.
		call txtb2im (itp, im)

		# Copy data to image.
		npix = 1
		do i = 1, IM_NDIM(im)
		    npix = npix * IM_LEN(im,i)
	        call txicpy (itp, im, irow, Memi[colptr], datatype, npix)

	        # Write column data into header.
	        call txihc (im, colnum, Memc[colname], Memc[colunits], 
                            Memc[colfmt], lenfmt)

	        # Write row number into header.
	        call imaddi (im, "ORIG_ROW", irow)

	        # Close output.
	        call imunmap (im)
	    }
	}

	# Free memory associated with columns.
	call tcs_close (Memi[colptr], numptr)
	call mfree (colptr, TY_INT)

	# Close row selector structure and input table.
	call trsclose (pcode)
	call tbtclo (itp)

	call sfree (sp)
end




#  Appends sufix to output image name.

procedure txisuff (filename, newname, row)

char	filename[ARB]	# i: output image name
char	newname[ARB]	# o: output image name with suffix
int	row		# i: row number

pointer	sp, ext, suffix
int	dot, i, j

int	strcmp(), strldxs(), strlen()

begin
	call smark (sp)
	call salloc (suffix, SZ_LINE, TY_CHAR)
	call salloc (ext,    SZ_LINE, TY_CHAR)

	# Get rid of any appendages except the extension.
	call imgcluster (filename, newname, SZ_FNAME)

	# Valid extensions are .??h, .fit and .fits
	# Everything else is part of the root file name.

	# Detect extension.
	Memc[ext] = EOS
	dot = strldxs (".", newname)
	if (dot != 0) {
	    i = dot
	    j = 0
	    while (newname[i] != EOS) {
	        Memc[ext+j] = newname[i]
	        j = j + 1
	        i = i + 1
	    }
	    Memc[ext+j] = EOS
	}

	# If valid extension, remove it from name.
	if ( ((strlen (Memc[ext]) == 4) && (Memc[ext+3] == 'h')) ||
	     (strcmp (Memc[ext], ".fit")  == 0)                  ||
	     (strcmp (Memc[ext], ".fits") == 0) ) 
	    newname[dot] = EOS
	else
	    Memc[ext] = EOS

	# Build suffix.
	call sprintf (Memc[suffix], SZ_LINE, "_r%04d")
	    call pargi (row)

	# Append suffix and extension to root name.
	call strcat (Memc[suffix], newname, SZ_FNAME)
	call strcat (Memc[ext],    newname, SZ_FNAME)

	call sfree (sp)
end


#  TXICPY --  Copy data from single row and column in 3D table to image.

procedure txicpy (itp, im, irow, icp, datatype, size)

pointer itp		# i: pointer to descriptor of input table
pointer im		# i: pointer to output image
int	irow		# i: row in input table
pointer icp		# i: array of pointers for input columns
int	datatype	# i: data type
int	size		# i: array size
#--
int	nbuf, nc
pointer	sp, bufin, v, bufout, errmsg, colname

string	badtype  "Unsupported column data type (%s)"

int	impnls(), impnli(), impnlr(), impnld()

begin
	call smark (sp)
	call salloc (bufin, size, datatype)
	call salloc (v, IM_MAXDIM, TY_LONG)

	nc = IM_LEN(im,1)
	call amovkl (long(1), Meml[v], IM_MAXDIM)

	switch (datatype) {
	case TY_SHORT:
	    call tcs_rdarys (itp, icp, irow, size, nbuf, Mems[bufin])
	    while (impnls (im, bufout, Meml[v]) != EOF) {
		call amovs (Mems[bufin], Mems[bufout], nc)
		bufin = bufin + nc
	    }
	case TY_INT,TY_LONG:
	    call tcs_rdaryi (itp, icp, irow, size, nbuf, Memi[bufin])
	    while (impnli (im, bufout, Meml[v]) != EOF) {
		call amovi (Memi[bufin], Memi[bufout], nc)
		bufin = bufin + nc
	    }
	case TY_REAL:
	    call tcs_rdaryr (itp, icp, irow, size, nbuf, Memr[bufin])
	    while (impnlr (im, bufout, Meml[v]) != EOF) {
		call amovr (Memr[bufin], Memr[bufout], nc)
		bufin = bufin + nc
	    }
	case TY_DOUBLE:
	    call tcs_rdaryd (itp, icp, irow, size, nbuf, Memd[bufin])
	    while (impnld (im, bufout, Meml[v]) != EOF) {
		call amovd (Memd[bufin], Memd[bufout], nc)
		bufin = bufin + nc
	    }
	default:
	    # Unsupported type, write error message
	    call salloc (colname, SZ_COLNAME, TY_CHAR)
	    call salloc (errmsg, SZ_LINE, TY_CHAR)
	    call tcs_txtinfo (icp, TBL_COL_NAME, Memc[colname], SZ_COLNAME)
	    call sprintf (Memc[errmsg], SZ_LINE, badtype)
	    call pargstr (Memc[colname])
	    call error (1, Memc[errmsg])
	}

	call sfree (sp)
end


#  TXIHC  --   Write basic column info into image header.

procedure txihc (im, colnum, colname, colunits, colfmt, lenfmt)

pointer im		# i: pointer to image
int	colnum		# i: column number in input table
char	colname[ARB]	# i: column name
char	colunits[ARB]	# i: column units
char	colfmt[ARB]	# i: column format
int	lenfmt		# i: length of format string
#--
pointer	sp, cu, cf, text

begin
	call smark (sp)
	call salloc (text, SZ_LINE, TY_CHAR)
	call salloc (cu,   SZ_LINE, TY_CHAR)
	call salloc (cf,   SZ_LINE, TY_CHAR)

	# Empty units or format string are encoded as "default".
	if (colunits[1] == EOS)
	    call strcpy ("default", Memc[cu], SZ_LINE)
	else
	    call strcpy (colunits,  Memc[cu], SZ_LINE)
	if (colfmt[1] == EOS)
	    call strcpy ("default", Memc[cf], SZ_LINE)
	else
	    call strcpy (colfmt,   Memc[cf], SZ_LINE)

	# Assemble keyword value.
	call sprintf (Memc[text], SZ_LINE, "%d %s %s %s %d")
	    call pargi (colnum)
	    call pargstr (colname)
	    call pargstr (Memc[cu])
	    call pargstr (Memc[cf])
	    call pargi (lenfmt)

	# Write keyword into header.
	call imastr (im, "COLDATA", Memc[text])
	call sfree (sp)
end


# TXTB2IM -- Convert table header to image header.

procedure txtb2im (tp, im)

pointer	tp			#I Table pointer
pointer	im			#I IMIO pointer (previously created)

int	i, j, k, dtype, len
pointer	sp, key, str
int	ival
bool	bval
double	dval

#bool	streq()
int	strlen(), strncmp()
errchk	tbhgnp, imaddb, imaddi, imaddd, imastr

string	exclude	"|XTENSION|BITPIX|NAXIS*|PCOUNT|GCOUNT|TFIELDS|TFORM*|TDIM*|\
		|TTYPE*|EXTNAME|DATE|END|"

begin	
	call smark (sp)
	call salloc (key, SZ_KEYWORD, TY_CHAR)
	call salloc (str, SZ_PARREC, TY_CHAR)

	do k = 1, ARB {
	    iferr (call tbhgnp (tp, k, Memc[key], dtype, Memc[str]))
		break
	    if (Memc[key] == EOS)
		break

	    # Check for keywords to exclude.
	    bval = false
	    len = strlen (Memc[key])
	    for (i=2; exclude[i]!=EOS; i=i+1) {
		if (strncmp (Memc[key], exclude[i], len) == 0 &&
		    exclude[i+len] == exclude[1]) {
		    bval = true
		    break
		}
		for (j=i+1; exclude[j]!=exclude[1]; j=j+1) {
		    if (exclude[j] == '*') {
			if (strncmp (Memc[key], exclude[i], j-i) == 0) {
			    bval = true
			    break
			}
		    }
		}
		if (bval)
		    break
		i = j
	    }
	    if (bval)
	        next

	    switch (dtype) {
	    case TY_BOOL:
		bval = (Memc[str] == 'T')
		call imaddb (im, Memc[key], bval)
	    case TY_INT, TY_LONG:
		call sscan (Memc[str])
		call gargi (ival)
#		if (streq (Memc[key], "WCSDIM")) {
#		    IM_NDIM(im) = ival
#		    IM_NPHYSDIM(im) = ival
#		}
		call imaddi (im, Memc[key], ival)
	    case TY_REAL, TY_DOUBLE:
		call sscan (Memc[str])
		call gargd (dval)
		call imaddd (im, Memc[key], dval)
	    case TY_CHAR:
		call imastr (im, Memc[key], Memc[str])
	    }
	}

	call sfree (sp)
end
