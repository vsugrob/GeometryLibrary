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

class ClipOutputTriangles implements ClipOutputReceiver, extends DoublyList <ClipOutputTriangles> {
	public var spawnIndex:Int;
	public var points:ChainedPolygon;
	private var parity:Int;
	/**
	 * Number of points since end of the last primitive.
	 */
	private var count:Int;
	
	public inline function new ( spawnIndex:Int ) {
		super ( this );
		this.spawnIndex = spawnIndex;
		this.parity = 0;
		this.count = 0;
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		points.appendPoint ( p );
		parity--;
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		points.appendPoint ( p );
		parity++;
	}
	
	//private inline function addPoint ( p:Point, 
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		if ( aelNode1.side == Side.Left )
			addPointToLeftBound ( p, aelNode1 );
		else
			addPointToRightBound ( p, aelNode1 );
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		var leftOut:ClipOutputTriangles;
		var isHole:Bool;
		
		if ( closestContribNode == null ) {
			leftOut = null;
			isHole = false;
		} else if ( closestContribNode.side == Side.Right ) {
			leftOut = closestContribNode.output.triOut;
			isHole = false;
		} else {
			leftOut = closestContribNode.output.triOut;
			isHole = true;
		}
		
		// Insert this output into output list
		if ( leftOut != null ) {
			this.next = leftOut.next;
			this.prev = leftOut;
			
			if ( leftOut.next != null )
				leftOut.next.prev = this;
			
			leftOut.next = this;
		}
		
		if ( isHole ) {
			// break leftOut to 2 columns
		} else {
			var pNode:DoublyList <Point> = new DoublyList <Point> ( p );
			points = new ChainedPolygon ( pNode, pNode );
			count = 1;
		}
	}
	
	public inline function merge ( poly:ClipOutputTriangles, append:Bool ):Void {
		/*if ( append )
			points.append ( poly.points );
		else
			points.prepend ( poly.points );
		
		if ( this.spawnIndex > poly.spawnIndex ) {
			this.isHole = poly.isHole;
			this.parent = poly.parent;
		}*/
	}
}