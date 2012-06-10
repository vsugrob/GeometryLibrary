package geom.clipper.output;
import geom.ChainedPolygon;

/**
 * ...
 * @author vsugrob
 */

class Primitive {
	public var points:ChainedPolygon;
	public var type:PrimitiveType;
	
	public function new ( points:ChainedPolygon, type:PrimitiveType ) {
		this.points = points;
		this.type = type;
	}
}