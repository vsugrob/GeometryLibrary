package geom.clipper.output;
import flash.geom.Point;
import geom.clipper.ActiveEdge;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputMonotone implements IClipOutputReceiver {
	public var spawnIndex:Int;
	public var leftBound:OutputBound;
	public var rightBound:OutputBound;
	
	public inline function new ( spawnIndex:Int ) {
		this.spawnIndex = spawnIndex;
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		leftBound.addLeftPointOnActiveEdge ( p, aelNode );
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		rightBound.addRightPointOnActiveEdge ( p, aelNode );
	}
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		
	}
	
	public inline function merge ( triOut:ClipOutputMonotone, aelNode1:ActiveEdge, aelNode2:ActiveEdge ):Void {
		
	}
}