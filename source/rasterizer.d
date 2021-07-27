import vec;
import std.stdio;

void rasterize() {
	writeln("We're in the rasterizer.");
	writeln("We'll do some actual work at some point.");
}

struct Canvas(int Ch, int Cw) {
    Color[] buffer = new Color[Ch * Cw];

    void PutPixel(int screen_x, int screen_y, Color color) @nogc {}
}
