use Curl;
var fl = open(url="http://norvig.com", mode=iomode.r);
// print to stdout and show progress bar
/*fl.setopt(curlopt_noprogress, false);*/
fl.perform();
// now don't show progress bar
fl.setopt(curlopt_noprogress, true);
fl.perform();


