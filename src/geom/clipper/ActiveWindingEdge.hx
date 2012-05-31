package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

class ActiveWindingEdge extends ActiveEdge {
	public var winding:Int;
	public var windingSum:Int;
	public var isGhost:Bool;
	
	public function new ( edge:Edge, kind:PolyKind, prev:ActiveEdge = null, next:ActiveEdge = null ) {
		super ( edge, kind, prev, next );
		this.asWindingEdge = this;
	}
}