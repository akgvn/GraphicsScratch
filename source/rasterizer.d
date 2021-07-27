import vec;
import common;
import std.stdio;

void rasterize() {
    auto canvas = Canvas(600, 600);

    canvas.DrawWireframeTriangle(Point(-200, -100), Point(240, 120), Point(-50,  -200), Color.WHITE);

    canvas.RenderToFile();

    writeln("Done");
}
