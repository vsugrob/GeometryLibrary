package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputSettings {
	public var polygons:Bool;
	public var monotoneNoHoleTriangles:Bool;
	public var convex:Bool;
	public var bounds:Bool;
	public var monotoneNoHolePolygons:Bool;
	
	public var monotoneNoHoleOutputInvolved (getMonotoneNoHoleOutputInvolved, null):Bool;
	private inline function getMonotoneNoHoleOutputInvolved ():Bool {
		return	monotoneNoHolePolygons || monotoneNoHoleTriangles;
	}
	
	public var noOutput (getNoOutput, null):Bool;
	private inline function getNoOutput ():Bool {
		return	!( polygons || monotoneNoHoleTriangles || convex || bounds || monotoneNoHolePolygons );
	}
	
	public function new ( generatePolygons:Bool = true, generateMonotoneNoHoleTriangles:Bool = false,
		generateConvex:Bool = false, generateBounds:Bool = false, generateMonotoneNoHolePolygons:Bool = false )
	{
		this.polygons = generatePolygons;
		this.monotoneNoHoleTriangles = generateMonotoneNoHoleTriangles;
		this.convex = generateConvex;
		this.bounds = generateBounds;
		this.monotoneNoHolePolygons = generateMonotoneNoHolePolygons;
	}
}