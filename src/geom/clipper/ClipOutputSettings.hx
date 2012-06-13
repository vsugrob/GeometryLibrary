package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputSettings {
	public var polygons:Bool;
	public var monotoneNoHoleTriangles:Bool;
	public var monotoneNoHoleConvex:Bool;
	public var bounds:Bool;
	public var monotoneNoHolePolygons:Bool;
	
	public var monotoneNoHoleOutputInvolved (getMonotoneNoHoleOutputInvolved, null):Bool;
	private inline function getMonotoneNoHoleOutputInvolved ():Bool {
		return	monotoneNoHoleTriangles || monotoneNoHoleConvex || monotoneNoHolePolygons;
	}
	
	public var noOutput (getNoOutput, null):Bool;
	private inline function getNoOutput ():Bool {
		return	!( polygons || monotoneNoHoleTriangles || monotoneNoHoleConvex || bounds || monotoneNoHolePolygons );
	}
	
	public function new ( generatePolygons:Bool = true, generateMonotoneNoHoleTriangles:Bool = false,
		generateMonotoneNoHoleConvex:Bool = false, generateBounds:Bool = false, generateMonotoneNoHolePolygons:Bool = false )
	{
		this.polygons = generatePolygons;
		this.monotoneNoHoleTriangles = generateMonotoneNoHoleTriangles;
		this.monotoneNoHoleConvex = generateMonotoneNoHoleConvex;
		this.bounds = generateBounds;
		this.monotoneNoHolePolygons = generateMonotoneNoHolePolygons;
	}
}