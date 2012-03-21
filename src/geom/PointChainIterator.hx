package geom;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class PointChainIterator {
	private var startPoint:PointChain;
	private var curPoint:PointChain;
	private var reverse:Bool;
	
	public function new ( startPoint:PointChain, reverse:Bool = false ) {
		this.startPoint = startPoint;
		this.curPoint = startPoint;
		this.reverse = reverse;
	}
	
	public function next ():Point {
		var p = curPoint.p;
		curPoint = reverse ? curPoint.prev : curPoint.next;
		
		if ( curPoint == startPoint )
			curPoint = null;
		
		return	p;
	}
	
	public function hasNext ():Bool {
		return	curPoint != null;
	}
}