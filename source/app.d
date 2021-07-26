import std.stdio;
import vec;
import canvas;

enum d  = 1;   // Viewport distance
enum Vw = 1;   // Viewport width
enum Vh = 1;   // Viewport height
enum Cw = 600; // Canvas width
enum Ch = 600; // Canvas height

struct Sphere {
    Vec3f center;
    float radius;
    Color color;
    int specular;

    Vec3f normal(const ref Vec3f point) const @nogc pure {
    	immutable direction = point - center;
    	immutable magnitude = direction.norm();

    	return direction / magnitude;
    }
}

struct Scene {
    float viewport_distance = d;
    float viewport_width  = Vw;
    float viewport_height = Vh;
    Sphere[] spheres;
    Light[] lights;
}

enum BACKGROUND_COLOR = Color(255, 255, 255); // White

static Scene scene = {
	spheres: [
		{[0, -1, 3], 1, {255, 0, 0}, 500}, // Red
		{[ 2, 0, 4], 1, {0, 0, 255}, 500}, // Blue
		{[-2, 0, 4], 1, {0, 255, 0}, 10}, // Green
		{[0, -5001, 0], 5000, {255, 255, 0}, 5000}, // Yellow
	],
	lights: [
		Light(Ambient_Light(0.2)),
		Light(Point_Light(0.6, Vec3f([2, 1, 0]))),
		Light(Directional_Light(0.2, Vec3f([1, 4, 4]))),
	]
};

void main() {
	immutable O = Vec3f([0, 0, 0]);

	Canvas!(Ch, Cw) canvas;

	for (int x = - (Cw / 2); x < (Cw / 2); x++) {
		for (int y = - (Ch / 2); y < (Ch / 2); y++) {
			immutable D = CanvasToViewport(x, y);
			immutable color = TraceRay(O, D, d, float.max);
			canvas.PutPixel(x, y, color);
		}
	}

	canvas.RenderToFile();

	writeln("Done.");
}

Vec3f CanvasToViewport(int x, int y) {
	// Casting to float because otherwise
	// numbers are rounded to ints.
	return Vec3f([
		cast(float) (x * Vw) / Cw,
		cast(float) (y * Vh) / Ch,
		cast(float) d
	]);
}

Color TraceRay(const ref Vec3f O, const ref Vec3f D, const float t_min, const float t_max) {
	const closest = ComputeIntersection(O, D, t_min, t_max);
	const closest_sphere = closest[0];
	immutable closest_t = closest[1];

	if (closest_sphere == null) return BACKGROUND_COLOR;

	// Compute intersection
	immutable P = O + (D * closest_t);

	// Compute sphere normal at intersection
	immutable N = (P - closest_sphere.center).normalized();

	return closest_sphere.color * ComputeLighting(P, N, D * -1, closest_sphere.specular);
}

Tuple!(Sphere*, float) ComputeIntersection(const ref Vec3f O, const ref Vec3f D, const float t_min, const float t_max) @nogc {
	auto closest_t = float.max;
	Sphere* closest_sphere = null;

	foreach (ref sphere; scene.spheres) {
		Tuple!(float, float) ts = IntersectRaySphere(O, D, sphere);
		auto t1 = ts[0], t2 = ts[1];

		if ((t1 > t_min) && (t1 < t_max) && (t1 < closest_t)) {
			closest_t = t1;
			closest_sphere = &sphere;
		}
		if ((t2 > t_min) && (t2 < t_max) && (t2 < closest_t)) {
			closest_t = t2;
			closest_sphere = &sphere;
		}
	}

	return tuple(closest_sphere, closest_t);
}

import std.math : sqrt, pow;
import std.typecons : tuple, Tuple;
Tuple!(float, float) IntersectRaySphere(const ref Vec3f O, const ref Vec3f D, const ref Sphere sphere) @nogc {
	immutable r = sphere.radius;
	immutable CO = O - sphere.center;

	immutable a = D * D;
	immutable b = CO * D * 2;
	immutable c = CO * CO - r * r;

	immutable discriminant = b*b - 4*a*c;
    if (discriminant < 0) { return tuple(float.max, float.max); }

	auto t1 = (-b + sqrt(discriminant)) / (2*a);
	auto t2 = (-b - sqrt(discriminant)) / (2*a);

	return tuple(t1, t2);
}

float ComputeLighting(const ref Vec3f P, const ref Vec3f N, const Vec3f viewing_direction, const int specular_exponent) {
	float i = 0.0;

	foreach (ref light; scene.lights) { i += light.ComputeIntensity(P, N, viewing_direction, specular_exponent); }

	return i;
}

struct Light {
	enum Light_Type: ubyte {
		Ambient,
		Point,
		Directional,
	}

	this(Ambient_Light light) @nogc pure {
		type = Light_Type.Ambient;
		al = light;
	}

	this(Point_Light light) @nogc pure {
		type = Light_Type.Point;
		pl = light;
	}

	this(Directional_Light light) @nogc pure {
		type = Light_Type.Directional;
		dl = light;
	}

	Light_Type type;

	// TODO maybe use `sumtype!` instead of dealing with this?
	// I'm curious which approach is faster.
	union {
		Ambient_Light al;
		Point_Light pl;
		Directional_Light dl;
	}

	float ComputeIntensity(const ref Vec3f point, const ref Vec3f normal, const ref Vec3f viewing_direction, const int specular_exponent) const @nogc {
		Vec3f L;
		float intensity, t_max;

		final switch (type) {
			case Light_Type.Ambient:
				return al.intensity;
			case Light_Type.Point:
				L = pl.position - point;
				intensity = pl.intensity;
				t_max = 1;
				break;
			case Light_Type.Directional:
				L = dl.direction;
				intensity = dl.intensity;
				t_max = float.max;
				break;
		}

		// Shadow check
		const shadow_data = ComputeIntersection(point, L, 0.001, t_max);
		if (shadow_data[0] != null) { return 0; }

		// Diffuse lighting
		immutable n_dot_l = normal * L;

		auto i = 0.0;
		if (n_dot_l > 0) { i = (intensity * n_dot_l) / (normal.norm() * L.norm()); }

		// Specular lighting
		if (specular_exponent != -1) {
			immutable R = ((normal * 2) * n_dot_l) - L;
			immutable r_dot_v = R * viewing_direction;

			if (r_dot_v > 0) {
				i += intensity * pow(r_dot_v / (R.norm() * viewing_direction.norm()), specular_exponent);
			}
		}

		return i;
	}
}

struct Ambient_Light {
	float intensity;
}

struct Point_Light {
	float intensity;
	Vec3f position;
}

struct Directional_Light {
	float intensity;
	Vec3f direction;
}
