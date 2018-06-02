use DataFrames;

var df = new DataFrame();

var validBits = [true, false, true, false, true];
var columnOne: Series = new TypedSeries(["a", "b", "c", "d", "e"], validBits);
var columnTwo: Series = new TypedSeries([1, 2, 3, 4, 5], validBits);
var columnThree: Series = new TypedSeries([10.0, 20.0, 30.0, 40.0, 50.0]);

df["columnOne"] = columnOne;
df["columnTwo"] = columnTwo;
df["columnThree"] = columnThree;

var idx = new TypedIndex(["rowOne", "rowTwo", "rowThree", "rowFour", "rowFive"]);
df.reindex(idx);
writeln(df);
