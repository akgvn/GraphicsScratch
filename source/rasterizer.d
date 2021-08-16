import vec;
import common;
import std.stdio;

void rasterize() {
    auto canvas = Canvas(600, 600);

    // canvas.DrawFilledTriangle(Point(-200, -100), Point(240, 120), Point(-50,  -200), Color.GREEN);
    // canvas.DrawWireframeTriangle(Point(-200, -100), Point(240, 120), Point(-50,  -200), Color.BLUE);
    // canvas.DrawShadedTriangle(Point(-200, -250, 0.3), Point(200, 50, 0.1), Point(20, 250, 1.0), Color.BLUE);

    perspective_projection(canvas);

    canvas.RenderToFile();

    writeln("Done");
}

void perspective_projection(ref Canvas canvas) {
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

    Scene s;
    // The front face
    canvas.DrawLine(s.ProjectVertex(vAf), s.ProjectVertex(vBf), Color.BLUE);
    canvas.DrawLine(s.ProjectVertex(vBf), s.ProjectVertex(vCf), Color.BLUE);
    canvas.DrawLine(s.ProjectVertex(vCf), s.ProjectVertex(vDf), Color.BLUE);
    canvas.DrawLine(s.ProjectVertex(vDf), s.ProjectVertex(vAf), Color.BLUE);

    // The back face
    canvas.DrawLine(s.ProjectVertex(vAb), s.ProjectVertex(vBb), Color.RED);
    canvas.DrawLine(s.ProjectVertex(vBb), s.ProjectVertex(vCb), Color.RED);
    canvas.DrawLine(s.ProjectVertex(vCb), s.ProjectVertex(vDb), Color.RED);
    canvas.DrawLine(s.ProjectVertex(vDb), s.ProjectVertex(vAb), Color.RED);

    // The front-to-back edges
    canvas.DrawLine(s.ProjectVertex(vAf), s.ProjectVertex(vAb), Color.GREEN);
    canvas.DrawLine(s.ProjectVertex(vBf), s.ProjectVertex(vBb), Color.GREEN);
    canvas.DrawLine(s.ProjectVertex(vCf), s.ProjectVertex(vCb), Color.GREEN);
    canvas.DrawLine(s.ProjectVertex(vDf), s.ProjectVertex(vDb), Color.GREEN);
}
