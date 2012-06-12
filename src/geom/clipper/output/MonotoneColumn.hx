package geom.clipper.output;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class MonotoneColumn {
	public var polys:DoublyList <ChainedPolygon>;
	private var poly:ChainedPolygon;
	public var leftBound:OutputBound;
	public var rightBound (getRightBound, null):OutputBound;
	private inline function getRightBound ():OutputBound {
		return	leftBound.next;
	}
	
	public function new ( p:Point, leftBound:OutputBound ) {
		this.poly = ChainedPolygon.create ( p );
		this.polys = new DoublyList <ChainedPolygon> ();
		this.polys.insertFirst ( this.poly );
		this.leftBound = leftBound;
	}
	
	public inline function addLeft ( p:Point ):Void {
		poly.prependPoint ( p );
	}
	
	public inline function addRight ( p:Point ):Void {
		poly.appendPoint ( p );
	}
	
	public inline function merge ( other:MonotoneColumn ):Void {
		polys.prepend ( other.polys );
	}
	
	public inline function flush ():Void {
		// no action
	}
}