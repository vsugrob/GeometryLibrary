package geom.clipper.output.monotone;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.clipper.ClipOutputSettings;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class MonotoneConvexColumn {
	private var poly:ChainedPolygon;
	public var polys:DoublyList <ChainedPolygon>;
	
	private var monoColumn:MonotoneColumn;
	private var leftBound (getLeftBound, null):OutputBound;
	private inline function getLeftBound ():OutputBound {
		return	monoColumn.leftBound;
	}
	
	private var rightBound (getRightBound, null):OutputBound;
	private inline function getRightBound ():OutputBound {
		return	monoColumn.rightBound;
	}
	
	public inline function new ( p:Point, monoColumn:MonotoneColumn ) {
		this.monoColumn = monoColumn;
		this.poly = ChainedPolygon.create ( p );
		this.polys = new DoublyList <ChainedPolygon> ();
		this.polys.insertFirst ( this.poly );
	}
	
	public inline function addLeft ( p:Point ):Void {
		poly.prependPoint ( p );
		
		if ( !leftBound.isConvexLeft () ) {
			var op = new Point ( rightBound.topX ( p.y ), p.y );
			poly.appendPoint ( op );
			
			poly = ChainedPolygon.create ( p );
			polys.insertLast ( poly );
			poly.appendPoint ( op );
		}
	}
	
	public inline function addRight ( p:Point ):Void {
		poly.appendPoint ( p );
		
		if ( !rightBound.isConvexRight () ) {
			var op = new Point ( leftBound.topX ( p.y ), p.y );
			poly.prependPoint ( op );
			
			poly = ChainedPolygon.create ( p );
			polys.insertLast ( poly );
			poly.prependPoint ( op );
		}
	}
	
	public inline function merge ( other:MonotoneConvexColumn ):Void {
		polys.prepend ( other.polys );
	}
}