package geom.clipper.output;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.clipper.ActiveEdge;
import geom.clipper.Side;
import geom.DoublyList;
import geom.DoublyListNode;

/**
 * ...
 * @author vsugrob
 */

class ClipOutputTriangles implements IClipOutputReceiver {
	public var spawnIndex:Int;
	public var parentOutput:ClipOutput;
	public var primities:DoublyList <Primitive>;
	private var points:ChainedPolygon;
	private var realRightOut:ClipOutputTriangles;
	private var rightContributor:ClipOutputTriangles;
	private var lastLeftEdge:BottomUpEdge;
	private var lastRightEdge:BottomUpEdge;
	private var lastPointWasRight:Null <Bool>;
	private var lastRightPoint:Point;
	/**
	 * Number of points added since end of the last primitive.
	 */
	private var count:Int;
	private var inStrip:Bool;
	/**
	 * Previous left dx (inverted slope)
	 */
	private var pldx:Float;
	/**
	 * Previous right dx (inverted slope)
	 */
	private var prdx:Float;
	private var fanLastPoint:Point;
	
	public inline function new ( spawnIndex:Int, parentOutput:ClipOutput ) {
		this.spawnIndex = spawnIndex;
		this.parentOutput = parentOutput;
		this.inStrip = true;
		this.primities = new DoublyList <Primitive> ();
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		lastLeftEdge.setFromActiveEdge ( aelNode );
		addPointToLeftBoundInternal ( p, lastLeftEdge );
	}
	
	public inline function addPointToLeftBoundInternal ( p:Point, edge:BottomUpEdge ):Void {
		addPoint ( p, lastRightEdge, edge.dx, pldx, lastPointWasRight == false, false );
		pldx = edge.dx;
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( realRightOut != null ) {
			realRightOut.lastRightEdge.setFromActiveEdge ( aelNode );
			realRightOut.addPointToRightBoundReal ( p, realRightOut.lastRightEdge );
		} else {
			lastRightEdge.setFromActiveEdge ( aelNode );
			addPointToRightBoundReal ( p, lastRightEdge );
		}
	}
	
	private inline function addPointToRightBoundInternal ( p:Point, edge:BottomUpEdge ):Void {
		if ( realRightOut != null ) {
			realRightOut.lastRightEdge.setFromBottomUpEdge ( edge );
			realRightOut.addPointToRightBoundReal ( p, realRightOut.lastRightEdge );
		} else {
			lastRightEdge.setFromBottomUpEdge ( edge );
			addPointToRightBoundReal ( p, edge );
		}
	}
	
	private inline function addPointToRightBoundReal ( p:Point, edge:BottomUpEdge ):Void {
		addPoint ( p, lastLeftEdge, edge.dx, prdx, lastPointWasRight == true, true );
		prdx = edge.dx;
	}
	
