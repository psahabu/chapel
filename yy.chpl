var writer = openwriter("DIRS");
writer.write("hello world");
writer.close();

var reader = openreader("DIRS");
var str:string;
reader.readstring(str);
write(str);
reader.close();
