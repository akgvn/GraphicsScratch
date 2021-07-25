import std.stdio;
import vec;
import canvas;
import std.typecons : tuple;
import std.math : sqrt;

alias Vec3f = Vector!(3, float);

enum d  = 1; // Viewport distance
enum Vw = 1; // Viewport width
enum Vh = 1; // Viewport height
enum Cw = 600; // Canvas width
enum Ch = 600; // Canvas height

/*
Scene for ["02: Basic Raytracing"](https://www.gabrielgambetta.com/computer-graphics-from-scratch/02-basic-raytracing.html):
viewport_size = 1 x 1
projection_plane_d = 1
sphere {
    center = (0, -1, 3)
    radius = 1
    color = (255, 0, 0)  # Red
}
sphere {
    center = (2, 0, 4)
    radius = 1
    color = (0, 0, 255)  # Blue
}
sphere {
    center = (-2, 0, 4)
    radius = 1
    color = (0, 255, 0)  # Green
}
*/

struct Sphere {
    Vec3f center;
    float radius;
    Color color;
}

struct Scene {
    float viewport_distance = d, viewport_width = Vw, viewport_height = Vh;
    Sphere[] spheres;
}

enum BACKGROUND_COLOR = Color(255, 255, 255); // White

static Scene scene = {
	spheres: [
		{[0, -1, 3], 1, {255, 0, 0}},
		{[ 2, 0, 4], 1, {0, 0, 255}},
		{[-2, 0, 4], 1, {0, 255, 0}},
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

	writeln("Done");
}

Vec3f CanvasToViewport(int x, int y) {
	// Casting to float because otherwise
	// numbers are rounded to ints.
	return Vec3f([
		cast(float)(x * Vw) / Cw,
		cast(float)(y * Vh) / Ch,
		d
	]);
}

Color TraceRay(Vec3f O, Vec3f D, float t_min, float t_max) {
	auto closest_t = float.max;
	Sphere* closest_sphere = null;

	foreach (ref sphere; scene.spheres) {
		auto ts = IntersectRaySphere(O, D, sphere);
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
	return closest_sphere.color;
}

auto IntersectRaySphere(Vec3f O, Vec3f D, Sphere sphere) {
	auto r = sphere.radius;
	auto CO = O - sphere.center;

	auto a = D * D;
	auto b = CO * D * 2;
	auto c = CO * CO - r * r;

	auto discriminant = b*b - 4*a*c;
    if (discriminant < 0) { return tuple(float.max, float.max); }

	auto t1 = (-b + sqrt(discriminant)) / (2*a);
	auto t2 = (-b - sqrt(discriminant)) / (2*a);

	return tuple(t1, t2);
}
