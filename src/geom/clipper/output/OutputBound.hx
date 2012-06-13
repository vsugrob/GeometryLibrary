package geom.clipper.output;
import flash.geom.Point;
import geom.clipper.ActiveEdge;

/**
 * ...
 * @author vsugrob
 */

class OutputBound {
	public var column:MonotoneColumn;
	public var edge:BottomUpEdge;
	public var prevDx:Float;
	public var prev:OutputBound;
	public var next:OutputBound;
	
	public function new () { }
	
	public static inline function newFromActiveEdge ( activeEdge:ActiveEdge ):OutputBound {
		var bound = new OutputBound ();
		bound.edge = BottomUpEdge.newFromActiveEdge ( activeEdge );
		bound.prevDx = bound.edge.dx;
		
		return	bound;
	}
	
	public static inline function newFromPoints ( p0:Point, p1:Point ):OutputBound {
		var bound = new OutputBound ();
		bound.edge = BottomUpEdge.newFromPoints ( p0, p1 );
		bound.prevDx = bound.edge.dx;
		
		return	bound;
	}
	
	public static inline function newHorizontal ( pStart:Point, dx:Float ):OutputBound {
		var bound = new OutputBound ();
		bound.edge = BottomUpEdge.newHorizontal ( pStart, dx );
		bound.prevDx = bound.edge.dx;
		
		return	bound;
	}
	
	public inline function clone ():OutputBound {
		var bound = new OutputBound ();
		bound.edge = BottomUpEdge.newFromBottomUpEdge ( this.edge );
		bound.prevDx = this.prevDx;
		
		return	bound;
	}
	
	public inline function addLeftPointOnActiveEdge ( p:Point, aelNode:ActiveEdge ):Void {
		edge.setFromActiveEdge ( aelNode );
		column.addLeft ( p );
		prevDx = edge.dx;
	}
	
	public inline function addRightPointOnActiveEdge ( p:Point, aelNode:ActiveEdge ):Void {
		edge.setFromActiveEdge ( aelNode );
		prev.column.addRight ( p );
		prevDx = edge.dx;
	}
	
	public inline function addLeftPointOnNewEdge ( p:Point, p0:Point, p1:Point ):Void {
		edge.setFromPoints ( p0, p1 );
		column.addLeft ( p );
		prevDx = edge.dx;
	}
	
	public inline function addRightPointOnNewEdge ( p:Point, p0:Point, p1:Point ):Void {
		edge.setFromPoints ( p0, p1 );
		prev.column.addRight ( p );
		prevDx = edge.dx;
	}
	
	public inline function addLeftPointOnBottomUpEdge ( p:Point, edge:BottomUpEdge ):Void {
		edge.setFromBottomUpEdge ( edge );
		column.addLeft ( p );
		prevDx = edge.dx;
	}
	
	public inline function addRightPointOnBottomUpEdge ( p:Point, otherEdge:BottomUpEdge ):Void {
		edge.setFromBottomUpEdge ( otherEdge );
		prev.column.addRight ( p );
		prevDx = edge.dx;
	}
	
	public inline function addLeftPointOnHorizontal ( p:Point, dx:Float ):Void {
		edge.setHorizontal ( p, dx );
		column.addLeft ( p );
		prevDx = edge.dx;
	}
	
	public inline function addRightPointOnHorizontal ( p:Point, dx:Float ):Void {
		edge.setHorizontal ( p, dx );
		prev.column.addRight ( p );
		prevDx = edge.dx;
	}
}