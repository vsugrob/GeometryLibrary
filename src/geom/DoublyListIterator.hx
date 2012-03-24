package geom;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class DoublyListIterator <TElement> {
	private var startPoint:DoublyList <TElement>;
	private var curPoint:DoublyList <TElement>;
	private var reverse:Bool;
	
	public function new ( startPoint:DoublyList <TElement>, reverse:Bool = false ) {
		this.startPoint = startPoint;
		this.curPoint = startPoint;
		this.reverse = reverse;
	}
	
	public function next ():TElement {
		var p = curPoint.value;
		curPoint = reverse ? curPoint.prev : curPoint.next;
		
		if ( curPoint == startPoint )
			curPoint = null;
		
		return	p;
	}
	
	public function hasNext ():Bool {
		return	curPoint != null;
	}
}