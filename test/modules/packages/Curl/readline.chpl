use IO;

var str:string;

{
  writeln("reading -- we can request byteranges ");
  var reader = openreader(url="http://norvig.com");

  while(reader.readline(str)){
    write(str);
  }

  reader.close();
}

{
  writeln("reading -- we cannot request byteranges ");
  var reader = openreader(url="http://chapel.cray.com");

  while(reader.readline(str)){
    write(str);
  }

  reader.close();
}

