import std.stdio;
// import std.typecons: tuple;
import std.traits: isNumeric;
import vec;

private ubyte clamp(T)(T math_expression_result) if (isNumeric!T) {
    if (math_expression_result > 255) return 255;
    else if (math_expression_result < 0) return 0;
    else return cast(ubyte) math_expression_result;
}

struct Color {
    ubyte r, g, b;

    Color opBinary(string op, T)(T rhs) const pure nothrow if ((is(T == Color) && (op == "+" || op == "-")) || (isNumeric!T && (op == "*" || op == "/"))) {
        static if      (op == "+") { return Color(clamp(r + rhs.r), clamp(g + rhs.g), clamp(b + rhs.b)); }
        else static if (op == "-") { return Color(clamp(r - rhs.r), clamp(g - rhs.g), clamp(b - rhs.b)); }
        else static if (op == "*") { return Color(clamp(r * rhs), clamp(g * rhs), clamp(b * rhs)); }
        else static if (op == "/") { return Color(clamp(r / rhs), clamp(g / rhs), clamp(b / rhs)); }
        else static assert(0, "Operator " ~ op ~ " not implemented.");
    }
}

struct Canvas(int Ch, int Cw) {
    // Color[Ch * Cw] buffer; // TODO Program breaks when this is used. (Segmentation fault)
    Color[] buffer = new Color[Ch * Cw];

    // The "camera" is at O = (0, 0, 0), looking towards positive Z axis.

    void PutPixel(int screen_x, int screen_y, Color color) @nogc {
        // Canvas has it's origin point in the middle, but the
        // buffer has it's origin on the top left. Conversion:
        int buffer_x = screen_x + (Cw / 2);
        int buffer_y = (Ch / 2) - screen_y - 1;
        int buffer_idx = buffer_x + buffer_y * Cw;

        this.buffer[buffer_idx] = color;
    }

    void RenderToFile(string filename = "out.ppm") const {
        // Dump the image to a PPM file.
        import std.format: format;
        auto header = cast(ubyte[]) format("P6\n%d %d\n255\n", Cw, Ch);

        // TODO Handle possible exceptions.
        import std.stdio: File;
        auto fp = File(filename, "wb");
        auto writer = fp.lockingBinaryWriter();

        import std.algorithm.mutation: copy;
        header.copy(writer);
        buffer.copy(writer);
    }
}
