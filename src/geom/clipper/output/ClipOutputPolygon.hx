package geom.clipper.output;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.clipper.ActiveEdge;
import geom.clipper.Side;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputPolygon implements ClipOutputReceiver {
	public var spawnIndex:Int;
	public var points:ChainedPolygon;
	public var parent:ClipOutputPolygon;
	public var isHole:Bool;
	
	public inline function new ( spawnIndex:Int ) {
		this.spawnIndex = spawnIndex;
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		points.prependPoint ( p );
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		points.appendPoint ( p );
	}
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		if ( aelNode1.side == Side.Left )
			points.prependPoint ( p );
		else
			points.appendPoint ( p );
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		if ( closestContribNode == null ) {
			parent = null;
			isHole = false;
		} else if ( closestContribNode.side == Side.Right ) {
			parent = closestContribNode.output.polyOut;
			isHole = false;
		} else {
			parent = closestContribNode.output.polyOut;
			isHole = true;
		}
		
		var pNode:DoublyList <Point> = new DoublyList <Point> ( p );
		points = new ChainedPolygon ( pNode, pNode );
	}
	
	public inline function merge ( poly:ClipOutputPolygon, append:Bool ):Void {
		if ( append )
			points.append ( poly.points );
		else
			points.prepend ( poly.points );
		
		if ( this.spawnIndex > poly.spawnIndex ) {
			this.isHole = poly.isHole;
			this.parent = poly.parent;
		}
	}
	
	public inline function iterator ():Iterator <Point> {
		return	points.iterator ();
	}
}