use FFS;

var str:string;

{
  writeln("readstring on a URL that we can request byteranges  -- this should work");

  var fl = open("http://norvig.com", iomode.r, ffst.curl);

  var reader = fl.reader();
  reader.readstring(str);
  write(str);
  reader.close();
  fl.close();
}

{
  writeln("readstring on a URL that we cannot request byteranges  -- this should NOT work (we should get an error)");

  var fl = open("http://chapel.cray.com", iomode.r, ffst.curl);

  var reader = fl.reader();
  reader.readstring(str);
  write(str);
  reader.close();
  fl.close();
}
