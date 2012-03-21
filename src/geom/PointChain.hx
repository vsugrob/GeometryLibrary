package geom;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class PointChain {
	public var p:Point;
	public var prev:PointChain;
	public var next:PointChain;
	
	public function new ( p:Point, prev:PointChain = null, next:PointChain = null ) {
		this.p = p;
		this.prev = prev;
		this.next = next;
	}
	
	public static function fromIterable ( it:Iterator <Point> , close:Bool = true ):PointChain {
		if ( !it.hasNext () )
			return	null;
		
		var pc0 = new PointChain ( it.next () );
		var pc1:PointChain;
		var pcStart = pc0;
		
		for ( point in it ) {
			pc1 = new PointChain ( point, pc0 );
			pc0.next = pc1;
			pc0 = pc1;
		}
		
		if ( close ) {
			pc1.next = pcStart;
			pcStart.prev = pc1;
		}
		
		return	pcStart;
	}
	
	/**
	 * @return	Forward iterator starting at the current point and ending at the last in chain or just before the
	 * 	current in case of circular chain.
	 * @warning	Iterating may cause infinite looping if:
	 *	1) pair of intermediate chain nodes points at each other
	 * 	2) iteration process starts with a node which points to some circular chain but not belongs to it.
	 */
	public function iterator ():Iterator <Point> {
		return	new PointChainIterator ( this );
	}
	
	/**
	 * @return	Backward iterator starting at the current point and ending at the first in chain or just after the
	 * 	current in case of circular chain.
	 * @warning	Iterating may cause infinite looping if:
	 *	1) pair of intermediate chain nodes points at each other
	 * 	2) iteration process starts with a node which points to some circular chain but not belongs to it.
	 */
	public function reverse ():Iterator <Point> {
		return	new PointChainIterator ( this, true );
	}
	
	public inline function insertNext ( point:Point ):Void {
		var pc = new PointChain ( point, this, this.next );
		
		if ( this.next != null )
			this.next.prev = pc;
		
		this.next = pc;
	}
	
	public inline function insertPrev ( point:Point ):Void {
		var pc = new PointChain ( point, this.prev, this );
		
		if ( this.prev != null )
			this.prev.next = pc;
		
		this.prev = pc;
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
	
	public function toString ():String {
		var str = "{p: " + p.toString () + ", ";
		
		if ( next == null && prev == null )
			str += "single";
		else if ( next == null && prev != null )
			str += "last";
		else if ( next != null && prev == null )
			str += "first";
		else
			str += "intermediate";
		
		str += " point}";
		
		return	str;
	}
}