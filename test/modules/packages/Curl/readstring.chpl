use IO;

var str:string;

{
  writeln("readstring on a URL that we can request byteranges  -- this should work");

  var reader = openreader(url="http://norvig.com");

  reader.readstring(str);
  write(str);
  reader.close();
}

{
  writeln("readstring on a URL that we cannot request byteranges  -- this should work");

  var reader = openreader(url="http://chapel.cray.com");

  reader.readstring(str);
  write(str);
  reader.close();
}
