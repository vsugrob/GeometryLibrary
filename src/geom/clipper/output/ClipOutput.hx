package geom.clipper.output;
import flash.geom.Point;
import geom.clipper.ActiveEdge;
import geom.clipper.ClipOutputSettings;
import geom.clipper.output.monotone.ClipOutputMonotone;

/**
 * ...
 * @author vsugrob
 */

class ClipOutput implements IClipOutputReceiver {
	public var spawnIndex:Int;
	public var settings:ClipOutputSettings;
	public var polyOut:ClipOutputPolygon;
	public var boundsOut:ClipOutputBounds;
	public var monoOut:ClipOutputMonotone;
	public var sharedData:OutputSharedData;
	
	public inline function new ( settings:ClipOutputSettings, spawnIndex:Int, sharedData:OutputSharedData ) {
		this.spawnIndex = spawnIndex;
		this.settings = settings;
		this.sharedData = sharedData;
		
		if ( settings.polygons )
			this.polyOut = new ClipOutputPolygon ( spawnIndex );
		
		if ( settings.bounds )
			this.boundsOut = new ClipOutputBounds ( spawnIndex, sharedData, settings );
		
		if ( sharedData.monotoneNoHoleOutputInvolved )
			this.monoOut = new ClipOutputMonotone ( spawnIndex, sharedData, settings );
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.addPointToLeftBound ( p, aelNode );
		
		if ( settings.bounds )
			boundsOut.addPointToLeftBound ( p, aelNode );
		
		if ( sharedData.monotoneNoHoleOutputInvolved )
			monoOut.addPointToLeftBound ( p, aelNode );
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.addPointToRightBound ( p, aelNode );
		
		if ( settings.bounds )
			boundsOut.addPointToRightBound ( p, aelNode );
		
		if ( sharedData.monotoneNoHoleOutputInvolved )
			monoOut.addPointToRightBound ( p, aelNode );
	}
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		if ( settings.polygons )
			polyOut.addLocalMin ( aelNode1, aelNode2, p );
		
		if ( settings.bounds )
			boundsOut.addLocalMin ( aelNode1, aelNode2, p );
		
		if ( sharedData.monotoneNoHoleOutputInvolved )
			monoOut.addLocalMin ( aelNode1, aelNode2, p );
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		if ( settings.polygons )
			polyOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
		
		if ( settings.bounds )
			boundsOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
		
		if ( sharedData.monotoneNoHoleOutputInvolved )
			monoOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
	}
	
	public inline function merge ( output:ClipOutput, aelNode1:ActiveEdge, aelNode2:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.merge ( output.polyOut, aelNode1, aelNode2 );
		
		if ( settings.bounds )
			boundsOut.merge ( output.boundsOut, aelNode1, aelNode2 );
		
		if ( sharedData.monotoneNoHoleOutputInvolved )
			monoOut.merge ( output.monoOut, aelNode1, aelNode2 );
	}
	
	public inline function flush ():Void {
		if ( settings.polygons )
			polyOut.flush ();
		
		if ( settings.bounds )
			boundsOut.flush ();
		
		if ( sharedData.monotoneNoHoleOutputInvolved )
			monoOut.flush ();
	}
}