class R {
  type t;
  var x:t;
  record R2 {
    var y:t;
  }
  proc test() {
    var r2:R2 = new R2(x);
    writeln(r2.y);
  }
}


var r = new unmanaged R(int, 7);

r.test();

delete r;
