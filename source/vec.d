import std.traits: isNumeric;
import std.conv: to;
import std.math: sqrt;

alias Vec3f  = Vector!(3, float);
alias Vertex = Vector!(3, float);
alias Mat3 = Matrix!(3, 3, float);
alias Mat4 = Matrix!(4, 4, float);

// alias Point = Vector!(2, int);
struct Point { int x, y; float h = 1; }

struct Matrix(int row, int col, T) if (isNumeric!T) {
    T[col][row] data;

    alias Self = Matrix!(row, col, T);

    void add(const ref Self rhs) @nogc nothrow {
        for (int r = 0; r < row; r++) {
            for (int c = 0; c < col; c++) {
                this.data[r][c] += rhs.data[r][c];
            }
        }
    }

    void mult(T rhs) @nogc nothrow {
        for (int r = 0; r < row; r++) {
            for (int c = 0; c < col; c++) {
                this.data[r][c] *= rhs;
            }
        }
    }

    Vector!(row, T) mult(Vector!(col, T) rhs) const @nogc nothrow {
        Vector!(row, T) result;

        for (int r = 0; r < row; r++) {
            result.data[r] = 0;
            for (int c = 0; c < col; c++) {
                result.data[r] += this.data[r][c] * rhs.data[c];
            }
        }

        return result;
    }

    Matrix!(row, r_col, T) mult(int r_row, int r_col)(Matrix!(r_row, r_col, T) rhs) const @nogc nothrow {
        Matrix!(row, r_col, T) result;

        for (int lr = 0; lr < row; lr++) {
            for (int rc = 0; rc < r_col; rc++) {
                static assert(col == r_row);

                auto sum = 0;
                for (int idx = 0; idx < col; idx++) {
                    sum += this.data[lr][idx] * rhs.data[idx][rc];
                }
                
                result.data[lr][rc] = sum;
            }
        }

        return result;
    }

    // Exposing template parameters for `canMultiplyMatrix`:
    private enum rows = row;
    private enum columns = col;

    private enum canMultiplyVector(V) = is(V == Vector!(col, T));
    private enum canMultiplyMatrix(M) = is(M == Matrix!(col, M.columns, T));
    private enum canMultiply(K) = canMultiplyVector!K || canMultiplyMatrix!K;

    auto opBinary(string op, K)(K rhs) const pure @nogc nothrow if (op == "*" && canMultiply!K) {
        return this.mult(rhs);
    }

}

// Gotta make sure we got this confusing thing right!
unittest {
    Matrix!(2, 3, int) left = {[
        [1, 2, 3],
        [4, 5, 6]
    ]};

    Matrix!(3, 2, int) right = {[
        [10, 11],
        [20, 21],
        [30, 31]
    ]};

    Matrix!(2, 2, int) result = {[
        [140, 146],
        [320, 335]
    ]};

    assert((left.mult(right)) == result);
    assert(left.canMultiplyMatrix!(typeof(right)));
    assert((left * right) == result);
}

struct Vector(int n, T = float) if (isNumeric!T) {
    T[n] data = 0;

    alias Self = Vector!(n, T);

    this(T[n] initial_values...) @nogc {
        data = initial_values;
    }

    Self normalized() const @nogc pure {
        Self normalized = this;

        const norm = norm();

        return (normalized / norm);
    }

    static Self add(const Self lhs, const Self rhs) pure @nogc {
        Self new_vec;

        for (int i = 0; i < n; i++) {
            new_vec.data[i] = lhs.data[i] + rhs.data[i];
        }

        return new_vec;
    }

    static Self sub(const Self lhs, const Self rhs) pure @nogc {
        Self new_vec;

        for (int i = 0; i < n; i++) {
            new_vec.data[i] = lhs.data[i] - rhs.data[i];
        }

        return new_vec;
    }

    static float mult(const Self lhs, const Self rhs) pure @nogc {
        auto sum = 0.0;

        for (int i = 0; i < n; i++) {
            sum += lhs.data[i] * rhs.data[i];
        }

        return sum;
    }

    static Self mult(K)(const Self lhs, const K rhs) pure @nogc if (isNumeric!K) {
        Self new_vec;

        for (int i = 0; i < n; i++) {
            new_vec.data[i] = cast(T)(lhs.data[i] * rhs);
        }

        return new_vec;
    }

    auto norm() const pure nothrow @nogc {
        T sum = 0;
        foreach (member; data) { sum += member * member; }
        return sqrt(cast(real) sum);
    }

    void normalize() nothrow @nogc {
        const norm = norm();
        foreach (ref member; data) { member = cast(T)(cast(float) member / norm); } // The casting is for when T == int, might be buggy.
    }

    // NOTE(ag): You could inline the binary operator functions above, but prepare to debug some issues if you go that way.
    auto opBinary(string op, T)(T rhs) const pure nothrow if ((op == "*" || op == "+" || op == "-" || op == "/")) {
        static if (is(T == Self) || is(T == const(Self)) || is(T == immutable(Self))) {
            static if      (op == "+") { return Self.add(this, rhs); }
            else static if (op == "-") { return Self.sub(this, rhs); }
            else static if (op == "*") { return Self.mult(this, rhs); }
            else static assert(0, "Operator " ~ op ~ " not implemented.");
        }
        else static if (isNumeric!T && op == "*") { return Self.mult(this, rhs); }
        else static if (isNumeric!T && op == "/") { return Self.mult(this, (1.0/rhs)); }
        else static if (is(T == Mat3) && op == "*" && n == 3) {
            Vec3f result = Vec3f([0, 0, 0]);

            for (auto row = 0; row < 3; row++) {
                for (auto col = 0; col < 3; col++) {
                    result.data[row] += this.data[col]* rhs.data[row][col];
                }
            }

            return result;
        }
        else static assert(0, "Operator " ~ op ~ " not implemented for " ~ T.stringof ~ ".");
    }

    static if (n > 1) {
    	@property T x() const { return data[0]; }
    	@property T x(T val)  { return data[0] = val; }
    	@property T y() const { return data[1]; }
    	@property T y(T val)  { return data[1] = val; }
    }
    static if (n > 2) {
    	@property T z() const { return data[2]; }
    	@property T z(T val)  { return data[2] = val; }
    }
    static if (n > 3) {
    	@property T w() const { return data[3]; }
    	@property T w(T val)  { return data[3] = val; }
    }

    string toString() const { return Self.stringof ~ to!(string)(this.data); }
}
