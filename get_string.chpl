use IO;

var str:string;

{
  writeln("readstring on a URL that we can request byteranges  -- this should work");

  var fl = copen("http://norvig.com", iomode.r);
  /*fl.setopt(chapcurl.NOPROGRESS, false);*/
  fl.get(str);
  writeln(str);
  fl.close();
}

{
  writeln("readstring on a URL that we cannot request byteranges  -- this should still work (we should get an error)");

  var fl = copen("http://chapel.cray.com", iomode.r);
  fl.get(str);
  writeln(str);
  fl.close();
}
