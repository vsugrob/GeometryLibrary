package geom;

/**
 * Serves as a wrapper around any other iterator.
 * Yields min ( count, it.numberOfElements ) elements.
 * Call to next () after hasNext () has been reported false may have unpredictable behavior.
 * @author vsugrob
 */
class TakeIterator <TElement> {
	private var it:Iterator <TElement>;
	private var i:UInt;
	private var count:UInt;
	private var endElementReached:Bool;
	
	public function new ( it:Iterator <TElement>, count:UInt ) {
		this.it = it;
		this.i = 0;
		this.count = count;
	}
	
	public inline function next ():TElement {
		i++;
		
		return	it.next ();
	}
	
	public inline function hasNext ():Bool {
		return	i < count && it.hasNext ();
	}
}