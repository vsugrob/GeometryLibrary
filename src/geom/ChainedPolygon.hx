package geom;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class ChainedPolygon {
	public var first:DoublyListNode <Point>;
	public var last:DoublyListNode <Point>;
	
	public function new ( first:DoublyListNode <Point>, last:DoublyListNode <Point> ) {
		this.first = first;
		this.last = last;
	}
	
	public static inline function create ( p:Point ):ChainedPolygon {
		var pNode = new DoublyListNode ( p );
		
		return	new ChainedPolygon ( pNode, pNode );
	}
	
	public inline function appendPoint ( p:Point ):Void {
		last.insertNext ( p );
		last = last.next;
	}
	
	public inline function prependPoint ( p:Point ):Void {
		first.insertPrev ( p );
		first = first.prev;
	}
	
	public inline function prepend ( poly:ChainedPolygon ):Void {
		first.prev = poly.last;
		poly.last.next = first;
		first = poly.first;
	}
	
	public inline function append ( poly:ChainedPolygon ):Void {
		last.next = poly.first;
		poly.first.prev = last;
		last = poly.last;
	}
	
	public inline function iterator ():Iterator <Point> {
		return	first.iterator ();
	}
}