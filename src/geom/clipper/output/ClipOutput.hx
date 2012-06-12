package geom.clipper.output;
import flash.geom.Point;
import geom.clipper.ActiveEdge;
import geom.clipper.ClipOutputSettings;

/**
 * ...
 * @author vsugrob
 */

class ClipOutput implements IClipOutputReceiver {
	public var spawnIndex:Int;
	public var settings:ClipOutputSettings;
	public var polyOut:ClipOutputPolygon;
	public var triOut:ClipOutputTriangles;
	public var monoOut:ClipOutputMonotone;
	public var sharedData:OutputSharedData;
	
	public inline function new ( settings:ClipOutputSettings, spawnIndex:Int, sharedData:OutputSharedData ) {
		this.spawnIndex = spawnIndex;
		this.settings = settings;
		this.sharedData = sharedData;
		
		if ( settings.polygons )
			this.polyOut = new ClipOutputPolygon ( spawnIndex );
		
		if ( settings.triangles )
			this.triOut = new ClipOutputTriangles ( spawnIndex, this );
		
		if ( settings.monotone )
			this.monoOut = new ClipOutputMonotone ( spawnIndex, sharedData );
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.addPointToLeftBound ( p, aelNode );
		
		if ( settings.triangles )
			triOut.addPointToLeftBound ( p, aelNode );
		
		if ( settings.monotone )
			monoOut.addPointToLeftBound ( p, aelNode );
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.addPointToRightBound ( p, aelNode );
		
		if ( settings.triangles )
			triOut.addPointToRightBound ( p, aelNode );
		
		if ( settings.monotone )
			monoOut.addPointToRightBound ( p, aelNode );
	}
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		if ( settings.polygons )
			polyOut.addLocalMin ( aelNode1, aelNode2, p );
		
		if ( settings.triangles )
			triOut.addLocalMin ( aelNode1, aelNode2, p );
		
		if ( settings.monotone )
			monoOut.addLocalMin ( aelNode1, aelNode2, p );
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		if ( settings.polygons )
			polyOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
		
		if ( settings.triangles )
			triOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
		
		if ( settings.monotone )
			monoOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
	}
	
	public inline function merge ( output:ClipOutput, aelNode1:ActiveEdge, aelNode2:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.merge ( output.polyOut, aelNode1, aelNode2 );
		
		if ( settings.triangles )
			triOut.merge ( output.triOut, aelNode1, aelNode2 );
		
		if ( settings.monotone )
			monoOut.merge ( output.monoOut, aelNode1, aelNode2 );
	}
}