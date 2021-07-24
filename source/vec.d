import std.traits: isNumeric;
import std.conv: to;

struct Vector(int n, T = float) if (isNumeric!T) {
	T[n] data = 0;

	Vector!(n, T) add(Vector!(n, T) lhs, Vector!(n, T) rhs) @nogc {
		Vector!(n, T) new_vec;

		for (int i = 0; i < n; i++) {
			new_vec.data[i] = lhs.data[i] + rhs.data[i];
		}

		return new_vec;
	}

	Vector!(n, T) sub(Vector!(n, T) lhs, Vector!(n, T) rhs) @nogc {
		Vector!(n, T) new_vec;

		for (int i = 0; i < n; i++) {
			new_vec.data[i] = lhs.data[i] - rhs.data[i];
		}

		return new_vec;

	}

	Vector!(n, T) mult(Vector!(n, T) lhs, Vector!(n, T) rhs) @nogc {
		Vector!(n, T) new_vec;

		for (int i = 0; i < n; i++) {
			new_vec.data[i] = lhs.data[i] * rhs.data[i];
		}

		return new_vec;
	}

	Vector!(n, T) mult(K)(Vector!(n, T) lhs, K rhs) @nogc if (isNumeric!K) {
		Vector!(n, T) new_vec;

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
