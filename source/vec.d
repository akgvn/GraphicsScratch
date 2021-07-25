import std.traits: isNumeric;
import std.conv: to;
import std.math: sqrt;

struct Vector(int n, T = float) if (isNumeric!T) {
    T[n] data = 0;

    alias Self = Vector!(n, T);

    this(T[n] initial_values) @nogc {
        data = initial_values;
    }

    static Self add(Self lhs, Self rhs) pure @nogc {
        Self new_vec;

        for (int i = 0; i < n; i++) {
            new_vec.data[i] = lhs.data[i] + rhs.data[i];
        }

        return new_vec;
    }

    static Self sub(Self lhs, Self rhs) pure @nogc {
        Self new_vec;

        for (int i = 0; i < n; i++) {
            new_vec.data[i] = lhs.data[i] - rhs.data[i];
        }

        return new_vec;
    }

    static float mult(Self lhs, Self rhs) pure @nogc {
        auto sum = 0.0;

        for (int i = 0; i < n; i++) {
            sum += lhs.data[i] * rhs.data[i];
        }

        return sum;
    }

    static Self mult(K)(Self lhs, K rhs) pure @nogc if (isNumeric!K) {
        Self new_vec;

        for (int i = 0; i < n; i++) {
            new_vec.data[i] = lhs.data[i] * rhs;
        }

        return new_vec;
    }

    auto norm() const pure nothrow {
        T sum = 0;
        foreach (member; data) { sum += member * member; }
        return sqrt(sum);
    }

    void normalize() {
        float norm = norm();
        foreach (ref member; data) { member /= norm; }
    }

    auto opBinary(string op, T)(T rhs) const pure nothrow if ((op == "*" || op == "+" || op == "-" || op == "/")) {
        static if (is(T == Self) || is(T == const(Self))) {
            static if      (op == "+") { return Self.add(this, rhs); }
            else static if (op == "-") { return Self.sub(this, rhs); }
            else static if (op == "*") { return Self.mult(this, rhs); }
            else static assert(0, "Operator " ~ op ~ " not implemented.");
        }
        else static if (isNumeric!T && op == "*") { return Self.mult(this, rhs); }
        else static if (isNumeric!T && op == "/") { return Self.mult(this, (1.0/rhs)); }
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

    string toString() { return Self.stringof ~ to!(string)(this.data); }
}