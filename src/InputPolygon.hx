package ;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.clipper.PolyKind;

/**
 * ...
 * @author vsugrob
 */

class InputPolygon {
	public var pts:Array <Point>;
	public var kind:PolyKind;
	
	public function new ( pts:Array <Point>, kind:PolyKind ) {
		this.pts = pts;
		this.kind = kind;
	}
}