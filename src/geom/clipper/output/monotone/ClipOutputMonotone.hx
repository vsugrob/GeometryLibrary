package geom.clipper.output.monotone;
import flash.geom.Point;
import geom.clipper.ActiveEdge;
import geom.clipper.ClipOutputSettings;
import geom.clipper.Side;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputMonotone implements IClipOutputReceiver {
	public var spawnIndex:Int;
	public var leftBound:OutputBound;
	public var rightBound:OutputBound;
	private var sharedData:OutputSharedData;
	private var outputSettings:ClipOutputSettings;
	
	public inline function new ( spawnIndex:Int, sharedData:OutputSharedData, outputSettings:ClipOutputSettings ) {
		this.spawnIndex = spawnIndex;
		this.sharedData = sharedData;
		this.outputSettings = outputSettings;
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		leftBound.addLeftPointOnActiveEdge ( p, aelNode );
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		rightBound.addRightPointOnActiveEdge ( p, aelNode );
	}
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		if ( aelNode1.side == Side.Right ) {	// Hole peak or notch on outer contour
			completeHole ( aelNode2.output.monoOut.leftBound, p );
		} else {	// Peak on (outer/hole) contour
			leftBound.addLeftPointOnActiveEdge ( p, aelNode1 );
			leftBound.column.flush ();
			
			removeBounds ( leftBound, leftBound.next, sharedData );
		}
	}
	
	private static inline function completeHole ( leftBound:OutputBound, p:Point ):Void {
		var rightBound = leftBound.prev;
		
		// Note that leftBound is after the rightBound in bound list
		var nextRightBound = leftBound.next;
		var nextRightEdge = BottomUpEdge.newFromBottomUpEdge ( nextRightBound.edge );
		var op = new Point ( nextRightBound.edge.topX ( p.y ), p.y );
		leftBound.addLeftPointOnHorizontal ( p, BottomUpEdge.RightHorizontal );
		nextRightBound.addRightPointOnHorizontal ( op, BottomUpEdge.LeftHorizontal );	// Here we change nextRightBound's edge
		leftBound.column.flush ();
		
		rightBound.addRightPointOnHorizontal ( p, BottomUpEdge.RightHorizontal );
		
		// Remove ended bounds from the bound list
		removeMiddleBounds ( rightBound, leftBound );
		
		nextRightBound.prevDx = BottomUpEdge.RightHorizontal;
		nextRightBound.addRightPointOnBottomUpEdge ( op, nextRightEdge );	// And here we restore nextRightBound's edge
	}
	
	/**
	 * Removes specified bounds from bound list. Given bounds must satisfy two conditions
	 * in order to be processed properly:
	 * 1. Bounds must be adjacent.
	 * 2. There must be other bound(s) before bound1 as well as after bound2.
	 * @param	bound1	First bound. Must precede bound2 in bound list.
	 * @param	bound2	Second bound.
	 */
	private static inline function removeMiddleBounds ( bound1:OutputBound, bound2:OutputBound ):Void {
		bound2.next.prev = bound1.prev;
		bound1.prev.next = bound2.next;
	}
	
	private static inline function removeBounds ( bound1:OutputBound, bound2:OutputBound, sharedData:OutputSharedData ):Void {
		if ( bound1.prev == null ) {
			sharedData.boundList = bound2.next;
			
			if ( sharedData.boundList != null )
				sharedData.boundList.prev = null;
		} else {
			bound1.prev.next = bound2.next;
			
			if ( bound2.next != null )
				bound2.next.prev = bound1.prev;
		}
	}
	
	public inline function merge ( other:ClipOutputMonotone, aelNode1:ActiveEdge, aelNode2:ActiveEdge ):Void {
		if ( aelNode1.side == Side.Right ) {
			this.leftBound.column.merge ( other.leftBound.column );
			this.rightBound = other.rightBound;
		} else {
			other.leftBound.column.merge ( this.leftBound.column );
			this.leftBound = other.leftBound;
		}
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		var leftOut:ClipOutputMonotone;
		var isHole:Bool;
		var closestBound:OutputBound;
		
		if ( closestContribNode == null ) {
			leftOut = null;
			closestBound = null;
			isHole = false;
		} else if ( closestContribNode.side == Side.Right ) {
			leftOut = closestContribNode.output.monoOut;
			closestBound = leftOut.rightBound;
			isHole = false;
		} else {
			leftOut = closestContribNode.output.monoOut;
			closestBound = leftOut.leftBound;
			isHole = true;
		}
		
		var bound1:OutputBound, bound2:OutputBound;
		var column:MonotoneColumn;
		
		if ( isHole ) {
			/* In case of a hole closestBound and closestBound.next won't contain null.
			 * Moreover, closestBound is left bound.*/
			var nextRightBound = closestBound.next;
			var op = new Point ( nextRightBound.edge.topX ( p.y ), p.y );
			bound1 = nextRightBound.clone ();
			bound2 = OutputBound.newHorizontal ( op, BottomUpEdge.LeftHorizontal );
			
			// Connect bounds P <-> B1 <-> B2 <-> N
			bound1.next = bound2;				// B1 -> B2
			bound2.prev = bound1;				// B1 <- B2
			bound1.prev = closestBound;			// P <- B1
			bound2.next = closestBound.next;	// B2 -> N
			closestBound.next.prev = bound2;	// B2 <- N
			closestBound.next = bound1;			// P -> B1
			
			column = new MonotoneColumn ( op, bound2, outputSettings );
			bound2.column = column;
			
			bound1.addRightPointOnHorizontal ( op, BottomUpEdge.LeftHorizontal );
			bound1.addRightPointOnActiveEdge ( p, aelNode1 );
			bound2.addLeftPointOnActiveEdge ( p, aelNode2 );
			
			leftBound = bound2;
			rightBound = bound1;
		} else {
			/* In this case closestBound (if not null) is right bound. Also it may have
			 * not null closestBound.next which is left bound of the next column.*/
			bound1 = OutputBound.newFromActiveEdge ( aelNode1 );
			bound2 = OutputBound.newFromActiveEdge ( aelNode2 );
			// Connect bounds B1 <-> B2
			bound1.next = bound2;
			bound2.prev = bound1;
			
			if ( closestBound != null ) {	// We have previous bound P
				// Connect bounds P <- B1 and B2 -> N
				bound1.prev = closestBound;				// P <- B1
				bound2.next = closestBound.next;		// B2 -> N
				
				if ( closestBound.next != null ) {
					// Next bound is not null. Again: next bound is left bound of the next column.
					closestBound.next.prev = bound2;	// B2 <- N
				}
				
				closestBound.next = bound1;				// P -> B1
			} else {	// No previous bound P
				if ( sharedData.boundList == null )		// No next bound N
					sharedData.boundList = bound1;
				else {	// We have next bound N
					// Connect bounds B2 <-> N
					bound2.next = sharedData.boundList;	// B2 -> N
					sharedData.boundList.prev = bound2;	// B2 <- N
					sharedData.boundList = bound1;
				}
			}
			
			column = new MonotoneColumn ( p, bound1, outputSettings );
			bound1.column = column;
			
			leftBound = bound1;
			rightBound = bound2;
		}
	}
	
	public inline function flush ():Void {
		leftBound.column.flush ();
	}
}