import vec;
import common;
import std.stdio;
import std.math : sqrt, pow;
import std.typecons : tuple, Tuple;

struct Sphere {
    Vec3f center;
    float radius;
    Color color;
    int specular;
    float reflective;

    Vec3f normal(const ref Vec3f point) const @nogc pure {
        immutable direction = point - center;
        immutable magnitude = direction.norm();

        return direction / magnitude;
    }
}

struct Camera {
    Vec3f position = Vec3f(0, 0, 0);
    Mat3 rotation = {[
        [1, 0, 0],
        [0, 1, 0],
        [0, 0, 1],
    ]};
}

struct Scene {
    float viewport_distance = 1;
    float viewport_width  = 1;
    float viewport_height = 1;
    int canvas_width  = 600;
    int canvas_height = 600;
    Sphere[] spheres;
    Light[] lights;

    Vec3f CanvasToViewport(int x, int y) const {
        // Casting to float because otherwise
        // numbers are rounded to ints.
        return Vec3f(
            (x * viewport_width) / canvas_width,
            (y * viewport_height) / canvas_height,
            viewport_distance
        );
    }
}

enum BACKGROUND_COLOR = Color.WHITE;

void raytrace() {
    // This is `static immutable` bc Canvas takes some
    // compile-time parameters. Might need to change those to
    // constructor arguments.
    static immutable Scene scene = {
        spheres: [
            {[ 0,    -1, 3],    1,    Color.RED,  500, 0.2},
            {[ 2,     0, 4],    1,   Color.BLUE,  500, 0.4},
            {[-2,     0, 4],    1,  Color.GREEN,   10, 0.3},
            {[ 0, -5001, 0], 5000, Color.YELLOW, 5000, 0.5},
        ],
        lights: [
            Light(0.2),
            Light(Light.Light_Type.Point, 0.6, Vec3f(2, 1, 0)),
            Light(Light.Light_Type.Directional, 0.2, Vec3f(1, 4, 4)),
        ]
    };

    Camera cam;
    cam.position = Vec3f(3, 0, 1);
    cam.rotation = Mat3([
        [0.7071, 0, -0.7071],
        [   0.0, 1,     0.0],
        [0.7071, 0,  0.7071]
    ]);

    auto canvas = Canvas(scene.canvas_width, scene.canvas_height);

    immutable half_width  = (scene.canvas_width / 2);
    immutable half_height = (scene.canvas_height / 2);

    Ray ray;
    foreach (x; -half_width .. half_width) {
        foreach (y; -half_height .. half_height) {
            ray.origin = cam.position;
            ray.direction = scene.CanvasToViewport(x, y) * cam.rotation;

            immutable color = ray.Trace(scene.viewport_distance, float.max, scene);
            canvas.PutPixel(x, y, color);
        }
    }

    canvas.RenderToFile();

    writeln("Done.");
}

struct Ray {
    Vec3f origin;
    Vec3f direction;

    Color Trace(const float t_min, const float t_max, const ref Scene scene, int recursion_depth = 3) const @nogc {
        const closest = ComputeIntersection(this, t_min, t_max, scene.spheres);
        const closest_sphere = closest[0];
        immutable closest_t = closest[1];

        if (closest_sphere == null) return BACKGROUND_COLOR;

        Ray surface_normal;

        // Compute intersection
        surface_normal.origin = this.origin + (this.direction * closest_t);

        // Compute sphere normal at intersection
        surface_normal.direction = (surface_normal.origin - closest_sphere.center).normalized();

        auto local_color = closest_sphere.color * ComputeLighting(surface_normal, this.direction * -1, closest_sphere.specular, scene);

        // Reflections
        const float r = closest_sphere.reflective;
        if (recursion_depth <= 0 || r <= 0.0) return local_color;

        // Reflected color
        auto negD = this.direction * -1;

        Ray reflection_ray = {
            origin : surface_normal.origin,
            direction : Ray.Reflect(negD, surface_normal.direction),
        };

        auto reflected_color = reflection_ray.Trace(0.05, float.max, scene, recursion_depth - 1);

        return (local_color * (1 - r)) + (reflected_color * r);
    }

    Tuple!(float, float) IntersectSphere(const ref Sphere sphere) const @nogc {
        immutable r = sphere.radius;
        immutable CO = this.origin - sphere.center;

        immutable a = this.direction * this.direction;
        immutable b = CO * this.direction * 2;
        immutable c = CO * CO - r * r;

        immutable discriminant = b*b - 4*a*c;
        if (discriminant < 0) { return tuple(float.max, float.max); }

        float t1 = (-b + sqrt(discriminant)) / (2*a);
        float t2 = (-b - sqrt(discriminant)) / (2*a);

        return tuple(t1, t2);
    }

    static Vec3f Reflect(const ref Vec3f direction_to_reflect, const ref Vec3f normal) @nogc {
        immutable n_dot_r = normal * direction_to_reflect;
        immutable normal2 = normal * 2;
        return (normal2 * n_dot_r) - direction_to_reflect;
    }

}

Tuple!(const(Sphere)*, float) ComputeIntersection(const ref Ray ray, const float t_min, const float t_max, const Sphere[] spheres) @nogc {
    auto closest_t = float.max;
    const(Sphere)* closest_sphere = null;

    foreach (ref sphere; spheres) {
        Tuple!(float, float) ts = ray.IntersectSphere(sphere);

        const auto t1 = ts[0], t2 = ts[1];

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

float ComputeLighting(const ref Ray point_on_surface, const Vec3f viewing_direction, const int specular_exponent, const ref Scene scene) @nogc {
    float i = 0.0;

    foreach (ref light; scene.lights) { i += light.ComputeIntensity(point_on_surface, viewing_direction, specular_exponent, scene.spheres); }

    return i;
}

struct Light {
    private enum Light_Type { Ambient, Point, Directional }

    this(float intensity) @nogc pure { this.intensity = intensity; type = Light_Type.Ambient; }
    this(Light_Type type, float intensity, Vec3f pos_or_dir) @nogc pure {
        this.type = type;
        this.intensity = intensity;
        this.position_or_direction = pos_or_dir;
    }

    Light_Type type;
    float intensity;
    Vec3f position_or_direction;

    float ComputeIntensity(const ref Ray point_on_surface, const ref Vec3f viewing_direction, const int specular_exponent, const ref Sphere[] spheres) const @nogc {
        Vec3f light_direction;
        float t_max;

        final switch (type) {
            case Light_Type.Ambient:
                return intensity;
            case Light_Type.Point:
                light_direction = position_or_direction - point_on_surface.origin;
                t_max = 1;
                break;
            case Light_Type.Directional:
                light_direction = position_or_direction;
                t_max = float.max;
                break;
        }

        auto surface_towards_light = Ray(point_on_surface.origin, light_direction);

        // Shadow check
        const shadow_data = ComputeIntersection(surface_towards_light, 0.001, t_max, spheres);
        if (shadow_data[0] != null) { return 0; }

        // Diffuse lighting
        immutable n_dot_l = point_on_surface.direction * light_direction;

        auto i = 0.0;
        if (n_dot_l > 0) { i = (intensity * n_dot_l) / (point_on_surface.direction.norm() * light_direction.norm()); }

        // Specular lighting
        if (specular_exponent != -1) {
            immutable R = Ray.Reflect(light_direction, point_on_surface.direction);
            immutable r_dot_v = R * viewing_direction;

            if (r_dot_v > 0) {
                i += intensity * pow(r_dot_v / (R.norm() * viewing_direction.norm()), specular_exponent);
            }
        }

        return i;
    }
}
