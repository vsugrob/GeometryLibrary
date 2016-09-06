package geom.clipper.output.monotone;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.clipper.ClipOutputSettings;
import geom.clipper.output.Primitive;
import geom.clipper.output.PrimitiveType;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class MonotoneTrianglesColumn {
	public var primities:DoublyList <Primitive>;
	private var points:ChainedPolygon;
	/**
	 * Number of points added since end of the last primitive.
	 */
	private var count:Int;
	private var inStrip:Bool;
	private var fanLastPoint:Point;
	private var lastPointWasRight:Null <Bool>;
	
	private var monoColumn:MonotoneColumn;
	private var leftBound (get_leftBound, null):OutputBound;
	private inline function get_leftBound ():OutputBound {
		return	monoColumn.leftBound;
	}
	
	private var rightBound (get_rightBound, null):OutputBound;
	private inline function get_rightBound ():OutputBound {
		return	monoColumn.rightBound;
	}
	
	public inline function new ( p:Point, monoColumn:MonotoneColumn ) {
		this.monoColumn = monoColumn;
		this.inStrip = true;
		this.primities = new DoublyList <Primitive> ();
		this.points = ChainedPolygon.create ( p );
		this.count = 1;
	}
	
	public inline function addLeft ( p:Point ):Void {
		addPoint ( p, leftBound, rightBound, false );
	}
	
	public inline function addRight ( p:Point ):Void {
		addPoint ( p, rightBound, leftBound, true );
	}
	
	private inline function addPoint ( p:Point, thisBound:OutputBound, oppositeBound:OutputBound, newPointIsRight:Bool ):Void {
		if ( inStrip ) {
			if ( lastPointWasRight == newPointIsRight ) {	// New point is on the same side as previous
				if ( thisBound.isConvex ( newPointIsRight ) ) {
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
				} else {
					var op = new Point ( oppositeBound.topX ( p.y ), p.y );
					points.appendPoint ( op );
					points.appendPoint ( p );
					count += 2;
				}
			} else {
				points.appendPoint ( p );
				count++;
				
				lastPointWasRight = newPointIsRight;
			}
		} else {	// In fan
			var newApex:Point = null;
			var newFirstPoint:Point = null;
			
			if ( lastPointWasRight == newPointIsRight ) {	// New point is on the same side as previous
				if ( thisBound.isConvex ( newPointIsRight ) ) {
					points.appendPoint ( p );
					count++;
				} else {
					var op = new Point ( oppositeBound.topX ( p.y ), p.y );
					points.appendPoint ( p );
					points.appendPoint ( op );
					newApex = p;
					newFirstPoint = op;
					lastPointWasRight = !newPointIsRight;	// First point is on opposite side
					
					points.appendPoint ( fanLastPoint );
					count += 3;
				}
			} else {
				newApex = points.last.value;
				newFirstPoint = p;
				points.appendPoint ( p );
				lastPointWasRight = newPointIsRight;
				
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
			}
		}
	}
	
	public inline function merge ( other:MonotoneTrianglesColumn ):Void {
		primities.prepend ( other.primities );
	}
	
	public inline function flush ():Void {
		if ( inStrip ) {
			if ( count > 2 ) {
				primities.insertLast ( new Primitive ( points, PrimitiveType.TriangleStrip ) );
				count = 0;
			}
		} else {
			points.appendPoint ( fanLastPoint );
			count++;
			primities.insertLast ( new Primitive ( points, PrimitiveType.TriangleFan ) );
			
			fanLastPoint = null;
			inStrip = true;
			count = 0;
		}
	}
}