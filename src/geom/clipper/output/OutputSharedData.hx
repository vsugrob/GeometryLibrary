package geom.clipper.output;
import geom.clipper.output.monotone.OutputBound;

/**
 * ...
 * @author vsugrob
 */

class OutputSharedData {
	/**
	 * First bound in bound list.
	 */
	public var boundList:OutputBound;
	public var monotoneNoHoleOutputInvolved:Bool;
	
	public function new ( monotoneNoHoleOutputInvolved:Bool ) {
		this.monotoneNoHoleOutputInvolved = monotoneNoHoleOutputInvolved;
	}
}