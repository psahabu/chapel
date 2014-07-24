use FFS;

var str:string;

{
  writeln("readstring on a URL that we can request byteranges  -- this should work");

  var fl = open("http://norvig.com", iomode.r, ffst.curl);
  /*fl.setopt(chapcurl.NOPROGRESS, false);*/
  fl.get(str);
  writeln(str);
  fl.close();
}

{
  writeln("readstring on a URL that we cannot request byteranges  -- this should still work (we should get an error)");

  var fl = open("http://chapel.cray.com", iomode.r, ffst.curl);
  fl.get(str);
  writeln(str);
  fl.close();
}
