package geom.clipper;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class Intersection {
	public var edge1:Edge;
	public var edge2:Edge;
	public var p:Point;
	
	public function new ( edge1:Edge, edge2:Edge, p:Point ) {
		this.edge1 = edge1;
		this.edge2 = edge2;
		this.p = p;
	}
}