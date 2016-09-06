# Polygon Clipper #

This library implements scanline
[Bala Vatti clipping algorithm](https://en.wikipedia.org/wiki/Vatti_clipping_algorithm)
in Haxe.
It allows you to combine, subtract, intersect and perform Xor operation on arbitrarily shaped polygons
simultaneously with the high efficiency.

![Clipping examples](doc/images/clipping-examples.png)

### Degeneracy handling ###
This library successfully handles input of any complexity.
Input polygons are free to suffer from any imaginable degeneracy.
Vertices can be coincident, collinear, float-epsilon-close to each other.
Contours can be self-intersecting,
segments can be one on top of another.
They can even duplicate each other.
