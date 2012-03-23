package geom.clipper;
import geom.ChainedPolygon;

/**
 * ...
 * @author vsugrob
 */

class Edge {
	/**
	 * Initially the x-coodinate of the bottom vertex, but once the
	 * edge is on the AEL, then it is the x-intercept of the edge with
	 * the line at the bottom of the current scanbeam.
	 */
	public var bottomX:Float;
	/**
	 * Y-coordinate of top vertex.
	 */
	public var topY:Float;
	/**
	 * The reciprocal of the slope of the edge.
	 */
	public var dx:Float;
	/**
	 * Does edge belong to clip or subject polygon?
	 */
	public var kind:PolyKind;
	/**
	 * Is it a left or right bound edge?
	 */
	public var side:Side;
	/**
	 * Does edge contribute to output polygons?
	 */
	public var contributing:Bool;
	/**
	 * Pointer to partial polygon associated to the edge.
	 */
	public var poly:ChainedPolygon;
	/**
	 * Pointer to succesor edge: an edge which belongs to the same bound and not lower than the current edge.
	 */
	public var successor:Edge;
	public var isHorizontal:Bool;
	
	public function new ( bottomX:Float, topY:Float, dx:Float, kind:PolyKind ) {
		this.bottomX = bottomX;
		this.topY = topY;
		this.dx = dx;
		this.kind = kind;
	}
	
	public function toString ():String {
		return	"(bottomX: " + bottomX + "topY: " + topY + "dx: " + dx + 
			"kind: " + kind + "side: " + side + "contributing: " + contributing +
			"poly: " + ( poly != null ? "assigned" : "null" ) + ")";
	}
}