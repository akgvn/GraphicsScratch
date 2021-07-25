import std.traits: isNumeric;
import std.conv: to;

struct Vector(int n, T = float) if (isNumeric!T) {
	T[n] data = 0;

	alias Self = Vector!(n, T);

	this(T[n] initial_values) {
		data = initial_values;
	}

	Self add(Self lhs, Self rhs) pure @nogc {
		Self new_vec;

		for (int i = 0; i < n; i++) {
			new_vec.data[i] = lhs.data[i] + rhs.data[i];
		}

		return new_vec;
	}

	Self sub(Self lhs, Self rhs) pure @nogc {
		Self new_vec;

		for (int i = 0; i < n; i++) {
			new_vec.data[i] = lhs.data[i] - rhs.data[i];
		}

		return new_vec;

	}

	Self mult(Self lhs, Self rhs) pure @nogc {
		Self new_vec;

		for (int i = 0; i < n; i++) {
			new_vec.data[i] = lhs.data[i] * rhs.data[i];
		}

		return new_vec;
	}

	Self mult(K)(Self lhs, K rhs) pure @nogc if (isNumeric!K) {
		Self new_vec;

		for (int i = 0; i < n; i++) {
			new_vec.data[i] = lhs.data[i] * rhs;
		}

		return new_vec;
	}

	string toString() {
		return to!(string)(this.data);
	}
}


// Add
// Sub
// Multiply
// Multiply with Scalar
// Cross product
// Normalize
// Get norm

/*
struct Vec3f {
    float x, y, z;

    float norm() { return sqrt(this.x * this.x + this.y * this.y + this.z * this.z); }

    void normalize() {
        float norm = norm();
        x /= norm;
        y /= norm;
        z /= norm;
    }

    auto opBinary(string op, T)(T rhs) const pure nothrow if ((op == "*" || op == "+" || op == "-")) {
        static if (is(T == Vec3f) || is(T == const(Vec3f))) {
            static if      (op == "+") { return Vec3f(x + rhs.x, y + rhs.y, z + rhs.z); }
            else static if (op == "-") { return Vec3f(x - rhs.x, y - rhs.y, z - rhs.z); }
            else static if (op == "*") { return (x * rhs.x + y * rhs.y + z * rhs.z); }
            else static assert(0, "Operator " ~ op ~ " not implemented.");
        }
        else static if (isNumeric!T && op == "*") { return Vec3f(x * rhs, y * rhs, z * rhs); }
        else static assert(0, "Operator " ~ op ~ " not implemented for " ~ T.stringof ~ ".");
    }

    void print() { printf("Vec3f { %f, %f, %f }\n", this.x, this.y, this.z); }
}
*/
