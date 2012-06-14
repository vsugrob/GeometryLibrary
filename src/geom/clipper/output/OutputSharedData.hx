package geom.clipper.output;
import geom.clipper.output.monotone.OutputBound;
import geom.clipper.PolyBounds;

/**
 * ...
 * @author vsugrob
 */

class OutputSharedData {
	/**
	 * First bound in bound list.
	 */
	public var boundList:OutputBound;
	/**
	 * Whether any kind of the monotone outputs must be produced?
	 */
	public var monotoneNoHoleOutputInvolved:Bool;
	
	public function new ( monotoneNoHoleOutputInvolved:Bool ) {
		this.monotoneNoHoleOutputInvolved = monotoneNoHoleOutputInvolved;
	}
}