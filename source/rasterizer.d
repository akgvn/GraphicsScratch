import vec;
import common;
import std.stdio;

void rasterize() {
    auto canvas = Canvas(600, 600);

    canvas.DrawLine(Point([-200, -100]), Point([240, 120]), Color.WHITE);
    canvas.DrawLine(Point([-50,  -200]), Point([60,  240]), Color.WHITE);

    canvas.RenderToFile();

    writeln("Done");
}
