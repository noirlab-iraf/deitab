# DCDEIMOS -- Apply wavelength calibration.

procedure dcdeimos (unextracted, extracted)

string	unextracted		{prompt="List of unextracted DEIMOS images"}
string	extracted		{prompt="List of extracted spectra"}
bool	linearize = no		{prompt="Linearize spectra?\n"}

real	w1 = INDEF		{prompt="Starting wavelength"}
real	w2 = INDEF		{prompt="Ending wavelength"}
real	dw = INDEF		{prompt="Wavelength interval per pixel"}
int	nw = INDEF		{prompt="Number of pixels"}

struct	*fd

begin
	file	temp1, temp2, flist
	file	in, out, incol, outext
	struct	flag

	temp1 = mktemp ("tmp$iraf")
	temp2 = mktemp ("iraf")
	flist = mktemp ("tmp$iraf")

	sections (unextracted, option="fullname", > temp1)
	sections (extracted, option="fullname") | joinlines (temp1, "STDIN",
	    delim=" ", maxc=161, short+, verb-, > flist)
	delete (temp1, verify-)

	fd = flist
	while (fscan (fd, in, out) != EOF) {
	    # Check for previous calibration.
	    flag = ""
	    hselect (out, "dclog1", yes) | scan (flag)
	    if (flag != "") {
	printf ("WARNING: Spectrum already dispersion calibrated (%s)\n", out)
		next
	    }

	    # Extract wavelengths.
	    apall (in//"[LAMBDA]", output=temp1, apertures="",
		format="multispec", references=in//"[FLUX]", profiles="",
		interactive=no, find=no, recenter=no, resize=yes, edit=no,
		trace=no, fittrace=no, extract=yes, extras=no, review=no,
		llimit=-0.5, ulimit=0.5, ylevel=INDEF,
		background="none", weights="none", clean=no, nsubaps=1)
	    listpix (temp1, formats="", verbose-) |
	        fields ("STDIN", 2, lines="1-", > "id"//temp2)
	    imdelete (temp1, verify-)

	    # Apply wavelengths.
	    hedit (out, "refspec1", temp2, add+, verify-, show-, update+)
	    dispcor (out, out, linearize=linearize, database="./", table="",
		w1=w1, w2=w2, dw=dw, nw=nw, log-, flux+, samedisp-,
		global-, ignoreaps-, confirm-, listonly-, verbose-, logfile="")
	    delete ("id"//temp2, verify-)
	}
	fd = ""; delete (flist, verify-)
end
