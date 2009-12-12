use Random;

class lastmaxloc: ReduceScanOp {
  type eltType;
  var value: eltType;
  var uninitialized = true;

  def accumulate(x) {
    if uninitialized || (x(1) > value(1)) ||
      ((x(1) == value(1)) && (x(2) > value(2))) then
      value = x;
    uninitialized = false;
  }
  def combine(x) {
    if uninitialized || (x.value(1) > value(1)) ||
      ((x.value(1) == value(1)) && (x.value(2) > value(2))) {
      value = x.value;
      uninitialized = x.uninitialized;
    }
  }
  def generate() return value;
}

class lastminloc: ReduceScanOp {
  type eltType;
  var value: eltType;
  var uninitialized = true;

  def accumulate(x) {
    if uninitialized || (x(1) < value(1)) ||
      ((x(1) == value(1)) && (x(2) > value(2))) then
      value = x;
    uninitialized = false;
  }
  def combine(x) {
    if uninitialized || (x.value(1) < value(1)) ||
      ((x.value(1) == value(1)) && (x.value(2) > value(2))) {
      value = x.value;
      uninitialized = x.uninitialized;
    }
  }
  def generate() return value;
}

config const seed = 888;
config const sigfigs = 1;
config const n = 1000000;
config const debug = false;

var R: [1..n] real;
var A: [1..n] int;

fillRandom(R, seed);

def getSigDigit(r: real) {
  var rn = r*10;
  while (rn < 10**(sigfigs-1)) do rn *= 10;
  return rn:int;
}

A = getSigDigit(R);

if debug {
  writeln(R);
  writeln(A);
}

var ml = minloc reduce (A, [1..n]);
writeln(ml);
ml = lastminloc reduce (A, [1..n]);
writeln(ml);

ml = maxloc reduce (A, [1..n]);
writeln(ml);
ml = lastmaxloc reduce (A, [1..n]);
writeln(ml);