	// TODO: zero-height triangles cannot be drawn so there is no need to emit them.
	// This fact also saves us from necessity of horizontal edge topX calculation.
	private inline function addPoint ( p:Point, oppositeEdge:BottomUpEdge, dx:Float, pdx:Float,
		newPointOnSameSide:Bool, newPointIsRight:Bool ):Void
	{
		if ( inStrip ) {
			if ( lastPointWasRight != null && newPointOnSameSide ) {
				if ( isConvex ( dx, pdx, lastPointWasRight ) ) {
					/* If count == 2 then we're about to add third point
					 * and it will be more suitable to convert strip to fan.
					 * If not, then flush strip before starting new fan.*/
					if ( count != 2 )
						primities.insertLast ( new Primitive ( points, PrimitiveType.TriangleStrip ) );
					
					fanLastPoint = points.last.prev.value;
					points = ChainedPolygon.create ( points.last.value );
					points.appendPoint ( p );
					count = 2;
					
					inStrip = false;
					
					if ( lastPointWasRight )
						lastRightPoint = points.last.value;
				} else {
					var op = new Point ( oppositeEdge.topX ( p.y ), p.y );
					points.appendPoint ( op );
					points.appendPoint ( p );
					count += 2;
					
					if ( lastPointWasRight )
						lastRightPoint = points.last.value;
					else
						lastRightPoint = points.last.prev.value;
				}
			} else {
				points.appendPoint ( p );
				count++;
				
				lastPointWasRight = newPointIsRight;
				
				if ( lastPointWasRight )
					lastRightPoint = points.last.value;
			}
		} else {	// In fan
			var newApex:Point = null;
			var newFirstPoint:Point = null;
			
			if ( newPointOnSameSide ) {
				if ( isConvex ( dx, pdx, lastPointWasRight ) ) {
					points.appendPoint ( p );
					count++;
				} else {
					var op = new Point ( oppositeEdge.topX ( p.y ), p.y );
					points.appendPoint ( p );
					points.appendPoint ( op );
					newApex = p;
					newFirstPoint = op;
					lastPointWasRight = !newPointIsRight;	// First point is on opposite side
					if ( fanLastPoint == null )
						throw "fanLastPoint is null";
					points.appendPoint ( fanLastPoint );
					count += 3;
				}
			} else {
				newApex = points.last.value;
				newFirstPoint = p;
				points.appendPoint ( p );
				lastPointWasRight = newPointIsRight;
				if ( fanLastPoint == null )
					throw "fanLastPoint is null";
				points.appendPoint ( fanLastPoint );
				count += 2;
			}
			
			if ( newApex != null ) {
				// Flush fan
				primities.insertLast ( new Primitive ( points, PrimitiveType.TriangleFan ) );
				
				// Start new strip
				points = ChainedPolygon.create ( newApex );
				points.appendPoint ( newFirstPoint );
				count = 2;
				fanLastPoint = null;
				inStrip = true;
				
				// We've added 2 points to different sides
				if ( lastPointWasRight )
					lastRightPoint = points.last.value;
				else
					lastRightPoint = points.last.prev.value;
			} else {
				if ( lastPointWasRight )
					lastRightPoint = points.last.value;
			}
		}
	}
	
	private inline function isConvex ( dx:Float, pdx:Float, rightSide:Bool ):Bool {
		var res:Bool;
		
		if ( rightSide )
			res = dx >= pdx;
		else
			res = dx <= pdx;
		
		return	res;
	}
	
	private inline function emitLastPrimitive ():Void {
		if ( inStrip ) {
			if ( count > 2 )
				primities.insertLast ( new Primitive ( points, PrimitiveType.TriangleStrip ) );
		} else {
			if ( fanLastPoint == null )
				throw "fanLastPoint is null";
			points.appendPoint ( fanLastPoint );
			count++;
			fanLastPoint = null;
			
			primities.insertLast ( new Primitive ( points, PrimitiveType.TriangleFan ) );
		}
	}
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		// Flush primitives
		if ( aelNode1.side == Side.Left ) {
			/* If lastPointWasRight is null then we got 2-pointed polygon
			 * and there is no need to emit any primitive since it will
			 * have zero area. */
			if ( lastPointWasRight != null ) {
				addPointToLeftBound ( p, aelNode1 );
				emitLastPrimitive ();
			}
		} else {
			var otherOut = aelNode2.output.triOut;
			otherOut.addPointToLeftBound ( p, aelNode2 );
			
			var op = new Point ( otherOut.lastRightEdge.topX ( p.y ), p.y );
			otherOut.addPointToRightBoundReal ( op, otherOut.lastRightEdge );
			otherOut.emitLastPrimitive ();
			
			var realRightEdge:BottomUpEdge;
			
			if ( realRightOut != null && aelNode1.output == aelNode2.output ) {	// Is a hole
				realRightOut.lastRightEdge.setFromPoints ( p, op );
				realRightEdge = realRightOut.lastRightEdge;
			} else
				realRightEdge = BottomUpEdge.newFromPoints ( p, op );
			
			addPointToRightBoundInternal ( p, realRightEdge );
			
			if ( realRightOut != null ) {
				realRightOut.lastRightEdge.setFromBottomUpEdge ( otherOut.lastRightEdge );
				realRightEdge = realRightOut.lastRightEdge;
			} else {
				lastRightEdge.setFromBottomUpEdge ( otherOut.lastRightEdge );
				realRightEdge = lastRightEdge;
			}
			
			addPointToRightBoundInternal ( op, realRightEdge );
			
			//op = new Point ( lastLeftEdge.topX ( p.y ), p.y );
			//addPointToLeftBoundInternal ( op, lastLeftEdge );
		}
		
