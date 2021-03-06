// Verifies we currently don't allow initializers to have try statements in
// their body.
// We hope to eventually allow it.
class Foo {
  var x: int;

  proc init() {
    try {
      outerFunc();
      x = 10;
    } catch {
      writeln("Look ma, I caught an error!");
    }
  }
}

proc outerFunc() throws {
  throw new unmanaged Error();
}

var foo = new unmanaged Foo();
writeln(foo);
delete foo;
