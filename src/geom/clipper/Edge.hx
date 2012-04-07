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
	 * Pointer to succesor edge: an edge which belongs to the same bound and not lower than the current edge.
	 */
	public var successor:Edge;
	/**
	 * Whether an edge is horizontal. Remember that horizontal edges is a special case in Vatti clipping
	 * algorithm and therefore requires special treatment in many situations.
	 */
	public var isHorizontal:Bool;
	
	public function new ( bottomX:Float, topY:Float, dx:Float ) {
		this.bottomX = bottomX;
		this.topY = topY;
		this.dx = dx;
	}
}