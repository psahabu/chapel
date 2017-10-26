use IO;

var str:string;

// run: nc -l 1080 in another window on this computer
// -- note that this WILL hang using nc since it is expecting EOF
// an "actual" server will only expect a given number of bytes (which we are
// satisfying)
var reader = openreader(url="http://norvig.com");
reader.readstring(str);
reader.close();

var writer = openwriter(url="http://127.0.0.1:1080");
writer.write(str);
writer.close();

