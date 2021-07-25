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

    Vec3f normal(const ref Vec3f point) {
    	Vec3f direction = point - center;
    	auto magnitude = direction.norm();

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
		{[0, -1, 3], 1, {255, 0, 0}}, // Red
		{[ 2, 0, 4], 1, {0, 0, 255}}, // Blue
		{[-2, 0, 4], 1, {0, 255, 0}}, // Green
		{[0, -5001, 0], 5000, {255, 255, 0}}, // Yellow
	],
	lights: [
		Light(Ambient_Light(0.2)),
		Light(Point_Light(0.6, Vec3f([2, 1, 0]))),
		Light(Directional_Light(0.2, Vec3f([1, 4, 4]))),
	]
};

void main() {
	// Integrating the new utility functions into the old
	// raytracer so that we'll know if something is broken.
	// old_raytracer_main(); // Not anymore. We're doing new stuff.

	auto O = Vec3f([0, 0, 0]);

	Canvas!(Ch, Cw) canvas;

	for (int x = - (Cw / 2); x < (Cw / 2); x++) {
		for (int y = - (Ch / 2); y < (Ch / 2); y++) {
			auto D = CanvasToViewport(x, y);
			auto color = TraceRay(O, D, d, float.max);
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

	if (closest_sphere == null) return BACKGROUND_COLOR;

	auto P = O + (D * closest_t);  // Compute intersection
	auto N = P - closest_sphere.center;  // Compute sphere normal at intersection
	N.normalize();
	return closest_sphere.color * ComputeLighting(P, N);
}

import std.math : sqrt;
import std.typecons : tuple, Tuple;
Tuple!(float, float) IntersectRaySphere(const ref Vec3f O, const ref Vec3f D, const ref Sphere sphere) {
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

float ComputeLighting(const ref Vec3f P, const ref Vec3f N) {
	float i = 0.0;

	foreach (ref light; scene.lights) { i += light.ComputeIntensity(P, N); }

	return i;
}

struct Light {
	enum Light_Type {
		Ambient,
		Point,
		Directional,
	}

	this(Ambient_Light light) {
		type = Light_Type.Ambient;
		al = light;
	}

	this(Point_Light light) {
		type = Light_Type.Point;
		pl = light;
	}

	this(Directional_Light light) {
		type = Light_Type.Directional;
		dl = light;
	}

	Light_Type type;

	union {
		Ambient_Light al;
		Point_Light pl;
		Directional_Light dl;
	}

	float ComputeIntensity(const ref Vec3f point, const ref Vec3f normal) {
		Vec3f L;
		float intensity;

		final switch (type) {
			case Light_Type.Ambient: return al.intensity;
			case Light_Type.Point:
				L = pl.position - point;
				intensity = pl.intensity;
				break;
			case Light_Type.Directional:
				L = dl.direction;
				intensity = dl.intensity;
				break;
		}

		// Diffuse lighting
		immutable n_dot_l = normal * L;

		auto i = 0.0;
		if (n_dot_l > 0) {
			i = (intensity * n_dot_l) / (normal.norm() * L.norm());
		}

		// Specular will be here soon.

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

