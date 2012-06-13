package geom.clipper.output.monotone;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.clipper.ClipOutputSettings;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class MonotonePolygonColumn {
	private var poly:ChainedPolygon;
	public var polys:DoublyList <ChainedPolygon>;
	
	public inline function new ( p:Point ) {
		this.poly = ChainedPolygon.create ( p );
		this.polys = new DoublyList <ChainedPolygon> ();
		this.polys.insertFirst ( this.poly );
	}
	
	public inline function addLeft ( p:Point ):Void {
		poly.prependPoint ( p );
	}
	
	public inline function addRight ( p:Point ):Void {
		poly.appendPoint ( p );
	}
	
	public inline function merge ( other:MonotonePolygonColumn ):Void {
		polys.prepend ( other.polys );
	}
}