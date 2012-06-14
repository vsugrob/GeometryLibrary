package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputSettings {
	public var polygons:Bool;
	public var monotoneNoHoleTriangles:Bool;
	public var monotoneNoHoleConvex:Bool;
	public var monotoneNoHolePolygons:Bool;
	public var bounds:Bool;
	public var boundsKind:PolyKind;
	/**
	 * PolyBounds instance that will receive bounds output.
	 */
	public var polyBoundsReceiver:PolyBounds;
	
	public var monotoneNoHoleOutputInvolved (getMonotoneNoHoleOutputInvolved, null):Bool;
	private inline function getMonotoneNoHoleOutputInvolved ():Bool {
		return	monotoneNoHoleTriangles || monotoneNoHoleConvex || monotoneNoHolePolygons;
	}
	
	public var noOutput (getNoOutput, null):Bool;
	private inline function getNoOutput ():Bool {
		return	!( polygons || monotoneNoHoleTriangles || monotoneNoHoleConvex || monotoneNoHolePolygons || bounds );
	}
	
	public function new ( generatePolygons:Bool = true, generateMonotoneNoHoleTriangles:Bool = false,
		generateMonotoneNoHoleConvex:Bool = false, generateMonotoneNoHolePolygons:Bool = false,
		generateBounds:Bool = false, boundsKind:PolyKind = null, polyBoundsReceiver:PolyBounds = null )
	{
		this.polygons = generatePolygons;
		this.monotoneNoHoleTriangles = generateMonotoneNoHoleTriangles;
		this.monotoneNoHoleConvex = generateMonotoneNoHoleConvex;
		this.monotoneNoHolePolygons = generateMonotoneNoHolePolygons;
		this.bounds = generateBounds;
		this.boundsKind = boundsKind;
		this.polyBoundsReceiver = polyBoundsReceiver;
	}
}