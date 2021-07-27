import vec;
import common;
import std.stdio;

void rasterize() {
    auto p0 = Point([-50, -200]);
    auto p1 = Point([60, 240]);

    auto canvas = Canvas(600, 600);

    canvas.DrawLine(p0, p1, Color.WHITE);

    canvas.RenderToFile();

    writeln("Done");
}
