use IO;

var str:string;

// run: nc -l 1080 in another window on this computer
// -- note that this WILL hang using nc since it is expecting EOF
// an "actual" server will only expect a given number of bytes (which we are
// satisfying)
var fl = openurl("http://norvig.com", iomode.r);
var reader = fl.reader();
reader.readstring(str);
reader.close();
fl.close();

var flout = openurl("http://127.0.0.1:1080", iomode.cw);
var writer = flout.writer();
writer.write(str);
writer.close();
flout.close();

