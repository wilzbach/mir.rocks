/*

Guidelines:
    - Please don't use global imports of the functions you want to show.
        (Every test should be independent.)
    - Add one line between imports and your tests if you have more than one
        import line
*/

// we use this comparison method a lot
import std.algorithm: equal;

// Needed for custom name attribute
struct name
{
    string val;
}

import std.stdio;
import mir.ndslice;

/**
With map we can call a custom function for every element
*/
@name("Creating a 2d matrix") unittest
{
    auto matrix = slice!int(2, 2);
    assert(matrix == [[0, 0], [0, 0]]);
}

/**
The row-first index (C, D style) uses the square brackets a[]<br>
The column-first index (Math, Fortran style) uses the parenthesis a()
*/
@name("Accessing row/columns") unittest
{
    // [0, 1, 2]
    // [3, 4, 5]
    // [6, 7, 8]
    auto matrix = iotaSlice(3, 3).slice;
    // access a row
    assert(matrix[1] == [3, 4, 5]);
    // access a column
    //assert(matrix([1]).equal([1, 4, 7]));

    // with slices
    assert(matrix[1..$,1..$] == [[4, 5], [7, 8]]);

    // set a row
    matrix[1][] = [1, 2, 4];
    assert(matrix[1] == [1, 2, 4]);

    // or the entire matrix
    matrix[] = 2;
    assert(matrix[1,1] == 2);
}

/**
The row-first index (C, D style) uses the square brackets a[]<br>
The column-first index (Math, Fortran style) uses the parenthesis a()
*/
@name("Accessing elements") unittest
{
    // [0, 1, 2]
    // [3, 4, 5]
    // [6, 7, 8]
    auto matrix = iotaSlice(3, 3).slice;
    // D & C order
    assert(matrix[1, 0] == 3);
    // Math & Fortran order
    assert(matrix(1, 0) == 1);

    // elements are lvalues
    matrix[1, 2] = 42;
    assert(matrix[1, 2] == 42);
}

/**
Mir provides many pre-made ways to select parts of a matrix.
*/
@name("Matrix selection") unittest
{
    // [0,  1,  2]
    // [3,  4,  5]
    // [6,  7,  8]
    // [9, 10, 11]
    auto matrix = iotaSlice(4, 3).slice;
    assert(matrix.diagonal == [0, 4, 8]);
    // it's just a pointer
    matrix.diagonal[1] = 42;
    assert(matrix[1, 1] == 42);

    // change the shape
    // [ 0, 1,  2,  3]
    // [42, 5,  6,  7]
    // [ 8, 9, 10, 11]
    assert(matrix.reshape(3, 4)[1, 0] == 42);

    // flatten
    assert(matrix.byElement[2..5].equal([2, 3, 42]));

    // windowing
    // [[0, 1]]
    // [[1, 2]]
    // [[3, 42]]
    // ...
    assert(matrix.windows(1, 2).byElement[2][0] == [3, 42]);
}

/**
All standard range functions still work with ndslice!
*/
@name("Use as a range") unittest
{
    import std.algorithm: sum;
    // [0,  1,  2]
    // [3,  4,  5]
    // [6,  7,  8]
    // [9, 10, 11]
    auto matrix = iotaSlice(4, 3).slice;
    auto n = matrix.elementsCount;
    assert(matrix.byElement.sum == (n * (n - 1)) / 2);

    // filter the mid column and flatten
    // 1, 4, 7, 10
    auto midColumn = matrix.drop(1, 1).dropBack(1, 1).byElement;
    assert(midColumn.equal([1, 4, 7, 10]));
    assert(midColumn.equal(matrix.everted[1]));

    import std.algorithm: min, max, fold;
    import std.typecons: tuple;
    // global min, max
    assert(matrix.byElement.fold!(min, max) == tuple(0, 11));

    // column min, max
    import std.algorithm: map;
    auto minMax = [[0, 2], [3, 5], [6, 8], [9, 11]].map!`tuple(a[0], a[1])`;
    alias compareTuple = (x,y) => x[0] == y[0] && x[1] == y[1];
    assert(matrix.map!(fold!(min, max)).equal!compareTuple(minMax));
}

