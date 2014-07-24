use IO;

var str:string;

{
  writeln("reading -- we can request byteranges ");
  var fl = copen("http://norvig.com", iomode.r);
  var reader = fl.reader();

  while(reader.readline(str)){
    write(str);
  }

  reader.close();
  fl.close();
}

{
  writeln("reading -- we cannot request byteranges ");
  var fl = copen("http://chapel.cray.com", iomode.r);
  var reader = fl.reader();

  while(reader.readline(str)){
    write(str);
  }

  reader.close();
  fl.close();
}

