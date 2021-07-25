// import std.stdio;
// import std.typecons: tuple;

module canvas;

import vec;
alias Color = Vector!(3, float);

struct Canvas(int Ch, int Cw) {
    // Color[Ch * Cw] buffer; // TODO Program breaks when this is used. (Segmentation fault)
    Color[] buffer = new Color[Ch * Cw];

    void PutPixel(int screen_x, int screen_y, Color color) {
        // Canvas has it's origin point in the middle, but the
        // buffer has it's origin on the top left. Conversion:
        int buffer_x = screen_x + (Cw / 2);
        int buffer_y = (Ch / 2) - screen_y;
        int buffer_idx = buffer_x + buffer_y * Cw;

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
        auto str = cast(ubyte[]) format("P6\n%d %d\n255\n", Cw, Ch);
        fwrite(cast(void*)str, ubyte.sizeof, str.length, fp); // Write the PPM header.

        auto idx = 0;
        auto file_buffer = new ubyte[Cw * Ch * 3];
        foreach (ref pixel; buffer) {
            {
                // Check if any of the vec elements is greater than one.
                import std.algorithm.comparison : max;
                immutable float maximum = max(pixel.x, pixel.y, pixel.z);

                // TODO implement overload for "/="
                if (maximum > 1) { pixel = pixel / maximum; }
            }

            file_buffer[idx + 0] = cast(ubyte)(pixel.x * 255);
            file_buffer[idx + 1] = cast(ubyte)(pixel.y * 255);
            file_buffer[idx + 2] = cast(ubyte)(pixel.z * 255);

            idx += 3;
        }

        // Write it all at once.
        fwrite(cast(void*)file_buffer, ubyte.sizeof, file_buffer.length, fp);
    }
}
