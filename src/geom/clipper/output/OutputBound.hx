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
	
	public function new ( column:MonotoneColumn, prev:OutputBound, next:OutputBound ) {
		this.column = column;
		this.prev = prev;
		this.next = next;
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
		edge.setFromActiveEdge ( p0, p1 );
		prev.column.addRight ( p );
		prevDx = edge.dx;
	}
}