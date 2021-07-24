//
// This file is a direct C to D port of
// geometry.c, geometry.h and raytracing.c
// from github.com/akgvn/Graphics
//
// The reason for doing this port is that
// I wanted to see the differences between
// C and D.
//
// Since the code should be working, I'll
// try to slowly use more and more D features
// instead of relying on C-style code.
//
// - akgvn, 2021/07/24
//


struct Vec2f {
    float x, y;
    void print() { printf("Vec2f { %f, %f }\n", this.x, this.y); }
}

struct Vec3f {
    float x, y, z;

    float norm() { return sqrt(this.x * this.x + this.y * this.y + this.z * this.z); }

    void normalize() {
        float norm = norm();
        x /= norm;
        y /= norm;
        z /= norm;
    }

    static float multiply(Vec3f lhs, Vec3f rhs) { return (lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z); }

    static Vec3f multiply(Vec3f lhs, float rhs) {
        Vec3f ret = {
            x : lhs.x * rhs,
            y : lhs.y * rhs,
            z : lhs.z * rhs,
        };
        return ret;
    }

    static Vec3f cross(Vec3f v1, Vec3f v2) {
        Vec3f ret = {
            x : v1.y*v2.z - v1.z*v2.y,
            y : v1.z*v2.x - v1.x*v2.z,
            z : v1.x*v2.y - v1.y*v2.x,
        };
        return ret;
    }

    static Vec3f add(Vec3f lhs, Vec3f rhs) {
        Vec3f ret = {
            x : lhs.x + rhs.x,
            y : lhs.y + rhs.y,
            z : lhs.z + rhs.z,
        };
        return ret;
    }

    static Vec3f sub(Vec3f lhs, Vec3f rhs) {
        Vec3f ret = {
            x : lhs.x - rhs.x,
            y : lhs.y - rhs.y,
            z : lhs.z - rhs.z,
        };
        return ret;
    }

    void print() { printf("Vec3f { %f, %f, %f }\n", this.x, this.y, this.z); }
}

struct Vec4f {
    float x, y, z, w;

    void print() { printf("Vec4f { %f, %f, %f, %f }\n", this.x, this.y, this.z, this.w); }

    static float multiply(Vec4f lhs, Vec4f rhs) {
        return (lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w);
    }

    static Vec4f multiply(Vec4f lhs, float rhs) {
        Vec4f ret = {
            x : lhs.x * rhs,
            y : lhs.y * rhs,
            z : lhs.z * rhs,
            w : lhs.w * rhs,
        };
        return ret;
    }

    static Vec4f add(Vec4f lhs, Vec4f rhs) {
        Vec4f ret = {
            x : lhs.x + rhs.x,
            y : lhs.y + rhs.y,
            z : lhs.z + rhs.z,
            w : lhs.w + rhs.w,
        };
        return ret;
    }

    static Vec4f sub(Vec4f lhs, Vec4f rhs) {
        Vec4f ret = {
            x : lhs.x - rhs.x,
            y : lhs.y - rhs.y,
            z : lhs.z - rhs.z,
            w : lhs.w - rhs.w,
        };
        return ret;
    }

}

import std.stdio : printf, fopen, puts, sprintf, fwrite, fclose;
import std.math : PI, sqrt, pow, fabs, tan;

enum WIDTH = 1024;
enum HEIGHT = 768;
enum FOV = (PI/2.0);

// NOTE: Maybe move these structs to a Raytracing.h?
struct Material {
    float refractive_index = 1.0;
    Vec4f albedo = {1.0, 0.0, 0.0, 0.0};
    Vec3f diffuse_color = {0.0, 0.0, 0.0};
    float specular_exponent = 0.0; // "shininess"?
};

struct Sphere {
    Vec3f center;
    float radius;
    Material material;
};

struct Ray {
    Vec3f origin;
    Vec3f direction;
};

struct Light {
    Vec3f position;
    float intensity;
};


