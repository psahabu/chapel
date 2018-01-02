use IO;

var str:string;

// TODO: version requesting byteranges

// cannot request byteranges
var reader = openreader(url="https://chapel-lang.org");

while(reader.readline(str)){
  write(str);
}

reader.close();
