use IO;

var str:string;

// run: nc -l 1080 in another window on this computer
var fl = copen("http://norvig.com", iomode.r);
var reader = fl.reader();
reader.readstring(str);
reader.close();
fl.close();

var flout = copen("http://127.0.0.1:1080", iomode.cw);
var writer = flout.writer();
writer.write(str);
writer.close();
flout.close();

