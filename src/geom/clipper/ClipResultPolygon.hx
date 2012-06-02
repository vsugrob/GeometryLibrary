package geom.clipper;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class ClipResultPolygon {
	public var points:ChainedPolygon;
	public var parent:ClipResultPolygon;
	public var isHole:Bool;
	private var maxY:Float;
	private var idx:UInt;
	
	public function new ( p:Point, parent:ClipResultPolygon, isHole:Bool, idx:UInt ) {
		var pNode:DoublyList <Point> = new DoublyList <Point> ( p );
		this.points = new ChainedPolygon ( pNode, pNode );
		this.parent = parent;
		this.isHole = isHole;
		this.idx = idx;
	}
	
	public inline function addFirst ( p:Point ):Void {
		points.prependPoint ( p );
	}
	
	public inline function addLast ( p:Point ):Void {
		points.appendPoint ( p );
	}
	
	public inline function iterator ():Iterator <Point> {
		return	points.iterator ();
	}
	
	public inline function prepend ( poly:ClipResultPolygon ):Void {
		points.prepend ( poly.points );
		
		if ( this.idx > poly.idx ) {
			this.isHole = poly.isHole;
			this.parent = poly.parent;
		}
	}
	
	public inline function append ( poly:ClipResultPolygon ):Void {
		points.append ( poly.points );
		
		if ( this.idx > poly.idx ) {
			this.isHole = poly.isHole;
			this.parent = poly.parent;
		}
	}
}