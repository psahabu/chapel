use IO;

var str:string;

{
  writeln("reading -- we can request byteranges ");
  var fl = open(url="http://norvig.com", mode=iomode.r);
  var reader = fl.reader();

  while(reader.readline(str)){
    write(str);
  }

  reader.close();
  fl.close();
}

{
  writeln("reading -- we cannot request byteranges ");
  var fl = open(url="http://chapel.cray.com", mode=iomode.r);
  var reader = fl.reader();

  while(reader.readline(str)){
    write(str);
  }

  reader.close();
  fl.close();
}

