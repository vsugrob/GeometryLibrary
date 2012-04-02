package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

enum ClipperState {
	NotStarted;
	AddNewBoundPairs;
	ProcessIntersections;
	ProcessEdgesInAel;
	Finished;
}