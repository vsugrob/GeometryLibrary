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
	 * Node in the Active Edge List.
	 */
	public var e1Node:ActiveEdge;
	/**
	 * Node in the Active Edge List.
	 */
	public var e2Node:ActiveEdge;
	/**
	 * Point of intersection of two edges.
	 */
	public var p:Point;
	/**
	 * Value which is used for ordering intersection nodes vertically descending by y.
	 * To do this we need to keep ordering by k ascending.
	 */
	public var k:Float;
	/**
	 * Pointer to next intersection node.
	 */
	public var next:Intersection;
	
	public function new ( e1Node:ActiveEdge, e2Node:ActiveEdge, p:Point, k:Float ) {
		this.e1Node = e1Node;
		this.e2Node = e2Node;
		this.p = p;
		this.k = k;
	}
	
	public inline function insert ( newIsec:Intersection ):Void {
		var curIsec:Intersection = this;
		var prevIsec:Intersection = null;
		
		do {
			if ( newIsec.k < curIsec.k ) {
				if ( prevIsec != null )
					prevIsec.next = newIsec;
				
				newIsec.next = curIsec;
				
				break;
			}
			
			prevIsec = curIsec;
			curIsec = curIsec.next;
		} while ( curIsec != null );
		
		if ( curIsec == null )
			prevIsec.next = newIsec;
	}
}