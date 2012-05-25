package geom;

/**
 * ...
 * @author vsugrob
 */

class ClosedPolygonIterator <TElement> {
	private var it:Iterator <TElement>;
	private var firstElement:TElement;
	private var closeMe:Bool;
	private var closed:Bool;
	
	public function new ( it:Iterator <TElement> ) {
		this.it = it;
		this.closed = !it.hasNext ();	// If iterator has no elements then empty sequence will be yielded.
		this.closeMe = false;
	}
	
	public function next ():TElement {
		if ( closeMe ) {
			closed = true;
			
			return	firstElement;
		} else {
			var elt = it.next ();
			
			if ( firstElement == null )
				firstElement = elt;
			
			return	elt;
		}
	}
	
	public function hasNext ():Bool {
		if ( it.hasNext () )
			return	true;
		else {
			if ( !closed ) {
				closeMe = true;
				
				return	true;
			} else
				return	false;
		}
	}
}