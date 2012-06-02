package geom.clipper;
import geom.ChainedPolygon;

/**
 * ...
 * @author vsugrob
 */

class ActiveEdge {
	public var edge:Edge;
	public var prev:ActiveEdge;
	public var next:ActiveEdge;
	/**
	 * Does edge belong to clip or subject polygon?
	 */
	public var kind:PolyKind;
	/**
	 * Is it a left or right bound edge?
	 */
	public var side:Side;
	/**
	 * Does edge contribute to output polygons?
	 */
	public var contributing:Bool;
	/**
	 * Y-coordinate of the edge's bottom vertex (point with the highest y).
	 */
	public var bottomY:Float;
	/**
	 * X-intercept of the edge with
	 * the line at the bottom of the current scanbeam.
	 */
	public var bottomXIntercept:Float;
	/**
	 * X-intercept of the edge with
	 * the line at the top of the current scanbeam.
	 */
	public var topXIntercept:Float;
	/**
	 * Pointer to partial polygon associated to the edge.
	 */
	public var poly:ChainedPolygon;
	/**
	 * Precasted reference to this instance as ActiveWindingEdge. If this is
	 * not an ActiveWindingEdge, this property will contain null.
	 */
	public var asWindingEdge:ActiveWindingEdge;
	
	public function new ( edge:Edge, kind:PolyKind, prev:ActiveEdge = null, next:ActiveEdge = null ) {
		this.edge = edge;
		this.prev = prev;
		this.next = next;
		this.kind = kind;
	}
	
	public inline function topX ( y:Float ):Float {
		return	edge.bottomX + edge.dx * ( y - bottomY );
	}
	
	public inline function insertNext ( edge:Edge, kind:PolyKind ):Void {
		var dl = new ActiveEdge ( edge, kind, this, this.next );
		
		if ( this.next != null )
			this.next.prev = dl;
		
		this.next = dl;
	}
	
	public inline function insertPrev ( edge:Edge, kind:PolyKind ):Void {
		var dl = new ActiveEdge ( edge, kind, this.prev, this );
		
		if ( this.prev != null )
			this.prev.next = dl;
		
		this.prev = dl;
	}
	
	/**
	 * Removes itself from a chain and sets its next and prev to null. Remember to keep pointer to some other
	 * node of the chain to prevent chain loss.
	 */
	public inline function removeSelf ():Void {
		if ( this.prev != null )
			this.prev.next = this.next;
		
		if ( this.next != null )
			this.next.prev = this.prev;
		
		this.prev = null;
		this.next = null;
	}
	
	public inline function removeNext ():Void {
		if ( this.next != null )
			this.next.removeSelf ();
	}
	
	public inline function removePrev ():Void {
		if ( this.prev != null )
			this.prev.removeSelf ();
	}
	
	/**
	 * Generalized swap routine that swaps positions of two elements in a list.
	 * Note that elements not necessarily belongs to the same list.
	 */
	public static inline function swap ( a:ActiveEdge, b:ActiveEdge ):Void {
		// Assume that commented out conditions also evaluates to true i.e. list is not broken
		if ( a.next == b /*&& b.prev == a*/ )
			swapAdjacent ( a, b );
		else if ( b.next == a /*&& a.prev == b*/ )
			swapAdjacent ( b, a );
		else
			swapNonAdjacent ( a, b );
	}
	
	/**
	 * Swap nodes a and b given that b follows a in list.
	 * This procedure performs faster than swapNonAdjacent () and generalized swap ().
	 * @param	a	A node which next property points to node b.
	 * @param	b	A node which prev property points to node a.
	 */
	public static inline function swapAdjacent ( a:ActiveEdge, b:ActiveEdge ):Void {
		if ( a.prev != null )
			a.prev.next = b;
		
		if ( b.next != null )
			b.next.prev = a;
		
		b.prev = a.prev;
		a.next = b.next;
		b.next = a;
		a.prev = b;
	}
	
	/**
	 * Swap nodes a and b given that there are some other nodes between them.
	 * @param	a	First node.
	 * @param	b	Second node.
	 */
	public static inline function swapNonAdjacent ( a:ActiveEdge, b:ActiveEdge ):Void {
		if ( a.prev != null )
			a.prev.next = b;
		
		if ( a.next != null )
			a.next.prev = b;
		
		if ( b.prev != null )
			b.prev.next = a;
		
		if ( b.next != null )
			b.next.prev = a;
		
		var tmp = a.next;
		a.next = b.next;
		b.next = tmp;
		
		tmp = a.prev;
		a.prev = b.prev;
		b.prev = tmp;
	}
	
	/**
	 * Checks whether any of the given nodes immediately followed by other in list.
	 * @param	a	First node.
	 * @param	b	Second node.
	 * @return	Boolean indicating adjacency.
	 */
	public static inline function areAdjacent ( a:ActiveEdge, b:ActiveEdge ):Bool {
		return	( a.next == b && b.prev == a ) || ( b.next == a && a.prev == b );
	}
}