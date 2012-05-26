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
	 * Indicates whether at least one of the edges is horizontal.
	 */
	public var isHorizontal:Bool;
	/**
	 * Pointer to next intersection node.
	 */
	public var next:Intersection;
	
	public function new ( e1Node:ActiveEdge, e2Node:ActiveEdge, p:Point, k:Float, isHorizontal:Bool = false ) {
		this.e1Node = e1Node;
		this.e2Node = e2Node;
		this.p = p;
		this.k = k;
		this.isHorizontal = isHorizontal;
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
	
	/**
	 * This function calculates where exactly intersection is and it may have
	 * unpredicted behavior in case when edges are parallel to each other.
	 * @param	yb
	 * @param	dy
	 */
	public inline function calculateIntersectionPoint ( yb:Float, dy:Float ):Void {
		if ( p == null ) {
			if ( isHorizontal ) {
				if ( e1Node.edge.isHorizontal ) {
					if ( e2Node.edge.isHorizontal ) {
						/* This calculation reimagines edges as non-horizontal edges with their bottom
						 * ends having x-coordinate in bottomXIntercept and top ends having
						 * x-coordinate in topXIntercept.
						 * Let a, b, c, d be e1Node.bottomXIntercept, e2Node.bottomXIntercept,
						 * e2Node.topXIntercept and e1Node.topXIntercept respectively.
						 * Let x be unknown x-ccordinate of intersection.
						 * 
						 * Solve system of equations:
						 * { ( b - a ) / ( d - c ) == k,
						 *   ( b - x ) / ( x - c ) == k } <=>
						 * ( b - a ) / ( d - c ) == ( b - x ) / ( x - c ) => ( if x - c != 0 )
						 * ( b - a ) * ( x - c ) == ( b - x ) * ( d - c ) <=>
						 * bx - bc - ax + ac == bd - bc - dx + cx <=>
						 * bx - ax + dx - cx == bd - bc + bc - ac <=>
						 * x * ( b - a + d - c ) == bd - ac => ( if b - a + d - c != 0 )
						 * x == ( bd - ac ) / ( b - a + d - c )
						 */
						var x = ( e2Node.bottomXIntercept * e1Node.topXIntercept - e1Node.bottomXIntercept * e2Node.topXIntercept ) /
							( e2Node.bottomXIntercept - e1Node.bottomXIntercept + e1Node.topXIntercept - e2Node.topXIntercept );
						
						p = new Point ( x, yb );
					} else /*if ( e1Node.edge.isHorizontal && !e2Node.edge.isHorizontal )*/
						p = new Point ( e2Node.topXIntercept, yb );
				} else /*if ( !e1Node.edge.isHorizontal && e2Node.edge.isHorizontal )*/
					p = new Point ( e1Node.topXIntercept, yb );
				
				/* Note that we haven't considered case when both edges are non-horizontal.
				 * This is because when both e1 and e2 are non-horizontal, their top x-intercept
				 * equals to bottom x-intercept and that's why these edges will never intersect
				 * when we checking for intersections in context of zero-height scanbeam.*/
			} else {
				/* Let dxt be absolute value of difference between top x intercepts.
				 * Let dxb be absolute value of difference between bottom x intercepts.
				 * Let k be quotient of dxb / dxt.
				 * NOTE on why we chose k to be equal dxb / dxt, not dxt / dxb:
				 * dxb can be zero while dxt can't.
				 * 
				 * System of equations where dy and k are known,
				 * ht and hb are altitudes for top and bottom
				 * triangles respectively:
				 * dy == hb + ht
				 * k == hb / ht
				 * 
				 * From the second eq:
				 * ht = hb / k
				 * 
				 * Substitute into the first eq:
				 * dy == hb + hb / k
				 * dy == hb * ( 1 + 1 / k )
				 * dy / ( 1 + 1 / k ) == hb
				 */
				var hb = dy * k / ( k + 1 );
				var yIsec = yb + hb;
				
				if ( Math.abs ( e1Node.edge.dx ) < Math.abs ( e2Node.edge.dx ) )
					p = new Point ( e1Node.topX ( yIsec ), yIsec );
				else
					p = new Point ( e2Node.topX ( yIsec ), yIsec );
			}
		}
	}
}