record foo_t {
  var t: int;
  var g: int;
}

proc foo_assign(rec:foo_t) {
  rec.t = 5;
  writeln(rec);
}

iter iter_foo_assign(rec:foo_t) {
  rec.t = 5;
  writeln(rec);
  yield 1;
}

var r:foo_t;
r.t = 1;
r.g = 7;

writeln(r);
foo_assign(r);

r.t = 1;
r.g = 7;

writeln(r);
iter_foo_assign(r);
