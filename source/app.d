import std.stdio;
import vec;
import canvas;
import old_raytracer;

void main() {
	// Integrating the new utility functions into the old
	// raytracer so that we'll know if something is broken.
	old_raytracer_main();
	writeln("Done");
}
