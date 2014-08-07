use IO;

var str:string;

{
  writeln("readstring on a URL that we can request byteranges  -- this should work");

  var fl = openurl("http://norvig.com", iomode.r);

  var reader = fl.reader();
  reader.readstring(str);
  write(str);
  reader.close();
  fl.close();
}

{
  writeln("readstring on a URL that we cannot request byteranges  -- this should work");

  var fl = openurl("http://chapel.cray.com", iomode.r);

  var reader = fl.reader();
  reader.readstring(str);
  write(str);
  reader.close();
  fl.close();
}
