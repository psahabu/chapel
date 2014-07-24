use FFS;

var str:string;

/*var fl = open("http://norvig.com/big.txt", iomode.r, ffst.curl);*/
/*var fl = open("http://www.google.com", iomode.r, ffst.curl);*/
/*var fl = open("http://chapel.cray.com", iomode.r, ffst.curl);*/

{
  writeln("reading -- we can request byteranges ");
  var fl = open("http://norvig.com", iomode.r, ffst.curl);
  var reader = fl.reader();

  while(reader.readline(str)){
    write(str);
  }

  reader.close();
  fl.close();
}

{
  writeln("reading -- we cannot request byteranges ");
  var fl = open("http://chapel.cray.com", iomode.r, ffst.curl);
  var reader = fl.reader();

  while(reader.readline(str)){
    write(str);
  }

  reader.close();
  fl.close();
}

