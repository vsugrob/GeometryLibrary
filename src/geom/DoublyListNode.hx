package geom;

/**
 * ...
 * @author vsugrob
 */

class DoublyListNode <TElement> {
	public var value:TElement;
	public var prev:DoublyListNode <TElement>;
	public var next:DoublyListNode <TElement>;
	
	public function new ( value:TElement, prev:DoublyListNode <TElement> = null, next:DoublyListNode <TElement> = null ) {
		this.value = value;
		this.prev = prev;
		this.next = next;
	}
	
	public static function fromIterable <TElement> ( it:Iterator <TElement>, close:Bool = true ):DoublyListNode <TElement> {
		if ( !it.hasNext () )
			return	null;
		
		var dl0 = new DoublyListNode <TElement> ( it.next () );
		var dl1:DoublyListNode <TElement>;
		var dlStart = dl0;
		
		for ( element in it ) {
			dl1 = new DoublyListNode <TElement> ( element, dl0 );
			dl0.next = dl1;
			dl0 = dl1;
		}
		
		if ( close ) {
			dl1.next = dlStart;
			dlStart.prev = dl1;
		}
		
		return	dlStart;
	}
	
	/**
	 * @return	List of elements starting at the current element and ending at the last in chain or just before the
	 * 	current in case of circular chain.
	 * @warning	This method may cause infinite looping if:
	 *	1) pair of intermediate chain nodes points to each other
	 * 	2) iteration process starts with a node which points to some circular chain but not belongs to it.
	 */
	public function toList ():List <TElement> {
		var list = new List <TElement> ();
		
		for ( element in this.iterator () )
			list.add ( element );
		
		return	list;
	}
	
	/**
	 * @return	Forward iterator starting at the current element and ending at the last in chain or just before the
	 * 	current in case of circular chain.
	 * @warning	Iterating may cause infinite looping if:
	 *	1) pair of intermediate chain nodes points to each other
	 * 	2) iteration process starts with a node which points to some circular chain but not belongs to it.
	 */
	public function iterator ():Iterator <TElement> {
		return	new DoublyListIterator <TElement> ( this );
	}
	
	/**
	 * @return	Backward iterator starting at the current element and ending at the first in chain or just after the
	 * 	current in case of circular chain.
	 * @warning	Iterating may cause infinite looping if:
	 *	1) pair of intermediate chain nodes points to each other
	 * 	2) iteration process starts with a node which points to some circular chain but not belongs to it.
	 */
	public function reverse ():Iterator <TElement> {
		return	new DoublyListIterator <TElement> ( this, true );
	}
	
	public inline function insertNext ( element:TElement ):Void {
		var dl = new DoublyListNode <TElement> ( element, this, this.next );
		
		if ( this.next != null )
			this.next.prev = dl;
		
		this.next = dl;
	}
	
	public inline function insertPrev ( element:TElement ):Void {
		var dl = new DoublyListNode <TElement> ( element, this.prev, this );
		
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
	 * @return	First node which has its prev pointer set to null or itself in case of circular chain.
	 * 	It returns itself also in the case when this node is single node in chain.
	 * @warning	This method may cause infinite looping if:
	 *	1) pair of intermediate chain nodes points to each other
	 * 	2) iteration process starts with a node which points to some circular chain but not belongs to it.
	 */
	public inline function first ():DoublyListNode <TElement> {
		var cur = this;
		
		while ( cur.prev != null ) {
			cur = cur.prev;
			
			if ( cur == this ) {
				// This is a curcular chain
				
				return	this;
			}
		}
		
		return	cur;
	}
	
	/**
	 * @return	Last node which has its next pointer set to null or previous to itself in case of circular chain
	 * 	or itself if this node is single node in chain.
	 * @warning	This method may cause infinite looping if:
	 *	1) pair of intermediate chain nodes points to each other
	 * 	2) iteration process starts with a node which points to some circular chain but not belongs to it.
	 */
	public inline function last ():DoublyListNode <TElement> {
		var cur = this;
		
		while ( cur.next != null ) {
			cur = cur.next;
			
			if ( cur == this ) {
				// This is a curcular chain
				
				return	this.prev;
			}
		}
		
		return	cur;
	}
	
	/**
	 * Generalized swap routine that swaps positions of two elements in a list.
	 * Note that elements not necessarily belongs to the same list.
	 */
	public static inline function swap <TElement> ( a:DoublyListNode <TElement>, b:DoublyListNode <TElement> ):Void {
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
	public static inline function swapAdjacent <TElement> ( a:DoublyListNode <TElement>, b:DoublyListNode <TElement> ):Void {
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
	public static inline function swapNonAdjacent <TElement> ( a:DoublyListNode <TElement>, b:DoublyListNode <TElement> ):Void {
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
	public static inline function areAdjacent <TElement> ( a:DoublyListNode <TElement>, b:DoublyListNode <TElement> ):Bool {
		return	( a.next == b && b.prev == a ) || ( b.next == a && a.prev == b );
	}
	
	public function toString ():String {
		var dValue:Dynamic = value;
		var str = "{element: " + dValue.toString () + ", ";
		
		if ( next == null && prev == null )
			str += "single";
		else if ( next == null && prev != null )
			str += "last";
		else if ( next != null && prev == null )
			str += "first";
		else
			str += "intermediate";
		
		str += " element}";
		
		return	str;
	}
}