		// Do merge stage for holes here (they have same outputs, so merge () won't be called for them)
		if ( aelNode1.side == Side.Right && aelNode1.output == aelNode2.output ) {
			if ( realRightOut.realRightOut == this ) {	// Then this is the last local minima in outer poly
				realRightOut.realRightOut = null;
				realRightOut.rightContributor = null;
			} else {
				rightContributor.realRightOut = realRightOut;
				realRightOut.rightContributor = rightContributor;
			}
		}
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
		
		if ( isHole ) {
			// Break leftOut into 2 columns
			lastRightEdge = new BottomUpEdge ( leftOut.lastRightEdge.bottomX, leftOut.lastRightEdge.bottomY, leftOut.lastRightEdge.dx );
			
			var op = new Point ( leftOut.lastRightEdge.topX ( p.y ), p.y );
			leftOut.lastRightEdge.setFromPoints ( op, p );
			leftOut.addPointToRightBoundReal ( op, leftOut.lastRightEdge );
			
			var pNode:DoublyListNode <Point> = new DoublyListNode <Point> ( leftOut.lastRightPoint );
			points = new ChainedPolygon ( pNode, pNode );
			count = 1;
			lastLeftEdge = BottomUpEdge.newFromPoints ( leftOut.lastRightPoint, p );
			lastRightPoint = leftOut.lastRightPoint;
			pldx = lastLeftEdge.dx;	// TODO: Beware of the NaN
			prdx = lastRightEdge.dx;
			leftOut.prdx = pldx;
			leftOut.lastRightEdge.setFromBottomUpEdge ( lastLeftEdge );
			
			if ( leftOut.rightContributor != null ) {
				leftOut.rightContributor.realRightOut = this;
				this.rightContributor = leftOut.rightContributor;
			} else {
				leftOut.realRightOut = this;
				this.rightContributor = leftOut;
			}
			
			this.realRightOut = leftOut;
			leftOut.rightContributor = this;
			
			addPointToLeftBound ( p, aelNode2 );
			addPointToRightBound ( p, aelNode1 );
		} else {
			var pNode:DoublyListNode <Point> = new DoublyListNode <Point> ( p );
			points = new ChainedPolygon ( pNode, pNode );
			count = 1;
			lastLeftEdge = BottomUpEdge.newFromActiveEdge ( aelNode1 );
			lastRightEdge = BottomUpEdge.newFromActiveEdge ( aelNode2 );
			lastRightPoint = p;
			pldx = lastLeftEdge.dx;
			prdx = lastRightEdge.dx;
		}
	}
	
	public inline function merge ( triOut:ClipOutputTriangles, aelNode1:ActiveEdge, aelNode2:ActiveEdge ):Void {
		var out1 = aelNode1.output.triOut;
		var out2 = aelNode2.output.triOut;
		
		if ( aelNode1.side == Side.Left ) {	// Then e2 node's side is right
			out2.primities.prepend ( out1.primities );
			
			if ( out1.realRightOut != out2 ) {
				out2.realRightOut = out1.realRightOut;
				out2.realRightOut.rightContributor = out2;
			} else {
				out2.realRightOut = null;
				out2.rightContributor = null;
			}
			
			aelNode1.output.triOut = out2;
		} else {
			out1.primities.prepend ( out2.primities );
			
			if ( out2.rightContributor != null ) {
				if ( out1.realRightOut != null ) {
					out1.realRightOut.rightContributor = out2.rightContributor;
					out2.rightContributor.realRightOut = out1.realRightOut;
				} else {
					out1.rightContributor = out2.rightContributor;
					out2.rightContributor.realRightOut = out1;
				}
			}
			
			if ( out2.realRightOut != null ) {
				out1.realRightOut = out2.realRightOut;
				out1.realRightOut.rightContributor = out1;
			}
		}
	}
}