import vec;
import std.math: abs, floor;

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
        else static if (op == "*") { return Color(clamp(r * rhs),   clamp(g * rhs),   clamp(b * rhs));   }
        else static if (op == "/") { return Color(clamp(r / rhs),   clamp(g / rhs),   clamp(b / rhs));   }
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

    void RenderToFile(string filename = "out.ppm") const nothrow {
        // Dump the image to a PPM file.
        import std.stdio: File, printf;

        try {
            import std.format: format;
            auto header = cast(ubyte[]) format("P6\n%d %d\n255\n", canvas_width, canvas_height);
            auto fp = File(filename, "wb");
            auto writer = fp.lockingBinaryWriter();

            import std.algorithm.mutation: copy;
            header.copy(writer);
            buffer.copy(writer);

        } catch (Exception e) {
            printf("Error when writing to ppm file."); // Using printf because writeln throws :D
        }
    }

    void PutPixel(int screen_x, int screen_y, Color color) @nogc nothrow {
        // Canvas has it's origin point in the middle, but the
        // buffer has it's origin on the top left. Conversion:
        const int buffer_x   = screen_x + (canvas_width / 2);
        const int buffer_y   = (canvas_height / 2) - screen_y - 1;
        const int buffer_idx = buffer_x + buffer_y * canvas_width;

        immutable x_out_of_bounds   = buffer_x   >  canvas_width  || buffer_x   < 0;
        immutable y_out_of_bounds   = buffer_y   >  canvas_height || buffer_y   < 0;
        immutable idx_out_of_bounds = buffer_idx >= buffer.length || buffer_idx < 0;

        if (x_out_of_bounds || y_out_of_bounds || idx_out_of_bounds) {
            import std.stdio: printf;
            printf("Out of bounds at screen coordinates: %d, %d --> buffer_idx = %d\n", screen_x, screen_y, buffer_idx);
            return;
        }

        this.buffer[buffer_idx] = color;
    }

    //
    // Rasterizer-only functions
    //

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

    void DrawWireframeTriangle(Point p0, Point p1, Point p2, Color color) {
        DrawLine(p0, p1, color);
        DrawLine(p1, p2, color);
        DrawLine(p2, p0, color);
    }

    void DrawFilledTriangle(Point p0, Point p1, Point p2, Color color) {
        // Sort the points so that y0 <= y1 <= y2
        if (p1.y < p0.y) { swap(p1, p0); }
        if (p2.y < p0.y) { swap(p2, p0); }
        if (p2.y < p1.y) { swap(p2, p1); }

        // Compute the x coordinates of the triangle edges
        auto x01 = Interpolate(p0.y, p0.x, p1.y, p1.x);
        auto x02 = Interpolate(p0.y, p0.x, p2.y, p2.x);
        auto x12 = Interpolate(p1.y, p1.x, p2.y, p2.x);

        // Concatenate the short sides
        auto x012 = x01 ~ x12[1..$];

        // Determine which is left and which is right
        auto m = cast(int) floor(cast(real) x012.length / 2.0);

        int[] x_left, x_right;

        // Note to future self about "why is m never out of bounds?":
        // I was confused about why we chose an arbitrary index and indexed
        // into both array with that index. Surely the number of items in
        // both arrays are not the same, right? One of them are going the
        // long way up, and the other is a direct line up.
        //
        // Consider the following and it should be clear:
        //
        // the Interpolate(...) call above finds an x coordinate for each y.
        // Since the y distance (and the number of pixels) are the same for
        // both ways (p0 -> p2 or p0 -> p1 -> p2) and we have only
        // one x value for each y value, length of the arrays must be equal!
        // m is the middle of the array for both arrays, and if you imagine
        // a horizontal line going through the triangle, the intersection points
        // are x02[m] & x012[m].

        if (x02[m] < x012[m]) {
            x_left  = x02;
            x_right = x012;
        } else {
            x_left  = x012;
            x_right = x02;
        }

        // Draw the horizontal segments
        foreach (y; p0.y .. p2.y) { // NOTE(ag): Maybe introduced a bug: it used to be y <= p2.y
            foreach (x; x_left[y - p0.y] .. x_right[y - p0.y]) {
                PutPixel(x, y, color);
            }
        }
    }

    void DrawShadedTriangle(Point p0, Point p1, Point p2, Color color) {
        // Sort the points so that y0 <= y1 <= y2
        if (p1.y < p0.y) { swap(p1, p0); }
        if (p2.y < p0.y) { swap(p2, p0); }
        if (p2.y < p1.y) { swap(p2, p1); }

        // Compute the x coordinates and h values of the triangle edges
        auto x01 = Interpolate(p0.y, p0.x, p1.y, p1.x);
        auto h01 = Interpolate(p0.y, p0.h, p1.y, p1.h);

        auto x12 = Interpolate(p1.y, p1.x, p2.y, p2.x);
        auto h12 = Interpolate(p1.y, p1.h, p2.y, p2.h);

        auto x02 = Interpolate(p0.y, p0.x, p2.y, p2.x);
        auto h02 = Interpolate(p0.y, p0.h, p2.y, p2.h);
        
        // Concatenate the short sides
        auto x012 = x01 ~ x12[1..$];
        auto h012 = h01 ~ h12[1..$];

        // Determine which is left and which is right
        auto m = cast(int) floor(cast(real) x012.length / 2.0);

        int[] x_left, x_right;
        float[] h_left, h_right;

        if (x02[m] < x012[m]) {
            x_left = x02;
            h_left = h02;

            x_right = x012;
            h_right = h012;
        } else {
            x_left = x012;
            h_left = h012;
            
            x_right = x02;
            h_right = h02;
        }

        // Draw the horizontal segments
        foreach (y; p0.y .. p2.y) {
            const x_l = x_left[y - p0.y];
            const x_r = x_right[y - p0.y];

            const h_segment = Interpolate(x_l, h_left[y - p0.y], x_r, h_right[y - p0.y]);
            foreach (x; x_l .. x_r) {
                const shaded_color = color * h_segment[x - x_l];
                PutPixel(x, y, shaded_color);
            }
        }
    }
}

