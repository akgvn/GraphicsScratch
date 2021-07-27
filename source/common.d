import vec;
import std.math: abs;

import std.traits: isNumeric;
private ubyte clamp(T)(T math_expression_result) if (isNumeric!T) {
    if (math_expression_result > 255) return 255;
    else if (math_expression_result < 0) return 0;
    else return cast(ubyte) math_expression_result;
}

struct Color {
    ubyte r, g, b;

    enum {
        BLACK  = Color(  0,   0,   0),
        WHITE  = Color(255, 255, 255),
        RED    = Color(255,   0,   0),
        GREEN  = Color(  0, 255,   0),
        BLUE   = Color(  0,   0, 255),
        YELLOW = Color(255, 255,   0),
    }

    Color opBinary(string op, T)(T rhs) const pure nothrow if ((is(T == Color) && (op == "+" || op == "-")) || (isNumeric!T && (op == "*" || op == "/"))) {
        static if      (op == "+") { return Color(clamp(r + rhs.r), clamp(g + rhs.g), clamp(b + rhs.b)); }
        else static if (op == "-") { return Color(clamp(r - rhs.r), clamp(g - rhs.g), clamp(b - rhs.b)); }
        else static if (op == "*") { return Color(clamp(r * rhs), clamp(g * rhs), clamp(b * rhs)); }
        else static if (op == "/") { return Color(clamp(r / rhs), clamp(g / rhs), clamp(b / rhs)); }
        else static assert(0, "Operator " ~ op ~ " not implemented.");
    }
}

struct Canvas {
    int canvas_width, canvas_height;
    Color[] buffer; // Color[Ch * Cw] buffer; (Cw and Ch were template parameters) -- TODO Program breaks when this is used. (Segmentation fault)

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

    void DrawLine(Point p0, Point p1, Color color) {
        if (abs(p1.x - p0.x) > abs(p1.y - p0.y)) {
            // Horizontal-ish line.

            if (p0.x > p1.x) { swap(p0, p1); }

            auto ys = Interpolate(p0.x, p0.y, p1.x, p1.y);

            auto initial_x = cast(int) p0.x;
            for (int x = initial_x; x <= p1.x; x++) {
                PutPixel(x, ys[x - initial_x], color);
            }
        } else {
            // Vertical-ish line.

            if (p0.y > p1.y) { swap(p0, p1); }

            auto xs = Interpolate(p0.y, p0.x, p1.y, p1.x);

            auto initial_y = cast(int) p0.y;
            for (int y = initial_y; y <= p1.y; y++) {
                PutPixel(xs[y - initial_y], y, color);
            }
        }
    }

    void RenderToFile(string filename = "out.ppm") const {
        // Dump the image to a PPM file.
        import std.format: format;
        auto header = cast(ubyte[]) format("P6\n%d %d\n255\n", canvas_width, canvas_height);

        // TODO Handle possible exceptions.
        import std.stdio: File;
        auto fp = File(filename, "wb");
        auto writer = fp.lockingBinaryWriter();

        import std.algorithm.mutation: copy;
        header.copy(writer);
        buffer.copy(writer);
    }
}

int[] Interpolate(float independent_0, float dependent_0, float independent_1, float dependent_1) {
    int[] values = [];
    auto slope = (dependent_1 - dependent_0) / (independent_1 - independent_0);
    auto dependent = dependent_0;

    for (auto i = independent_0; i <= independent_1; i++) {
        values ~= cast(int) dependent;
        dependent += slope;
    }

    return values;
}

void swap(T)(ref T lhs, ref T rhs) {
    auto temp = lhs;
    lhs = rhs;
    rhs = temp;
}
