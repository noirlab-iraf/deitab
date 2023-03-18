# TXDEIMOS -- Extract multiextension images from DEIMOS tables.

procedure txdeimos (input, output)

string	input			{prompt="List of input DEIMOS tables"}
string	output			{prompt="List of output DEIMOS images"}

struct	*fd

begin
	file	temp1, temp2, flist
	file	in, out, incol, outext

	temp1 = mktemp ("tmp$iraf")
	temp2 = mktemp ("tmp$iraf")
	flist = mktemp ("tmp$iraf")

	sections (input, option="fullname", > temp1)
	sections (output, option="fullname") | joinlines (temp1, "STDIN",
	    delim=" ", maxc=161, short+, verb-, > flist)
	delete (temp1, verify-)

	fd = flist
	while (fscan (fd, in, out) != EOF) {
	    if (imaccess (out//"[1]")) {
	        printf ("WARNING: Output already exists (%s)\n", out)
		next
	    }

	    # Flux extension
	    printf ("%s[c:FLUX]\n", in) | scan (incol)
	    printf ("%s[FLUX]\n", out) | scan (outext)
	    txndimage (incol, outext, verbose-)
	    hedit (outext, "CUNIT1", "Angstroms", add+, verify-, show-, update+)

	    # Wavelength extension
	    printf ("%s[c:DLAMBDA]\n", in) | scan (incol)
	    txndimage (incol, temp1, verbose-)
	    hedit (temp1, "CUNIT1", "Angstroms", add+, verify-, show-, update+)
	    printf ("%s[c:LAMBDA0]\n", in) | scan (incol)
	    txndimage (incol, temp2, verbose-)
	    hedit (temp2, "CUNIT1", "Angstroms", add+, verify-, show-, update+)
	    printf ("%s[LAMBDA,append]\n", out) | scan (outext)
	    imarith (temp1, "+", temp2, outext, title="", hpar="", pixtype="",
	        calctype="", verb-, noact-)
	    imdelete (temp1, verify-)
	    imdelete (temp2, verify-)

	    # Variance extension
	    printf ("%s[c:IVAR]\n", in) | scan (incol)
	    printf ("%s[IVAR,append]\n", out) | scan (outext)
	    txndimage (incol, outext, verbose-)
	    hedit (outext, "CUNIT1", "Angstroms", add+, verify-, show-, update+)
	}
	fd = ""; delete (flist, verify-)
end
