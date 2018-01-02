{
  var writer = openwriter("DIRS");
  writer.write("hello world");
  writer.close();
}

{
  var reader = openreader("DIRS");
  var str:string;
  reader.readstring(str);
  write(str);
  reader.close();
}

{
  var reader = openreader(url="https://chapel-lang.org");
  var str:string;
  reader.readstring(str);
  write(str);
  reader.close();
}