// Returns true if the ray intersects the sphere.
// Also mutates the first_intersect_distance parameter to reflect the location of the first intersection.
static bool
ray_intersects_sphere(const ref Ray ray, const ref Sphere sphere, ref float first_intersect_distance) {
    // The fact that this function is not self-explanatory saddens me. Especially since I'm
    // trying to name things in an explanatory way. I'll put a list of resources to
    // understand what is going on here to the readme.

    Vec3f L = Vec3f.sub(sphere.center, ray.origin); // sphere_center_to_ray_origin_distance

    float tc = Vec3f.multiply(L, ray.direction); // tc is the distance of sphere center to ray origin along the ray direction vector.

    float center_to_ray_straight_distance = Vec3f.multiply(L, L) - tc*tc;
    float radius_squared = sphere.radius * sphere.radius;

    // Check if the ray is not inside the sphere
    if (center_to_ray_straight_distance > radius_squared) return false;

    float half_length_of_ray_inside_circle = sqrt(radius_squared - center_to_ray_straight_distance);

    first_intersect_distance      = tc - half_length_of_ray_inside_circle;
    float last_intersect_distance = tc + half_length_of_ray_inside_circle;

    // If looking at earlier commits, you might see that I thought the compiler optimizes out some of the next 3 lines.
    // Actually it doesn't, I was comparing a float* to 0. So the compiler thought, rightly, we'd never execute the
    // if (pointer is lower than 0) { do thing } instruction. There should really be a warning for this, and if there is one,
    // it should really be enabled by default.
    if (first_intersect_distance < 0.0) { first_intersect_distance = last_intersect_distance; } // Maybe intersects at only one point?
    if ( last_intersect_distance < 0.0) { return false; }
    else { return true; }
}

Vec3f
reflection_vector(Vec3f light_direction, Vec3f surface_normal) {
    return Vec3f.sub(
        light_direction,
        Vec3f.multiply(surface_normal, 2.0 * Vec3f.multiply(light_direction, surface_normal))
    );
}

Vec3f refraction_vector(Vec3f light_vector, Vec3f normal, float refractive_index) { // Snell's law
    float cos_incidence = -1 * Vec3f.multiply(light_vector, normal); // Cosine of the angle of the incidence

    if      (cos_incidence >  1) { cos_incidence =  1; }
    else if (cos_incidence < -1) { cos_incidence = -1; }

    float refractive_indices_ratio; // n1 / n2, n1 is refractive index of outside, n2 is inside object
    Vec3f refraction_normal;

    if (cos_incidence < 0) { // Is the ray inside the object?
        cos_incidence = -cos_incidence;
        refractive_indices_ratio = refractive_index; // swap the indices
        refraction_normal = Vec3f.multiply(normal, -1); // invert the normal
    } else { // not inside the object, go on
        refractive_indices_ratio = 1.0 / refractive_index;
        refraction_normal = normal;
    }

    float cos_refraction_squared = 1 - ((refractive_indices_ratio * refractive_indices_ratio) * (1 - cos_incidence*cos_incidence));
    if (cos_refraction_squared < 0) {
        return Vec3f(0, 0, 0);
    } else {
        return Vec3f.add(
            Vec3f.multiply(light_vector, refractive_indices_ratio),
            Vec3f.multiply(refraction_normal, (refractive_indices_ratio * cos_incidence) - sqrt(cos_refraction_squared))
        );
    }
}

static bool
scene_intersect(ref const Ray ray, const Sphere[] spheres, ref Vec3f hit_point, ref Vec3f surface_normal, ref Material material) {
    float spheres_distance = float.max;

    foreach (ref current_sphere; spheres) {
        float distance_of_i;
        bool current_sphere_intersects = ray_intersects_sphere(ray, current_sphere, distance_of_i);

        // Finds the closest sphere.
        if (current_sphere_intersects && (distance_of_i < spheres_distance)) {
            spheres_distance = distance_of_i;

            hit_point = Vec3f.add(ray.origin, Vec3f.multiply(ray.direction, distance_of_i));

            surface_normal = Vec3f.sub(hit_point, current_sphere.center);
            surface_normal.normalize();

            material = current_sphere.material;
        }
    }

    float checkerboard_distance = float.max;

    if (fabs(ray.direction.y) > 1e-3)  {

        float board_distance = -(ray.origin.y+4) / ray.direction.y; // the checkerboard plane has equation y = -4
        Vec3f board_hit_point = Vec3f.add(
            ray.origin,
            Vec3f.multiply(ray.direction, board_distance)
        );

        if (board_distance>0 && fabs(board_hit_point.x)<10 && board_hit_point.z<-10 && board_hit_point.z>-30 && board_distance<spheres_distance) {
            checkerboard_distance = board_distance;
            hit_point = board_hit_point;
            surface_normal = Vec3f(0, 1, 0);

            int white_or_orange = (cast(int)(.5*hit_point.x+1000) + cast(int)(.5*hit_point.z));

            material.diffuse_color = white_or_orange & 1 ? Vec3f(1, 1, 1) : Vec3f(1, 0.7, 0.3);
            material.diffuse_color = Vec3f.multiply(material.diffuse_color, 0.3);
        }
    }
    return (spheres_distance<1000) || (checkerboard_distance<1000);
}

