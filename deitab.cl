#{ DEITAB -- Deimos package

# Load associated packages.
tables
ttools
noao
twodspec
apextract
onedspec

cl < "deitab$lib/zzsetenv.def"
package	deitab, bin = deibin$

# Package Tasks
task	txndimage	= deisrc$x_deitab.e

task	txdeimos	= deisrc$txdeimos.cl
task	dcdeimos	= deisrc$dcdeimos.cl

clbye()