/**
You can just use standard tools to create your matrix as a string.
*/
@name("Custom matrix formatting") unittest
{
    auto matrix = iotaSlice(4, 3).slice;

    // create your own matrix output
    import std.algorithm: joiner, map;
    import std.format: format;
    alias joinRow = (x) => x.map!(`format("%3d", a)`).joiner(", ");
    format("%(%(%3d, %)\n%)", matrix).writeln;

    auto output =
    "  0,   1,   2\n" ~
    "  3,   4,   5\n" ~
    "  6,   7,   8\n" ~
    "  9,  10,  11";
    assert(matrix.map!joinRow.joiner("\n").equal(output));
}

/**
Matrix 3d transposition
*/
@name("Matrix transposition in 3d") unittest
{
    // [0]  [0, 1]
    //      [2, 3]
    // [1]  [4, 5]
    //      [6, 7]
    auto m3d = iotaSlice(2, 2, 2).slice;

    // bring a selected dimensions to front
    // [0]  [0, 2]
    //      [4, 6]
    // [1]  [1, 3]
    //      [6, 7]
    assert(m3d.transposed!2[0, 1] == [4, 6]);

    // invert the order of dimensions
    // [0]  [0, 4]
    //      [2, 6]
    // [1]  [1, 5]
    //      [3, 7]
    assert(m3d.everted[0, 1] == [2, 6]);

    // for 2d they are the same operation
    auto matrix = iotaSlice(3, 3).slice;
    assert(matrix.transposed == matrix.everted);


    // split into blocks
    // [
    //  [0]
    //      [0]
    //          [0, 1]
    //          [4, 5]
    //      [1]
    //          [2, 3]
    //          [6, 7]
    //  [1]
    //      [0]
    //          [8, 9]
    //          [12, 13]
    //      [1]
    //          [10, 11]
    //          [14, 15]

    assert(iotaSlice(4, 4).slice.blocks(2, 2)[0, 1] == [[2, 3], [6, 7]]);
}

/**
BLAS is work in progress.
*/
@name("Matrix functions") unittest
{
    import mir.blas;
    auto mat1 = [2, 4];
    auto mat2 = [1, 3].sliced;
    // 2 * 1 + 4 * 3
    assert(mat1.dot(mat2) == 14);
}

/**
A couple of convenient combinatorics methods are provided. Think about as the mir
analog to Python's itertools.
*/
@name("Combinatorics") unittest
{
    import mir.combinatorics;
    assert([0, 1].permutations.equal!equal([[0, 1], [1, 0]]));
    assert([0, 1].cartesianPower(2).equal!equal([[0, 0], [0, 1], [1, 0], [1, 1]]));
    assert([0, 1].combinations(2).equal!equal([[0, 1]]));
    assert([0, 1].combinationsRepeat(2).equal!equal([[0, 0], [0, 1], [1, 1]]));
}

/**
Sparse matrices only allocate the non-zero elements. They are still slices.
*/
@name("Sparse matrices") unittest
{
    import mir.sparse;
    auto mat1= sparse!int(2, 2);
    mat1[1, 1] = 42;
    assert(mat1 == [[0, 0], [0, 42]]);
}

/**
If you want to get ultimate performance, you can provide your own allocator
*/
@name("With @nogc") @nogc unittest
{
    import std.experimental.allocator.mallocator: Mallocator;
    import std.experimental.allocator: dispose;
    alias Allocator = Mallocator.instance;
    auto ones = Allocator.makeSlice!int([2, 2], 1);
    static immutable staticOnes = [[1, 1], [1, 1]];
    assert(ones.slice.equal(staticOnes));
    Allocator.dispose(ones.array);
}
