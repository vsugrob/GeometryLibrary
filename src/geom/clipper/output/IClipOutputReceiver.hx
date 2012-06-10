package geom.clipper.output;
import flash.geom.Point;
import geom.clipper.ActiveEdge;

/**
 * ...
 * @author vsugrob
 */

interface IClipOutputReceiver {
	public var spawnIndex:Int;
	public function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void;
	public function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void;
	public function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void;
	public function addLocalMax ( e1Node:ActiveEdge, e2Node:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void;
}