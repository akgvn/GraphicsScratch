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

    void PutPixel(int screen_x, int screen_y, Color color) {
        // Canvas has it's origin point in the middle, but the
        // buffer has it's origin on the top left. Conversion:
        int buffer_x = screen_x + (Cw / 2);
        int buffer_y = (Ch / 2) - screen_y - 1;
        int buffer_idx = buffer_x + buffer_y * Cw;

        // writefln("Ch = %d, Cw = %d --> Ch * Cw = %d", Ch, Cw, Ch * Cw);
        // writefln("screen_x = %5d -> buffer_x = %5d", screen_x, buffer_x);
        // writefln("screen_y = %5d -> buffer_y = %5d", screen_y, buffer_y);
        // writefln("buffer_idx = %d", buffer_idx);

        this.buffer[buffer_idx] = color;
    }

    void RenderToFile(string filename = "out.ppm") {
        // Dump the image to a PPM file.
        import std.stdio  : fopen, puts, fwrite, fclose;
        import std.string : toStringz;
        auto fp = fopen(filename.toStringz(), "wb");
        if (!fp) {
            puts("Can't open file for writing.");
            return;
        }
        scope(exit) fclose(fp);

        import std.format: format;
        auto header = cast(ubyte[]) format("P6\n%d %d\n255\n", Cw, Ch);

        auto header_bytes = fwrite(cast(ubyte*) header, ubyte.sizeof, header.length, fp);
        auto data_bytes = fwrite(cast(ubyte*) buffer, ubyte.sizeof, buffer.length * 3, fp); // Color is 3 bytes, that's why we're multiplying by 3.
        writeln("Written ", header_bytes + data_bytes, " bytes.");
    }
}
