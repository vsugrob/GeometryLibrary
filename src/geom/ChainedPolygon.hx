package geom;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class ChainedPolygon {
	public var first:DoublyList <Point>;
	public var last:DoublyList <Point>;
	
	public function new ( first:DoublyList <Point>, last:DoublyList <Point> ) {
		this.first = first;
		this.last = last;
	}
	
	public inline function appendPoint ( p:Point ):Void {
		last.insertNext ( p );
		last = last.next;
	}
	
	public inline function prependPoint ( p:Point ):Void {
		first.insertPrev ( p );
		first = first.prev;
	}
	
	public function iterator ():Iterator <Point> {
		return	first.iterator ();
	}
}