// Return color of the sphere if intersected, otherwise returns background color.
static Vec3f
cast_ray(const ref Ray ray, const Sphere[] spheres, const Light[] lights, size_t depth) {
    Vec3f point, surface_normal;
    Material material;

    if (depth > 5 || !scene_intersect(ray, spheres, point, surface_normal, material)) {
        return Vec3f(0.2, 0.7, 0.8); // Background color
    }

    Vec3f reflect_color;
    {   // Reflection stuff happens in this scope.
        Vec3f reflect_direction = reflection_vector(ray.direction, surface_normal); reflect_direction.normalize();

        Vec3f reflect_origin; // offset the original point to avoid occlusion by the object itself
        {
            if (Vec3f.multiply(reflect_direction, surface_normal) < 0) {
                reflect_origin = Vec3f.sub(point, Vec3f.multiply(surface_normal, 1e-3));
            } else {
                reflect_origin = Vec3f.add(point, Vec3f.multiply(surface_normal, 1e-3));
            }
        }

        Ray reflection_ray  = { reflect_origin, reflect_direction };
        reflect_color = cast_ray(reflection_ray, spheres, lights, depth + 1);
    }

    Vec3f refract_color;
    {   // refraction stuff happens in this scope.
        Vec3f refract_direction = refraction_vector(ray.direction, surface_normal, material.refractive_index); refract_direction.normalize();

        Vec3f refract_origin;
        {
            if (Vec3f.multiply(refract_direction, surface_normal) < 0) {
                refract_origin = Vec3f.sub(point, Vec3f.multiply(surface_normal, 1e-3));
            } else {
                refract_origin = Vec3f.add(point, Vec3f.multiply(surface_normal, 1e-3));
            }
        }

        Ray refraction_ray  = { refract_origin, refract_direction };
        refract_color = cast_ray(refraction_ray, spheres, lights, depth + 1);
    }

    float diffuse_light_intensity = 0, specular_light_intensity = 0;
    foreach (ref current_light; lights) {
        Vec3f light_direction = Vec3f.sub(current_light.position, point);
        light_direction.normalize();

        bool in_shadow = false;
        {
            // Can this point see the current light?
            Vec3f light_to_point_vec = Vec3f.sub(current_light.position, point);
            float light_distance = light_to_point_vec.norm();

            Vec3f shadow_origin;
            if (Vec3f.multiply(light_direction, surface_normal) < 0) {
                shadow_origin = Vec3f.sub(point, Vec3f.multiply(surface_normal, 1e-3));
            } else {
                shadow_origin = Vec3f.add(point, Vec3f.multiply(surface_normal, 1e-3));
            }

            Vec3f shadow_point, shadow_normal; Material temp_material;

            Ray temp_ray = {shadow_origin, light_direction};
            bool light_intersected = scene_intersect(temp_ray, spheres, shadow_point, shadow_normal, temp_material);
            Vec3f pt_to_origin = Vec3f.sub(shadow_point, shadow_origin);
            bool obstruction_closer_than_light = pt_to_origin.norm() < light_distance;
            in_shadow = light_intersected && obstruction_closer_than_light;
        }
        if (in_shadow) continue;

        // Diffuse Lighting:
        float surface_illumination_intensity = Vec3f.multiply(light_direction, surface_normal);
        if (surface_illumination_intensity < 0) surface_illumination_intensity = 0;
        diffuse_light_intensity += current_light.intensity * surface_illumination_intensity;

        // Specular Lighting:
        float specular_illumination_intensity = Vec3f.multiply(reflection_vector(light_direction, surface_normal), ray.direction);
        if (specular_illumination_intensity < 0) specular_illumination_intensity = 0;
        specular_illumination_intensity = pow(specular_illumination_intensity, material.specular_exponent);
        specular_light_intensity += current_light.intensity * specular_illumination_intensity;
    }

    Vec3f lighting = Vec3f.add(
        Vec3f.multiply(material.diffuse_color, diffuse_light_intensity * material.albedo.x),
        Vec3f.multiply(Vec3f(1.0, 1.0, 1.0), specular_light_intensity * material.albedo.y)
    );

    Vec3f reflect_refract = Vec3f.add(
        Vec3f.multiply(reflect_color, material.albedo.z),
        Vec3f.multiply(refract_color, material.albedo.w)
    );

    return Vec3f.add(lighting, reflect_refract);
}

