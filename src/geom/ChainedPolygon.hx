package geom;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class ChainedPolygon {
	public var first:PointChain;
	public var last:PointChain;
	
	public function new ( first:PointChain, last:PointChain ) {
		this.first = first;
		this.last = last;
	}
	
	public inline function appendPoint ( p:Point ):Void {
		last.insertNext ( p );
	}
	
	public inline function prependPoint ( p:Point ):Void {
		first.insertPrev ( p );
	}
}