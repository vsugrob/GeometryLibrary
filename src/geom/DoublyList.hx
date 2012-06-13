package geom;

/**
 * ...
 * @author vsugrob
 */

class DoublyList <TElement> {
	public var first:DoublyListNode <TElement>;
	public var last:DoublyListNode <TElement>;
	public var isEmpty (getIsEmpty, null):Bool;
	private inline function getIsEmpty ():Bool {
		return	first == null && last == null;
	}
	
	public function new () {}
	
	public inline function insertLast ( element:TElement ):Void {
		if ( last == null ) {
			first = last = new DoublyListNode <TElement> ( element );
		} else {
			last.insertNext ( element );
			last = last.next;
		}
	}
	
	public inline function insertFirst ( element:TElement ):Void {
		if ( first == null ) {
			first = last = new DoublyListNode <TElement> ( element );
		} else {
			first.insertPrev ( element );
			first = first.prev;
		}
	}
	
	public inline function prepend ( list:DoublyList <TElement> ):Void {
		if ( !list.isEmpty ) {
			if ( first == null ) {
				first = list.first;
				last = list.last;
			} else {
				first.prev = list.last;
				list.last.next = first;
				first = list.first;
			}
		}
	}
	
	public inline function append ( list:DoublyList <TElement> ):Void {
		if ( !list.isEmpty ) {
			if ( last == null ) {
				first = list.first;
				last = list.last;
			} else {
				last.next = list.first;
				list.first.prev = last;
				last = list.last;
			}
		}
	}
	
	public function iterator ():Iterator <TElement> {
		var it:Iterator <TElement>;
		
		if ( first == null ) {
			it = cast {
				hasNext : function () {
					return	false;
				},
				next : function () {
					return	null;
				}
			}
		} else
			it = first.iterator ();
		
		return	it;
	}
}