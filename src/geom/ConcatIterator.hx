package geom;

/**
 * Yields elements of two iterators succesively
 * as if they were a single entity.
 * @author vsugrob
 */
class ConcatIterator <TElement> {
	private var it1:Iterator <TElement>;
	private var it2:Iterator <TElement>;
	private var it:Iterator <TElement>;
	
	public function new ( it1:Iterator <TElement>, it2:Iterator <TElement> ) {
		this.it1 = it1;
		this.it2 = it2;
		this.it = it1;
	}
	
	public inline function next ():TElement {
		return	it.next ();
	}
	
	public inline function hasNext ():Bool {
		if ( it.hasNext () )
			return	true;
		else {
			if ( it == it1 ) {
				it = it2;
				
				return	it.hasNext ();
			} else
				return	false;
		}
	}
}