// NOTE: Move this to a utils.h (?) when working on Raycasting or Software Rendering.
void
dump_ppm_image(Vec3f[] buffer, int width, int height) {
    // Size of buffer parametre must be width * height!
    // Dump the image to a PPM file.

    auto fp = fopen("out.ppm", "wb");
    if (!fp) {
        puts("Can't open file for writing.");
        return;
    }

    char[64] header;
    size_t count = sprintf(cast(char*)header, "P6\n%d %d\n255\n", width, height);
    fwrite(cast(void*)header, ubyte.sizeof, count, fp); // Write the PPM header.

    foreach (ref pixel; buffer) {
        {
            // Check if any of the vec elements is greater than one.
            float max = pixel.x > pixel.y ? pixel.x : pixel.y;
            max = max > pixel.z ? max : pixel.z;

            if (max > 1) {
                pixel.x /= max;
                pixel.y /= max;
                pixel.z /= max;
            }
        }

        ubyte x = cast(ubyte)(pixel.x * 255);
        ubyte y = cast(ubyte)(pixel.y * 255);
        ubyte z = cast(ubyte)(pixel.z * 255);

        ubyte[3] rgb = [x, y, z];

        // Note to self: fwrite moves the file cursor,
        // no need to use fseek or something.
        fwrite(cast(void*)rgb, ubyte.sizeof, 3, fp);
    }

    fclose(fp);
}

static void
render(const Sphere[] spheres, const Light[] lights) {
    Vec3f[] framebuffer = new Vec3f[WIDTH * HEIGHT];

    // Each pixel in the resulting image will have an RGB value, represented by the Vec3f type.
    for (size_t row = 0; row < HEIGHT; row++) {
        for (size_t col = 0; col < WIDTH; col++) {
            // Sweeping the field of view with rays.

            const float camera_screen_distance = 1.0;
            float screen_width = 2 * tan(FOV/2.) * camera_screen_distance;
            float x =  (screen_width * (col + 0.5)/cast(float)WIDTH  - 1)* WIDTH/cast(float)HEIGHT;
            float y = -(screen_width * (row + 0.5)/cast(float)HEIGHT - 1);

            Vec3f dir = {x, y, -1};

            dir.normalize();
            Ray ray = {origin: Vec3f(0, 0, 0), direction: dir};

            // Writing [col * row + WIDTH] instead of the current expression just cost
            // me 1.5 hours of debugging. Sigh. Don't write code when you're sleepy!
            framebuffer[col + row * WIDTH] = cast_ray(ray, spheres, lights, 0);
        }
    }

    dump_ppm_image(framebuffer, WIDTH, HEIGHT);
}

void main() {
    Material      ivory = {1.0, {0.6,  0.3, 0.1, 0.0}, {0.4, 0.4, 0.3},   50.0};
    Material      glass = {1.5, {0.0,  0.5, 0.1, 0.8}, {0.6, 0.7, 0.8},  125.0};
    Material red_rubber = {1.0, {0.9,  0.1, 0.0, 0.0}, {0.3, 0.1, 0.1},   10.0};
    Material     mirror = {1.0, {0.0, 10.0, 0.8, 0.0}, {1.0, 1.0, 1.0}, 1425.0};

    Sphere[] spheres = [
        {center: Vec3f(-3,    0,   -16), radius: 2, material:      ivory},
        {center: Vec3f(-1.0, -1.5, -12), radius: 2, material:      glass},
        {center: Vec3f( 1.5, -0.5, -18), radius: 3, material: red_rubber},
        {center: Vec3f( 7,    5,   -18), radius: 4, material:     mirror},
    ];

    Light[] lights = [
        {position: Vec3f(-20, 20,  20), intensity: 1.5},
        {position: Vec3f( 30, 50, -25), intensity: 1.8},
        {position: Vec3f( 30, 20,  30), intensity: 1.7},
    ];

    render(spheres, lights);
}
