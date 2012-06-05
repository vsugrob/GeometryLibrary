package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputSettings {
	public var polygons:Bool;
	public var triangles:Bool;
	public var convex:Bool;
	public var bounds:Bool;
	public inline var noOutput (getNoOutput, null):Bool;
	
	private inline function getNoOutput ():Bool {
		return	polygons == false && triangles == false && convex == false && bounds == false;
	}
	
	public function new ( generatePolygons:Bool = true, generateTriangles:Bool = false,
		generateConvex:Bool = false, generateBounds:Bool = false )
	{
		this.polygons = generatePolygons;
		this.triangles = generateTriangles;
		this.convex = generateConvex;
		this.bounds = generateBounds;
	}
}