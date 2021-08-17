import vec;
import common;
import std.stdio;

void rasterize() {
    Scene scene;
    auto canvas = Canvas(scene.canvas_width, scene.canvas_height);

    // canvas.DrawFilledTriangle(Point(-200, -100), Point(240, 120), Point(-50,  -200), Color.GREEN);
    // canvas.DrawWireframeTriangle(Point(-200, -100), Point(240, 120), Point(-50,  -200), Color.BLUE);
    // canvas.DrawShadedTriangle(Point(-200, -250, 0.3), Point(200, 50, 0.1), Point(20, 250, 1.0), Color.BLUE);

    // perspective_projection(scene, canvas);
    representing_a_cube(scene, canvas);

    canvas.RenderToFile();

    writeln("Done");
}

void perspective_projection(ref Scene scene, ref Canvas canvas) {
    // The four "front" vertices
    auto vAf = Vertex(-2, -0.5, 5);
    auto vBf = Vertex(-2,  0.5, 5);
    auto vCf = Vertex(-1,  0.5, 5);
    auto vDf = Vertex(-1, -0.5, 5);

    // The four "back" vertices
    auto vAb = Vertex(-2, -0.5, 6);
    auto vBb = Vertex(-2,  0.5, 6);
    auto vCb = Vertex(-1,  0.5, 6);
    auto vDb = Vertex(-1, -0.5, 6);

    // The front face
    canvas.DrawLine(scene.ProjectVertex(vAf), scene.ProjectVertex(vBf), Color.BLUE);
    canvas.DrawLine(scene.ProjectVertex(vBf), scene.ProjectVertex(vCf), Color.BLUE);
    canvas.DrawLine(scene.ProjectVertex(vCf), scene.ProjectVertex(vDf), Color.BLUE);
    canvas.DrawLine(scene.ProjectVertex(vDf), scene.ProjectVertex(vAf), Color.BLUE);

    // The back face
    canvas.DrawLine(scene.ProjectVertex(vAb), scene.ProjectVertex(vBb), Color.RED);
    canvas.DrawLine(scene.ProjectVertex(vBb), scene.ProjectVertex(vCb), Color.RED);
    canvas.DrawLine(scene.ProjectVertex(vCb), scene.ProjectVertex(vDb), Color.RED);
    canvas.DrawLine(scene.ProjectVertex(vDb), scene.ProjectVertex(vAb), Color.RED);

    // The front-to-back edges
    canvas.DrawLine(scene.ProjectVertex(vAf), scene.ProjectVertex(vAb), Color.GREEN);
    canvas.DrawLine(scene.ProjectVertex(vBf), scene.ProjectVertex(vBb), Color.GREEN);
    canvas.DrawLine(scene.ProjectVertex(vCf), scene.ProjectVertex(vCb), Color.GREEN);
    canvas.DrawLine(scene.ProjectVertex(vDf), scene.ProjectVertex(vDb), Color.GREEN);
}

void representing_a_cube(ref Scene scene, ref Canvas canvas) {
    Model model;

    model.vertices = [
        Vertex( 1,  1,  1),
        Vertex(-1,  1,  1),
        Vertex(-1, -1,  1),
        Vertex( 1, -1,  1),
        Vertex( 1,  1, -1),
        Vertex(-1,  1, -1),
        Vertex(-1, -1, -1),
        Vertex( 1, -1, -1),
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

    auto instances = [
        ModelInstance(&model, Vertex(-1.5, 0, 7)),
        ModelInstance(&model, Vertex(1.25, 2, 7.5))
    ];

    foreach(ref instance; instances) {
        instance.Render(scene, canvas);
    }

    // model.Render(scene, canvas);
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

    void Render(const ref Scene scene, ref Canvas canvas) const {
        auto projected = new Point[vertices.length];

        foreach (idx, vertex; vertices) {
            projected[idx] = scene.ProjectVertex(vertex);
        }

        foreach (triangle; triangles) {
            triangle.Render(projected, canvas);
        }
    }

    void TranslateAndRender(const ref Scene scene, ref Canvas canvas, Vec3f translation_vector) const {
        auto projected = new Point[vertices.length];

        foreach (idx, vertex; vertices) {
            projected[idx] = scene.ProjectVertex(vertex + translation_vector);
        }

        foreach (triangle; triangles) {
            triangle.Render(projected, canvas);
        }
    }

    void Translate(Vec3f translation_vector) {
        foreach(ref vertex; vertices) {
            vertex = vertex + translation_vector;
        }
    }
}

struct ModelInstance {
    Model* model;
    Vec3f pos;

    void Render(const ref Scene scene, ref Canvas canvas) const {
        if (model != null) model.TranslateAndRender(scene, canvas, pos);
        else printf("Error: Null model pointer!\n");
    }
}
