package ;
import flash.geom.Point;
import geom.clipper.PolyKind;

/**
 * ...
 * @author vsugrob
 */

class InputPolygon {
	public var pts:Iterable <Point>;
	public var kind:PolyKind;
	
	public function new ( pts:Iterable <Point>, kind:PolyKind ) {
		this.pts = pts;
		this.kind = kind;
	}
}