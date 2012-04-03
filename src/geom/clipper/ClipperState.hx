package geom.clipper;

/**
 * ...
 * @author vsugrob
 */

enum ClipperState {
	NotStarted;
	AddNewBoundPairs;
	ProcessIntersections;
	BuildIntersectionList;
	ProcessIntersectionList;
	ProcessEdgesInAel;
	Finished;
}