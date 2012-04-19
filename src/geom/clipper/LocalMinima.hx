package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

/**
 * There is a significant cause why LocalMinima inherits Edge, explanation follows.
 * All edges belong to some bound and connected via their successor
 * field. Normally successor contains pointer to a next edge in bound
 * but once two bounds meets in their apex there should be a way to
 * get this pair. So last edge in bound have it's successor pointer set
 * to LocalMinima record that "knows" about both joining bounds. This is
 * one of the reasons for inheritance mentioned above.
 * Q: Why don't you inherited both Edge and LocalMinima from some common base
 * class?
 * A: And this is the other reason because inheritance have its cost: every instance of subclass we
 * create will call subclass constructor first and superclass constructor second. So for each edge
 * we must call two functions instead of one which impacts performance significantly.
 * In addition there will be much less local minimas than edges so despite we have some extra
 * fields LocalMinima inherited from Edge (successor, isHorizontal), still it is a better way.
 */
class LocalMinima extends Edge {
	/**
	 * First edge ending at the local minima.
	 */
	public var edge1:Edge;
	/**
	 * Second edge ending at the local minima.
	 */
	public var edge2:Edge;
	
	public function new ( jointX:Float, jointY:Float, edge1:Edge, edge2:Edge ) {
		super ( jointX, jointY, Math.NaN );
		
		this.edge1 = edge1;
		this.edge2 = edge2;
	}
}