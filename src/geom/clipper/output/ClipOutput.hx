package geom.clipper.output;
import flash.geom.Point;
import geom.clipper.ActiveEdge;
import geom.clipper.ClipOutputSettings;

/**
 * ...
 * @author vsugrob
 */

class ClipOutput implements ClipOutputReceiver {
	public var spawnIndex:Int;
	public var settings:ClipOutputSettings;
	public var polyOut:ClipOutputPolygon;
	public var triOut:ClipOutputTriangles;
	
	public inline function new ( settings:ClipOutputSettings, spawnIndex:Int ) {
		this.spawnIndex = spawnIndex;
		this.settings = settings;
		
		if ( settings.polygons )
			this.polyOut = new ClipOutputPolygon ( spawnIndex );
		
		if ( settings.triangles )
			this.triOut = new ClipOutputTriangles ( spawnIndex );
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.addPointToLeftBound ( p, aelNode );
		
		if ( settings.triangles )
			triOut.addPointToLeftBound ( p, aelNode );
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.addPointToRightBound ( p, aelNode );
		
		if ( settings.triangles )
			triOut.addPointToRightBound ( p, aelNode );
	}
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		if ( settings.polygons )
			polyOut.addLocalMin ( aelNode1, aelNode2, p );
		
		if ( settings.triangles )
			triOut.addLocalMin ( aelNode1, aelNode2, p );
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		if ( settings.polygons )
			polyOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
		
		if ( settings.triangles )
			triOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
	}
	
	public inline function merge ( output:ClipOutput, append:Bool ):Void {
		if ( settings.polygons )
			polyOut.merge ( output.polyOut, append );
		
		if ( settings.triangles )
			triOut.merge ( output.triOut, append );
	}
}