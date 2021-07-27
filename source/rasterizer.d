import vec;
import common;
import std.stdio;

void rasterize() {
    auto p0 = Point(-200,-100);
    auto p1 = Point(240,120);

    auto canvas = Canvas(600, 600);

    canvas.DrawLine(p0, p1, Color.WHITE);

    RenderToFile(canvas.buffer, 600, 600);

    writeln("Done");
}

struct Canvas {
    int canvas_width, canvas_height;
    Color[] buffer;

    this(int cw, int ch) {
        canvas_width = cw;
        canvas_height = ch;
        buffer = new Color[canvas_width * canvas_height];
    }

    void PutPixel(int screen_x, int screen_y, Color color) @nogc {
        // Canvas has it's origin point in the middle, but the
        // buffer has it's origin on the top left. Conversion:
        int buffer_x = screen_x + (canvas_width / 2);
        int buffer_y = (canvas_height / 2) - screen_y - 1;
        int buffer_idx = buffer_x + buffer_y * canvas_width;

        this.buffer[buffer_idx] = color;
    }

    void DrawLine(Point p0, Point p1, Color color) @nogc {
        if (p0.x > p1.x) {
            // Swap
            auto temp = p0;
            p0 = p1;
            p1 = temp;
        }

        float slope = cast(float)(p1.y - p0.y) / (p1.x - p0.x);
        float y = p0.y;

        for (int x = p0.x; x <= p1.x; x++) {
            PutPixel(x, cast(int) y, color);
            y += slope;
        }
    }
}

struct Point { int x, y; }
