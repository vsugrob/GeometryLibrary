package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

/**
 * Singly-linked list of the scanlines which encloses scanbeams. List is maintained
 * sorted descending by y-coordinate. Note that y-coordinates are distinct i.e. there
 * will be no scanbeams with equal ys.
 */
class Scanbeam {
	/**
	 * Vertical coordinate of the horizontal scanline which can be bottom or top
	 * of the scanbeam.
	 */
	public var y:Float;
	/**
	 * Pointer to the next scanbeam which y-coordinate less than y of this scanbeam.
	 */
	public var next:Scanbeam;
	
	public function new ( y:Float ) {
		this.y = y;
	}
	
	public inline function insert ( newSb:Scanbeam ):Void {
		var curSb:Scanbeam = this;
		var prevSb:Scanbeam = null;
		
		do {
			if ( newSb.y == curSb.y )
				break;
			else if ( newSb.y > curSb.y ) {
				if ( prevSb != null )
					prevSb.next = newSb;
				
				newSb.next = curSb;
				
				break;
			}
			
			prevSb = curSb;
			curSb = curSb.next;
		} while ( curSb != null );
		
		if ( curSb == null )
			prevSb.next = newSb;
	}
}