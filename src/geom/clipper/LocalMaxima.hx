package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

class LocalMaxima {
	/**
	 * edge1 is the first edge of boundary non-decreasing by Y-axis.
	 */
	public var edge1:Edge;
	/**
	 * edge1 is the first edge of boundary non-increasing by Y-axis.
	 */
	public var edge2:Edge;
	/**
	 * Local maximas sorted descending by y-coordinate.
	 */
	public var y:Float;
	/**
	 * Does edge1 and edge2 belong to clip or subject polygon?
	 */
	public var kind:PolyKind;
	/**
	 * Pointer to a next local maxima which y is not greater than y of the current node.
	 */
	public var next:LocalMaxima;
	
	public function new ( edge1:Edge, edge2:Edge, y:Float, kind:PolyKind ) {
		this.edge1 = edge1;
		this.edge2 = edge2;
		this.y = y;
		this.kind = kind;
	}
	
	public inline function insert ( newLm:LocalMaxima ):Void {
		var curLm:LocalMaxima = this;
		var prevLm:LocalMaxima = null;
		
		do {
			if ( newLm.y >= curLm.y ) {
				if ( prevLm != null )
					prevLm.next = newLm;
				
				newLm.next = curLm;
				
				break;
			}
			
			prevLm = curLm;
			curLm = curLm.next;
		} while ( curLm != null );
		
		if ( curLm == null )
			prevLm.next = newLm;
	}
}