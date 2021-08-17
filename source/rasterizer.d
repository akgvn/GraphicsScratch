import vec;
import common;
import std.stdio;

void rasterize() {
    Scene scene;
    scene.camera = Camera(Vec3f(-3, 1, 2), MakeOYRotationMatrix(-30));

    auto canvas = Canvas(scene.canvas_width, scene.canvas_height);

    populate_scene(scene);
    scene.Render(canvas);

    canvas.RenderToFile();

    writeln("Done");
}

void populate_scene(ref Scene scene) {
    Model model;

    model.vertices = [
        Vertex( 1,  1,  1, 1),
        Vertex(-1,  1,  1, 1),
        Vertex(-1, -1,  1, 1),
        Vertex( 1, -1,  1, 1),
        Vertex( 1,  1, -1, 1),
        Vertex(-1,  1, -1, 1),
        Vertex(-1, -1, -1, 1),
        Vertex( 1, -1, -1, 1),
    ];

    model.triangles = [
        Model.Triangle([0, 1, 2], Color.RED),
        Model.Triangle([0, 2, 3], Color.RED),
        Model.Triangle([4, 0, 3], Color.GREEN),
        Model.Triangle([4, 3, 7], Color.GREEN),
        Model.Triangle([5, 4, 7], Color.BLUE),
        Model.Triangle([5, 7, 6], Color.BLUE),
        Model.Triangle([1, 5, 6], Color.YELLOW),
        Model.Triangle([1, 6, 2], Color.YELLOW),
        Model.Triangle([4, 5, 1], Color.PURPLE),
        Model.Triangle([4, 1, 0], Color.PURPLE),
        Model.Triangle([2, 6, 7], Color.CYAN),
        Model.Triangle([2, 7, 3], Color.CYAN),
    ];

    scene.models = [model];
    scene.instances = [
        Scene.Instance(0, Vec3f(-1.5, 0, 7), Identity4, 0.75),
        Scene.Instance(0, Vec3f(1.25, 2.5, 7.5), MakeOYRotationMatrix(195)),
    ];
}

struct Model {
    struct Triangle {
        int[3] indices;
        Color color;

        void Render(const ref Point[] projected, ref Canvas canvas) const {
            canvas.DrawWireframeTriangle(
                projected[indices[0]],
                projected[indices[1]],
                projected[indices[2]],
                color
            );
        }
    }

    Triangle[] triangles;
    Vertex[] vertices;

    void Render(const ref Scene scene, ref Canvas canvas, Mat4 transform_matrix = Identity4) const {
        auto projected = new Point[vertices.length];

        foreach (idx, vertex; vertices) {
            projected[idx] = scene.ProjectVertex(scene.camera.CameraMatrix * transform_matrix * vertex);
        }

        foreach (triangle; triangles) {
            triangle.Render(projected, canvas);
        }
    }
}

Mat4 MakeOYRotationMatrix(float degrees) @nogc {
    import std.math : sin, cos, PI;
    float cosine = cos(degrees * PI/180.0);
    float sine   = sin(degrees * PI/180.0);

    return Mat4([
        [cosine, 0,  -sine, 0],
        [    0f, 1,      0, 0],
        [  sine, 0, cosine, 0],
        [    0f, 0,      0, 1]
    ]);
}

Mat4 MakeTranslationMatrix(Vec3f translation_vector) @nogc {
    const x = translation_vector.x;
    const y = translation_vector.y;
    const z = translation_vector.z;

    return Mat4([
        [1, 0, 0,  x],
        [0, 1, 0,  y],
        [0, 0, 1,  z],
        [0, 0, 0, 1f]
    ]);
}

Mat4 MakeScalingMatrix(float scale) @nogc {
    return Mat4([
        [scale,     0,     0, 0],
        [    0, scale,     0, 0],
        [    0,     0, scale, 0],
        [   0f,     0,     0, 1],
    ]);
}

struct Camera {
    Vec3f position;
    Mat4 orientation = Identity4;

    Mat4 CameraMatrix() const @nogc {
        return orientation.Transposed() * MakeTranslationMatrix(position * -1);
    }
}

struct Scene {
    float viewport_distance = 1;
    float viewport_width  = 1;
    float viewport_height = 1;
    int canvas_width  = 600;
    int canvas_height = 600;
    Camera camera;
    Model[] models;
    Instance[] instances;

    struct Instance {
        int model_idx;
        Vec3f pos;
        Mat4 orientation = Identity4;
        float scale = 1;

        Mat4 TransformMatrix() const @nogc {
            return MakeTranslationMatrix(this.pos) * (this.orientation * MakeScalingMatrix(this.scale));
        }
    }

    Vec3f CanvasToViewport(int x, int y) const @nogc nothrow {
        return Vec3f(
            (x * viewport_width) / canvas_width,
            (y * viewport_height) / canvas_height,
            viewport_distance
        );
    }

    Point ViewportToCanvas(float x, float y) const @nogc nothrow {
        return Point(
            cast(int) ((x * canvas_width)  / viewport_width),
            cast(int) ((y * canvas_height) / viewport_height),
        );
    }

    Point ProjectVertex(Vertex v) const @nogc nothrow {
        float px = ((v.x * viewport_distance) / v.z);
        float py = ((v.y * viewport_distance) / v.z);

        return ViewportToCanvas(px, py);
    }

    void Render(ref Canvas canvas) const {
        foreach(ref instance; instances) {
            models[instance.model_idx].Render(this, canvas, instance.TransformMatrix());
        }
    }
}