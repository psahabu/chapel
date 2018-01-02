use IO;

var str:string;

// TODO: version requesting byteranges

// cannot request byteranges
var reader = openreader(url="https://chapel-lang.org");

reader.readstring(str);
write(str);
reader.close();
