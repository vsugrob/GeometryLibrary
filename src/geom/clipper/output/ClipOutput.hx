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
	private var monotoneNoHoleOutputInvolved:Bool;
	public var polyOut:ClipOutputPolygon;
	public var monoOut:ClipOutputMonotone;
	public var sharedData:OutputSharedData;
	
	public inline function new ( settings:ClipOutputSettings, spawnIndex:Int, sharedData:OutputSharedData ) {
		this.spawnIndex = spawnIndex;
		this.settings = settings;
		this.monotoneNoHoleOutputInvolved = settings.monotoneNoHoleOutputInvolved;	// Evaluate this property once and store result
		this.sharedData = sharedData;
		
		if ( settings.polygons )
			this.polyOut = new ClipOutputPolygon ( spawnIndex );
		
		if ( this.monotoneNoHoleOutputInvolved )
			this.monoOut = new ClipOutputMonotone ( spawnIndex, sharedData, settings );
	}
	
	public inline function addPointToLeftBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.addPointToLeftBound ( p, aelNode );
		
		if ( this.monotoneNoHoleOutputInvolved )
			monoOut.addPointToLeftBound ( p, aelNode );
	}
	
	public inline function addPointToRightBound ( p:Point, aelNode:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.addPointToRightBound ( p, aelNode );
		
		if ( this.monotoneNoHoleOutputInvolved )
			monoOut.addPointToRightBound ( p, aelNode );
	}
	
	public inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		if ( settings.polygons )
			polyOut.addLocalMin ( aelNode1, aelNode2, p );
		
		if ( this.monotoneNoHoleOutputInvolved )
			monoOut.addLocalMin ( aelNode1, aelNode2, p );
	}
	
	public inline function addLocalMax ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		if ( settings.polygons )
			polyOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
		
		if ( this.monotoneNoHoleOutputInvolved )
			monoOut.addLocalMax ( aelNode1, aelNode2, closestContribNode, p );
	}
	
	public inline function merge ( output:ClipOutput, aelNode1:ActiveEdge, aelNode2:ActiveEdge ):Void {
		if ( settings.polygons )
			polyOut.merge ( output.polyOut, aelNode1, aelNode2 );
		
		if ( this.monotoneNoHoleOutputInvolved )
			monoOut.merge ( output.monoOut, aelNode1, aelNode2 );
	}
	
	public inline function flush ():Void {
		if ( settings.polygons )
			polyOut.flush ();
		
		if ( this.monotoneNoHoleOutputInvolved )
			monoOut.flush ();
	}
}