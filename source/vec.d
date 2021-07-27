import std.traits: isNumeric;
import std.conv: to;
import std.math: sqrt;

alias Vec3f = Vector!(3, float);
alias Point = Vector!(2, int);

struct Mat3 { float[3][3] data; } // TODO(ag): Make this a generic struct

struct Vector(int n, T = float) if (isNumeric!T) {
    T[n] data = 0;

    alias Self = Vector!(n, T);

    this(T[n] initial_values) @nogc {
        data = initial_values;
    }

    Self normalized() const @nogc pure {
        Self normalized = this;

        float norm = norm();

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

    auto norm() const pure nothrow {
        T sum = 0;
        foreach (member; data) { sum += member * member; }
        return sqrt(cast(real) sum);
    }

    void normalize() {
        float norm = norm();
        foreach (ref member; data) { member = cast(T)(cast(float) member / norm); } // The casting is for when T == int, might be buggy.
    }

    // TODO maybe inline all the static functions above?
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

    // TODO do we need these, really?
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

    string toString() { return Self.stringof ~ to!(string)(this.data); }
}
