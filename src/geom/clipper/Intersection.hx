package geom.clipper;
import flash.geom.Point;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

/**
 * Singly-linked list of intersections between edges sorted descending by y.
 */
class Intersection {
	/**
	 * A node in the Active Edge List.
	 */
	public var e1Node:DoublyList <Edge>;
	/**
	 * A node in the Active Edge List.
	 */
	public var e2Node:DoublyList <Edge>;
	/**
	 * Point of intersection of two edges.
	 */
	public var p:Point;
	/**
	 * Pointer to a next intersection node which p.y is not less than p.y of the current node.
	 */
	public var next:Intersection;
	
	public function new ( e1Node:DoublyList <Edge>, e2Node:DoublyList <Edge>, p:Point ) {
		this.e1Node = e1Node;
		this.e2Node = e2Node;
		this.p = p;
	}
	
	public inline function insert ( newIsec:Intersection ):Void {
		var curIsec:Intersection = this;
		var prevIsec:Intersection = null;
		
		do {
			if ( newIsec.p.y > curIsec.p.y ) {
				if ( prevIsec != null )
					prevIsec.next = newIsec;
				
				newIsec.next = curIsec;
				
				return;
			}
			
			prevIsec = curIsec;
			curIsec = curIsec.next;
		} while ( curIsec != null );
		
		prevIsec.next = newIsec;
	}
}