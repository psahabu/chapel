use IO;

var str:string;

{
  writeln("readstring on a URL that we can request byteranges  -- this should work");

  var fl = open(url="http://norvig.com", mode=iomode.r);

  var reader = fl.reader();
  reader.readstring(str);
  write(str);
  reader.close();
  fl.close();
}

{
  writeln("readstring on a URL that we cannot request byteranges  -- this should work");

  var fl = open(url="http://chapel.cray.com", mode=iomode.r);

  var reader = fl.reader();
  reader.readstring(str);
  write(str);
  reader.close();
  fl.close();
}
