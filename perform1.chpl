var fl = open("http://norvig.com", iomode.r);
// print to stdout and show progress bar
fl.setopt(chapcurl.NOPROGRESS, false);
fl.perform();
// now don't show progress bar
fl.setopt(chapcurl.NOPROGRESS, true);
fl.perform();