enum isFloatOrInteger(T) = (is(T == int) || is(T == float));

/// Interpolates a unique coordinate for each point between dependent_0 and _1, using independent coordinates.
T[] Interpolate(T)(int independent_0, T dependent_0, int independent_1, T dependent_1) if (isFloatOrInteger!T) {
    auto slope = cast(float) (dependent_1 - dependent_0) / cast(float) (independent_1 - independent_0);
    auto dependent = cast(float) dependent_0;
    const count = (independent_1 - independent_0) + 1;

    auto values = new T[count];
    foreach (i; 0 .. count) {
        values[i] = cast(T) dependent;
        dependent += slope;
    }

    return values;
}

private void swap(T)(ref T lhs, ref T rhs) nothrow @nogc {
    auto temp = lhs;
    lhs = rhs;
    rhs = temp;
}

/*
struct Camera {
    Vec3f position = Vec3f(0, 0, 0);
    Mat3 rotation = {[
        [1, 0, 0],
        [0, 1, 0],
        [0, 0, 1],
    ]};
}
*/

struct Scene {
    float viewport_distance = 1;
    float viewport_width  = 1;
    float viewport_height = 1;
    int canvas_width  = 600;
    int canvas_height = 600;

    Vec3f CanvasToViewport(int x, int y) const @nogc nothrow {
        return Vec3f(
            (x * viewport_width) / canvas_width,
            (y * viewport_height) / canvas_height,
            viewport_distance
        );
    }

    Point ViewportToCanvas(float px, float py) const @nogc nothrow {
        return Point(
            cast(int) ((px * canvas_width)  / viewport_width),
            cast(int) ((py * canvas_height) / viewport_height),
        );
    }

    Point ProjectVertex(Vertex v) const @nogc nothrow {
        float px = ((v.x * viewport_distance) / v.z);
        float py = ((v.y * viewport_distance) / v.z);

        return ViewportToCanvas(px, py);
    }
}
