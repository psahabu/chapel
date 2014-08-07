use IO;

var str:string;

{
  writeln("readstring on a URL that we can request byteranges  -- this should work");

  var fl = open(url="http://norvig.com", mode=iomode.r);
  /*fl.setopt(chapcurl.NOPROGRESS, false);*/
  fl.get(str);
  writeln(str);
  fl.close();
}

{
  writeln("readstring on a URL that we cannot request byteranges  -- this should still work (we should get an error)");

  var fl = open(url="http://chapel.cray.com", mode=iomode.r);
  fl.get(str);
  writeln(str);
  fl.close();
}
