void RenderToFile(Color[] buffer, int canvas_width, int canvas_height, string filename = "out.ppm") {
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
