package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

class LocalMaxima {
	public var edge1:Edge;
	public var edge2:Edge;
	/**
	 * Local maximas sorted descending by y-coordinate.
	 */
	public var y:Float;
	/**
	 * Pointer to a next local maxima which y is not greater than y of the current node.
	 */
	public var next:LocalMaxima;
	
	public function new ( edge1:Edge, edge2:Edge, y:Float ) {
		this.edge1 = edge1;
		this.edge2 = edge2;
		this.y = y;
	}
	
	public inline function insert ( newLm:LocalMaxima ):Void {
		var curLm:LocalMaxima = this;
		var prevLm:LocalMaxima = null;
		
		do {
			if ( newLm.y >= curLm.y ) {
				if ( prevLm != null )
					prevLm.next = newLm;
				
				newLm.next = curLm;
				
				return;
			}
			
			prevLm = curLm;
			curLm = curLm.next;
		} while ( curLm != null );
		
		prevLm.next = newLm;
	}
}