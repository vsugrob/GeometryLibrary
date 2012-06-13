package geom.clipper.output.monotone;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.clipper.ClipOutputSettings;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class MonotoneColumn {
	private var outputSettings:ClipOutputSettings;
	public var monoPolyColumn:MonotonePolygonColumn;
	public var trianglesColumn:MonotoneTrianglesColumn;
	public var convexColumn:MonotoneConvexColumn;
	public var leftBound:OutputBound;
	public var rightBound (getRightBound, null):OutputBound;
	private inline function getRightBound ():OutputBound {
		return	leftBound.next;
	}
	
	public inline function new ( p:Point, leftBound:OutputBound, outputSettings:ClipOutputSettings ) {
		this.outputSettings = outputSettings;
		this.leftBound = leftBound;
		
		if ( outputSettings.monotoneNoHolePolygons )
			this.monoPolyColumn = new MonotonePolygonColumn ( p );
		
		if ( outputSettings.monotoneNoHoleTriangles )
			this.trianglesColumn = new MonotoneTrianglesColumn ( p, this );
		
		if ( outputSettings.monotoneNoHoleConvex )
			this.convexColumn = new MonotoneConvexColumn ( p, this );
	}
	
	public inline function addLeft ( p:Point ):Void {
		if ( outputSettings.monotoneNoHolePolygons )
			monoPolyColumn.addLeft ( p );
		
		if ( outputSettings.monotoneNoHoleTriangles )
			trianglesColumn.addLeft ( p );
		
		if ( outputSettings.monotoneNoHoleConvex )
			convexColumn.addLeft ( p );
	}
	
	public inline function addRight ( p:Point ):Void {
		if ( outputSettings.monotoneNoHolePolygons )
			monoPolyColumn.addRight ( p );
		
		if ( outputSettings.monotoneNoHoleTriangles )
			trianglesColumn.addRight ( p );
		
		if ( outputSettings.monotoneNoHoleConvex )
			convexColumn.addRight ( p );
	}
	
	public inline function merge ( other:MonotoneColumn ):Void {
		if ( outputSettings.monotoneNoHolePolygons )
			monoPolyColumn.merge ( other.monoPolyColumn );
		
		if ( outputSettings.monotoneNoHoleTriangles )
			trianglesColumn.merge ( other.trianglesColumn );
		
		if ( outputSettings.monotoneNoHoleConvex )
			convexColumn.merge ( other.convexColumn );
	}
	
	public inline function flush ():Void {
		// flush for monoPolyColumn and convexColumn is not required
		
		if ( outputSettings.monotoneNoHoleTriangles )
			trianglesColumn.flush ();
	}
}