package geom.clipper.output;
import flash.geom.Point;
import geom.clipper.ActiveEdge;

/**
 * ...
 * @author vsugrob
 */

class BottomUpEdge {
	public var bottomX:Float;
	public var bottomY:Float;
	public var dx:Float;
	
	public inline function new ( bottomX:Float, bottomY:Float, dx:Float ) {
		this.bottomX = bottomX;
		this.bottomY = bottomY;
		this.dx = dx;
	}
	
	public static inline function newFromActiveEdge ( activeEdge:ActiveEdge ):BottomUpEdge {
		return	new BottomUpEdge ( activeEdge.edge.bottomX, activeEdge.bottomY,
			activeEdge.edge.isHorizontal ? ( activeEdge.edge.dx > 0 ? Math.NEGATIVE_INFINITY : Math.POSITIVE_INFINITY ) : activeEdge.edge.dx
		);
	}
	
	public inline function setFromActiveEdge ( activeEdge:ActiveEdge ):Void {
		this.bottomX = activeEdge.edge.bottomX;
		this.bottomY = activeEdge.bottomY;
		this.dx = activeEdge.edge.isHorizontal ? ( activeEdge.edge.dx > 0 ? Math.NEGATIVE_INFINITY : Math.POSITIVE_INFINITY ) : activeEdge.edge.dx;
	}
	
	public static inline function newFromPoints ( p0:Point, p1:Point ):BottomUpEdge {
		var dx = ( p1.x - p0.x ) / ( p1.y - p0.y );
		
		if ( !Math.isFinite ( dx ) )
			dx = -dx;
		
		return	new BottomUpEdge ( p0.x, p0.y, dx );
	}
	
	public inline function setFromPoints ( p0:Point, p1:Point ):Void {
		this.bottomX = p0.x;
		this.bottomY = p0.y;
		this.dx = ( p1.x - p0.x ) / ( p1.y - p0.y );
		
		if ( !Math.isFinite ( this.dx ) )
			this.dx = -this.dx;
	}
	
	public inline function setFromBottomUpEdge ( edge:BottomUpEdge ):Void {
		this.bottomX = edge.bottomX;
		this.bottomY = edge.bottomY;
		this.dx = edge.dx;
	}
	
	public inline function topX ( y:Float ):Float {
		return	bottomX + dx * ( y - bottomY );
	}
}