package geom.clipper.output;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.clipper.ActiveEdge;
import geom.clipper.ClipOutputSettings;
import geom.clipper.Edge;
import geom.clipper.LocalMaxima;
import geom.clipper.Side;
import geom.DoublyListNode;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputBounds implements IClipOutputReceiver {
	public var spawnIndex:Int;
	private var leftEdge:Edge;
	private var prevLeftEdge:Edge;
	private var rightEdge:Edge;
	private var prevRightEdge:Edge;
	private var sharedData:OutputSharedData;
	private var outputSettings:ClipOutputSettings;
	
	public inline function new ( spawnIndex:Int, sharedData:OutputSharedData, outputSettings:ClipOutputSettings ) {
		this.spawnIndex = spawnIndex;
		this.sharedData = sharedData;
		this.outputSettings = outputSettings;
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		var newEdge = addPointToEdge ( p, leftEdge );
		
		if ( newEdge != null ) {
			prevLeftEdge = leftEdge;
			leftEdge = newEdge;
		}
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		var newEdge = addPointToEdge ( p, rightEdge );
		
		if ( newEdge != null ) {
			prevRightEdge = rightEdge;
			rightEdge = newEdge;
		}
	}
	
	private static inline function addPointToEdge ( p:Point, edge:Edge ):Edge {
		var dx:Float = p.x - edge.bottomX;
		var dy:Float = p.y - edge.topY;
		var k:Float = 0;
		var zeroLengthEdge:Bool = false;
		
		if ( dy != 0 ) {
			k = dx / dy;
			
			if ( !Math.isFinite ( k ) ) {	// Then edge is indistinguishable from horizontal
				dy = 0;
				
				// edge.topY (corresponding to edge start Y) and p.y slightly differs, fix it.
				p = new Point ( p.x, edge.topY );
			}
		} else if ( dx == 0 /*&& dy == 0*/ ) {
			zeroLengthEdge = true;
		}
		
		var successor:Edge = null;
		
		if ( !zeroLengthEdge ) {	// Otherwise skip zero-length edge
			if ( dy == 0 ) {
				edge.dx = dx;
				edge.isHorizontal = true;
			} else {
				edge.dx = k;
				edge.topY = p.y;
			}
			
			successor = new Edge ( p.x, p.y );
			edge.successor = successor;
		}
		
		return	successor;
	}
	
	// TODO: handle 1-point and other degenerate cases!
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		var boundsOut1 = aelNode1.output.boundsOut;
		var boundsOut2 = aelNode2.output.boundsOut;
		var lastLeftEdge:Edge, lastRightEdge:Edge;
		
		if ( aelNode1.side == Side.Left ) {
			boundsOut1.addPointToLeftBound ( p, null );
			boundsOut2.addPointToRightBound ( p, null );
			lastLeftEdge = boundsOut1.prevLeftEdge;
			lastRightEdge = boundsOut2.prevRightEdge;
		} else {
			boundsOut1.addPointToRightBound ( p, null );
			boundsOut2.addPointToLeftBound ( p, null );
			lastRightEdge = boundsOut1.prevRightEdge;
			lastLeftEdge = boundsOut2.prevLeftEdge;
		}
		
		// Left edge is increasing no matter whether this local minima is convergence point for a hole or for an outer contour
		outputSettings.polyBoundsReceiver.addLocalMinima ( lastLeftEdge, lastRightEdge, p.x, p.y );
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		leftEdge = new Edge ( p.x, p.y );
		rightEdge = new Edge ( p.x, p.y );
		prevLeftEdge = leftEdge;
		prevRightEdge = rightEdge;
		
		// Left edge is increasing no matter whether this local maxima is starting point for a hole or for an outer contour
		outputSettings.polyBoundsReceiver.addLocalMaxima ( leftEdge, rightEdge, p.y, outputSettings.boundsKind );
	}
	
	public inline function merge ( other:ClipOutputBounds, aelNode1:ActiveEdge, aelNode2:ActiveEdge ):Void {
		if ( aelNode1.side == Side.Right ) {
			this.rightEdge = other.rightEdge;
			this.prevRightEdge = other.prevRightEdge;
		} else {
			this.leftEdge = other.leftEdge;
			this.prevLeftEdge = other.prevLeftEdge;
		}
	}
	
	public inline function flush ():Void {}
}