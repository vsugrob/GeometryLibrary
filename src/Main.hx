package ;

import flash.desktop.Clipboard;
import flash.desktop.ClipboardFormats;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.Lib;
import geom.ChainedPolygon;
import geom.clipper.ActiveEdge;
import geom.clipper.ClipperState;
import geom.clipper.Edge;
import geom.clipper.LocalMaxima;
import geom.clipper.LocalMinima;
import geom.clipper.PolyKind;
import geom.clipper.Side;
import geom.clipper.VattiClipper;
import geom.ClosedPolygonIterator;
import geom.DoublyList;
import geom.TakeIterator;
import geom.ConcatIterator;
import geom.clipper.ClipOperation;

/**
 * ...
 * @author vsugrob
 */

class Main {
	static var clipper:VattiClipper;
	static var debugSprite:Sprite;
	static var inputPolys:List <InputPolygon>;
	static var panAndZoom:PanAndZoom;
	static var morpher:DebugPolyMorpher;
	static var clipOp:ClipOperation;
	
	static function testRandomPolyClipping ( numTestsPerFrame:UInt = 20 ):Void {
		var stage = Lib.current.stage;
		var prevTime:Float = Date.now ().getTime ();
		var numClipsMade:UInt = 0;
		var totalClipsMade:UInt = 0;
		stage.frameRate = 100;
		
		stage.addEventListener ( Event.ENTER_FRAME, function ( e:Event ) {
			for ( i in 0...numTestsPerFrame ) {
				inputPolys = new List <InputPolygon> ();
				
				inputPolys.add ( new InputPolygon ( DebugPolyMorpher.genRandomPoly ( 10, 0, 600 ), PolyKind.Subject ) );
				inputPolys.add ( new InputPolygon ( DebugPolyMorpher.genRandomPoly ( 10, 0, 600 ), PolyKind.Clip ) );
				
				clipper = new VattiClipper ();
				
				for ( inputPoly in inputPolys )
					clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
				
				clipper.clip ( clipOp );
				
				numClipsMade++;
				totalClipsMade++;
				
				//debugSprite.graphics.clear ();
				//drawInputPolys ( debugSprite.graphics, panAndZoom.zoom );
				//clipper.drawOutPolys ( debugSprite.graphics );
				
				//drawCurrentStep ( panAndZoom.zoom );
				
				var nowTime:Float = Date.now ().getTime ();
				var timeDelta:Float = nowTime - prevTime;
				
				if ( timeDelta >= 1000 ) {
					prevTime = nowTime;
					trace ( "Clips made: " + numClipsMade + ", total: " + totalClipsMade );
					numClipsMade = 0;
				}
			}
		} );
	}
	
	static function main () {
		//clipOp = ClipOperation.Intersection;
		clipOp = ClipOperation.Difference;
		//clipOp = ClipOperation.Union;
		
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		debugSprite = new Sprite ();
		debugSprite.x = 400;
		debugSprite.y = 25;
		stage.addChild ( debugSprite );
		
		panAndZoom = new PanAndZoom ( debugSprite );
		panAndZoom.addEventListener ( Event.COMPLETE, function ( e:Event ):Void {
			drawCurrentStep ( panAndZoom.zoom );
		} );
		
		inputPolys = new List <InputPolygon> ();
		
		/*testRandomPolyClipping ();
		return;*/
		
		/*// Test: poly with two contributing local maximas
		var subject = [
			new Point ( 0, 50 ),
			new Point ( 30, 100 ),
			new Point ( 40, 75 ),
			new Point ( 50, 100 ),
			new Point ( 150, 75 ),
			new Point ( 50, 0 )
		];
		
		var clip = [
			new Point ( 60, 20 ),
			new Point ( 20, 90 ),
			new Point ( 40, 130 ),
			new Point ( 120, 40 ),
		];
		
		addInputPolygon ( clip, PolyKind.Clip );
		addInputPolygon ( subject, PolyKind.Subject );*/
		
		/*// Test: simple case of one self-intersection (hourglass)
		var subject = [
			new Point ( 10, 10 ),
			new Point ( 0, 300 ),
			new Point ( 300, 600 ),
			new Point ( 600, 300 ),
			new Point ( 300, 0 )
		];
		
		var clip = [
			new Point ( 100, 300 ),
			new Point ( 200, 290 ),
			new Point ( 100, 100 ),
			new Point ( 200, 110 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: two clip polygons
		var subject = [
			new Point ( 0, 100 ),
			new Point ( 100, 250 ),
			new Point ( 200, 100 ),
			new Point ( 100, 0 )
		];
		
		var clip = [
			new Point ( 100, 300 ),
			new Point ( 200, 290 ),
			new Point ( 100, 100 ),
			new Point ( 200, 200 ),
		];
		
		var clip2 = [
			new Point ( 200, 0 ),
			new Point ( 0, 300 ),
			new Point ( 100, 200 )
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );
		addInputPolygon ( clip2, PolyKind.Clip );*/
		
		
		/*// Test: self-intersections with even-odd rule (vatti clip classic behavior)
		var subject = [
			new Point ( -10, -10 ),
			new Point ( 600, 0 ),
			new Point ( 610, 610 ),
			new Point ( 0, 600 ),
		];
		
		var clip = [
			new Point ( 0, 200 ),
			new Point ( 300, 0 ),
			new Point ( 600, 200 ),
			new Point ( 200, 400 ),
			new Point ( 100, 300 ),
			new Point ( 300, 100 ),
			new Point ( 500, 300 ),
			new Point ( 400, 400 ),
		];
		
		addInputPolygon ( clip, PolyKind.Clip );
		addInputPolygon ( subject, PolyKind.Subject );*/
		
		/*// Test: overlapping edges of the same poly
		var subject = [
			//new Point ( -10, -10 ),
			//new Point ( 600, 0 ),
			//new Point ( 610, 610 ),
			//new Point ( 0, 600 ),
			new Point ( 100, 100 ),
			new Point ( 400, 100 ),
			new Point ( 410, 410 ),
			new Point ( 0, 400 ),
		];
		
		var clip = [
			new Point ( 330, 500 ),
			new Point ( 325, 450 ),
			new Point ( 350, 400 ),
			new Point ( 450, 300 ),
			new Point ( 300, 250 ),
			new Point ( 150, 300 ),
			new Point ( 350, 400 ),
			new Point ( 325, 450 ),
		];
		
		addInputPolygon ( clip, PolyKind.Clip );
		addInputPolygon ( subject, PolyKind.Subject );*/
		
		/*// Test: "wings"
		var bgPoly = [
			//new Point ( -10, -10 ),
			//new Point ( 600, 0 ),
			//new Point ( 610, 610 ),
			//new Point ( 0, 600 ),
			new Point ( 100, 100 ),
			new Point ( 400, 100 ),
			new Point ( 410, 410 ),
			new Point ( 0, 400 ),
		];
		
		var leftWing = [
			new Point ( 300, 500 ),
			new Point ( 200, 200 ),
			new Point ( 400, 300 ),
		];
		
		var rightWing = [
			new Point ( 300, 500 ),
			new Point ( 600, 200 ),
			new Point ( 400, 300 ),
		];
		
		addInputPolygon ( bgPoly, PolyKind.Subject );
		addInputPolygon ( leftWing, PolyKind.Clip );
		addInputPolygon ( rightWing, PolyKind.Clip );*/
		
		/*// Test: "wings" rearranged
		var bgPoly = [
			//new Point ( -10, -10 ),
			//new Point ( 600, 0 ),
			//new Point ( 610, 610 ),
			//new Point ( 0, 600 ),
			new Point ( 100, 100 ),
			new Point ( 400, 100 ),
			new Point ( 410, 410 ),
			new Point ( 0, 400 ),
		];
		
		var leftWing = [
			new Point ( 300, 500 ),
			new Point ( 200, 200 ),
			new Point ( 400, 300 ),
		];
		
		var rightWing = [
			new Point ( 300, 500 ),
			new Point ( 600, 200 ),
			new Point ( 400, 300 ),
		];
		
		addInputPolygon ( bgPoly, PolyKind.Subject );
		addInputPolygon ( leftWing, PolyKind.Clip );
		addInputPolygon ( rightWing, PolyKind.Subject );*/
		
		/*// Test: singly-rooted tooth
		var bgPoly = [
			//new Point ( -10, -10 ),
			//new Point ( 600, 0 ),
			//new Point ( 610, 610 ),
			//new Point ( 0, 600 ),
			new Point ( 100, 100 ),
			new Point ( 400, 100 ),
			new Point ( 410, 410 ),
			new Point ( 0, 400 ),
		];
		
		var tooth = [
			new Point ( 300, 500 ),
			new Point ( 100, 300 ),
			new Point ( 300, 200 ),
			new Point ( 500, 300 ),
			new Point ( 300, 500 ),
			new Point ( 350, 300 ),
			new Point ( 250, 330 ),
		];
		
		addInputPolygon ( bgPoly, PolyKind.Subject );
		addInputPolygon ( tooth, PolyKind.Clip );*/
		
		/*// Test: q-shaped poly.
		var bgPoly = [
			//new Point ( -10, -10 ),
			//new Point ( 600, 0 ),
			//new Point ( 610, 610 ),
			//new Point ( 0, 600 ),
			new Point ( 100, 100 ),
			new Point ( 400, 100 ),
			new Point ( 410, 410 ),
			new Point ( 0, 400 ),
		];
		
		var tooth = [
			new Point ( 500, 500 ),
			new Point ( 100, 490 ),
			new Point ( 110, 100 ),
			new Point ( 400, 110 ),
			new Point ( 390, 480 ),
			new Point ( 300, 470 ),
			new Point ( 310, 200 ),
			new Point ( 200, 210 ),
			new Point ( 210, 300 ),
			new Point ( 500, 310 ),
		];
		
		addInputPolygon ( bgPoly, PolyKind.Subject );
		addInputPolygon ( tooth, PolyKind.Clip );*/
		
		/*// Test: many-rooted tooth
		var bgPoly = [
			//new Point ( -10, -10 ),
			//new Point ( 600, 0 ),
			//new Point ( 610, 610 ),
			//new Point ( 0, 600 ),
			new Point ( 100, 100 ),
			new Point ( 400, 100 ),
			new Point ( 410, 410 ),
			new Point ( 0, 400 ),
		];
		
		var tooth = [
			new Point ( 50, 200 ),
			new Point ( 300, 500 ),
			new Point ( 150, 200 ),
			new Point ( 175, 210 ),
			new Point ( 300, 500 ),
			new Point ( 200, 190 ),
			new Point ( 250, 230 ),
			new Point ( 300, 500 ),
			new Point ( 290, 240 ),
			new Point ( 320, 280 ),
			new Point ( 300, 500 ),
			
			new Point ( 600, 200 ),
			new Point ( 250, 50 ),
		];
		
		addInputPolygon ( bgPoly, PolyKind.Subject );
		addInputPolygon ( tooth, PolyKind.Clip );*/
		
		/*// Test: coincident polys, "diamond"
		var subject = [
			new Point ( 100, 0 ),
			new Point ( 200, 100 ),
			new Point ( 100, 300 ),
			new Point ( 0, 100 ),
		];
		
		var clip = [
			new Point ( 100, 0 ),
			new Point ( 150, 100 ),
			new Point ( 100, 300 ),
			new Point ( 50, 100 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: "lowered wings"
		var bgPoly = [
			new Point ( -10, -10 ),
			new Point ( 600, 0 ),
			new Point ( 610, 610 ),
			new Point ( 0, 600 ),
		];
		
		var leftWing = [
			new Point ( 300, 500 ),
			new Point ( 200, 400 ),
			new Point ( 400, 300 ),
		];
		
		var rightWing = [
			new Point ( 300, 500 ),
			new Point ( 600, 400 ),
			new Point ( 400, 300 ),
		];
		
		addInputPolygon ( bgPoly, PolyKind.Subject );
		
		// Subtest 1: edges are not resorted at the local maxima
		//addInputPolygon ( rightWing, PolyKind.Clip );
		//addInputPolygon ( leftWing, PolyKind.Clip );
		// Subtest 2: edges ARE resorted at the local maxima
		addInputPolygon ( leftWing, PolyKind.Clip );
		addInputPolygon ( rightWing, PolyKind.Clip );*/
		
		/*// Test: flipped many-rooted tooth
		var bgPoly = [
			//new Point ( -10, -10 ),
			//new Point ( 600, 0 ),
			//new Point ( 610, 610 ),
			//new Point ( 0, 600 ),
			new Point ( 100, 100 ),
			new Point ( 400, 100 ),
			new Point ( 410, 410 ),
			new Point ( 0, 400 ),
		];
		
		var tooth = [
			new Point ( 300, 500 ),
			new Point ( 0, 300 ),
			new Point ( 300, 0 ),
			new Point ( 150, 300 ),
			new Point ( 180, 320 ),
			new Point ( 300, 0 ),
			new Point ( 210, 330 ),
			new Point ( 240, 310 ),
			new Point ( 300, 0 ),
			new Point ( 300, 250 ),
			new Point ( 340, 275 ),
			new Point ( 300, 0 ),
			
			new Point ( 600, 300 ),
		];
		
		addInputPolygon ( bgPoly, PolyKind.Subject );
		addInputPolygon ( tooth, PolyKind.Clip );*/
		
		/*// Test: first issue from "doc/issues/joints.svg"
		var subject = [
			new Point ( 0, 0 ),
			new Point ( -50.46992166899145, -90.66692451015115 ),
			new Point ( 10, -140 ),
		];
		
		var clip = [
			new Point ( -50.46992166899145, 50 ),
			new Point ( -50.46992166899145, -150 ),
			new Point ( 100, -160 ),
			new Point ( 50, 100 ),
		];
		
		debugSprite.x += 100;
		debugSprite.y += 170;
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: edge intersecting join in local minima
		var subject = [
			new Point ( 300, 100 ),
			new Point ( 500, 300 ),
			new Point ( 300, 500 ),
			new Point ( 100, 300 ),
		];
		
		var clip = [
			new Point ( 300, 300 ),
			new Point ( 300, 0 ),
			new Point ( 600, 100 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: several zero-length edges
		var subject = [
			new Point ( 300, 100 ),
			new Point ( 300, 100 ),
			new Point ( 500, 300 ),
			new Point ( 500, 300 ),
			new Point ( 300, 500 ),
			new Point ( 300, 500 ),
			new Point ( 100, 300 ),
			new Point ( 100, 300 ),
			new Point ( 100, 300 ),
		];
		
		var clip = [
			new Point ( 300, 300 ),
			new Point ( 300, 300 ),
			new Point ( 300, 0 ),
			new Point ( 300, 0 ),
			new Point ( 300, 0 ),
			new Point ( 600, 100 ),
			new Point ( 600, 100 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: one horizontal edge.
		var subject = [
			new Point ( 300, 500 ),
			new Point ( 400, 400 ),
			new Point ( 500, 400 ),
			new Point ( 200, 100 ),
		];
		
		var clip = [
			new Point ( 300, 0 ),
			new Point ( 400, 600 ),
			new Point ( 500, 200 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: several coincident horizontal edges.
		var subject = [
			new Point ( 300, 500 ),
			new Point ( 400, 400 ),
			new Point ( 500, 400 ),
			new Point ( 200, 100 ),
		];
		
		var clip = [
			new Point ( 300, 0 ),
			new Point ( 400, 600 ),
			new Point ( 700, 400 ),
			new Point ( 450, 400 ),
			new Point ( 500, 400 ),
			new Point ( 390, 400 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		// Test: horizontal edge pairing to terminating edge
		var subject = [
			new Point ( 200, 200 ),
			new Point ( 400, 200 ),
			new Point ( 400, 400 ),
			new Point ( 200, 400 ),
		];
		
		var clip = [
			new Point ( 300, 0 ),
			new Point ( 150, 500 ),
			new Point ( 600, 150 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );
		
		/*// Test: penetrating triangles
		var subject = [
			new Point ( 300, 500 ),
			new Point ( 100, 200 ),
			new Point ( 500, 250 ),
		];
		
		var clip = [
			new Point ( 300, 300 ),
			new Point ( 100, 100 ),
			new Point ( 500, 110 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: two coincident squares
		var subject = [
			new Point ( 200, 200 ),
			new Point ( 400, 200 ),
			new Point ( 400, 400 ),
			new Point ( 200, 400 ),
		];
		
		var clip = [
			new Point ( 200, 200 ),
			new Point ( 400, 200 ),
			new Point ( 400, 400 ),
			new Point ( 200, 400 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: two shifted squares
		var subject = [
			new Point ( 200, 200 ),
			new Point ( 400, 200 ),
			new Point ( 400, 400 ),
			new Point ( 200, 400 ),
		];
		
		var clip = [
			new Point ( 300, 200 ),
			new Point ( 500, 200 ),
			new Point ( 500, 400 ),
			new Point ( 300, 400 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: horizontal edge arriving at local maxima
		// and (possibly) intersecting terminating edges
		// already present in AEL
		var subject = [
			new Point ( 400, 500 ),
			new Point ( 500, 300 ),
			new Point ( 300, 300 ),
		];
		
		var clip = [
			new Point ( 100, 300 ),
			new Point ( 400, 300 ),
			new Point ( 300, 100 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*var angle = 0.0;
		var dAngle = 10;
		
		while ( angle <= 45 ) {
			// Test: coincident edges of different kind
			var bgPoly = [
				new Point ( 300, 0 ),
				new Point ( 600, 300 ),
				new Point ( 300, 600 ),
				new Point ( 0, 300 ),
			];
			
			var clip = [
				new Point ( 300, 200 ),
				new Point ( 400, 100 ),
				new Point ( 500, 200 ),
				new Point ( 400, 300 ),
			];
			
			//var clip = [
				//new Point ( 300, 200 ),
				//new Point ( 395, 105 ),
				//new Point ( 495, 205 ),
				//new Point ( 400, 300 ),
			//];
			
			var center = DebugPolyMorpher.getPolyCenter ( bgPoly );
			DebugPolyMorpher.rotatePoly ( bgPoly, angle * Math.PI / 180, center );
			DebugPolyMorpher.rotatePoly ( clip, angle * Math.PI / 180, center );
			//inputPolys = new List <InputPolygon> ();
			
			addInputPolygon ( bgPoly, PolyKind.Subject );
			
			//if ( angle != 22.5 )
				addInputPolygon ( clip, PolyKind.Clip );
			
			//clipper = new VattiClipper ();
			//
			//for ( inputPoly in inputPolys ) {
				//clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
			//}
			//
			//try {
				//clipper.clip ( clipOp );
			//} catch ( ex:Dynamic ) {
				//trace ( 'EXCEPTION. angle: ' + angle + ' dAngle: ' + dAngle );
				//trace ( ex );
				//
				//break;
			//}
			
			angle += dAngle;
		}*/
		
		morpher = new DebugPolyMorpher ( inputPolys, 20 );
		//morpher.stopped = true;
		var prevTime:Float = Date.now ().getTime () / 1000;
		
		stage.addEventListener ( Event.ENTER_FRAME, function ( e:Event ) {
			var nowTime:Float = Date.now ().getTime () / 1000;
			
			morpher.update ( nowTime - prevTime );
			prevTime = nowTime;
			
			clipper = new VattiClipper ();
			
			for ( inputPoly in inputPolys )
				clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
			
			clipper.clip ( clipOp );
			
			//debugSprite.graphics.clear ();
			//drawInputPolys ( debugSprite.graphics, panAndZoom.zoom );
			//clipper.drawOutPolys ( debugSprite.graphics );
			
			drawCurrentStep ( panAndZoom.zoom );
		} );
		
		/*clipper = new VattiClipper ();
		
		for ( inputPoly in inputPolys )
			clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
		
		clipper.clip ();
		drawInputPolys ( debugSprite.graphics, panAndZoom.zoom );
		clipper.drawOutPolys ( debugSprite.graphics );*/
		
		//drawCurrentStep ( panAndZoom.zoom );
		
		var stepNum = 0;
		
		// Setup stage for clipStep
		stage.addEventListener ( KeyboardEvent.KEY_DOWN, function ( kb:KeyboardEvent ) {
			if ( kb.keyCode == 32 ) {	// Space
				if ( clipper.clipStep () )
					stepNum++;
				
				drawCurrentStep ( panAndZoom.zoom );
				
				if ( clipper.clipperState == ClipperState.Finished )
					clipper.drawOutPolys ( debugSprite.graphics );
				
				trace ( "clipStep () #" + stepNum + ", next action: " + clipper.clipperState );
				
				clipper.traceNextIntersection ();
			} else if ( kb.keyCode == 49 )	// 1
				clipper.drawAelBySide ( debugSprite.graphics );
			else if ( kb.keyCode == 50 )	// 2
				clipper.drawAelByPoly ( debugSprite.graphics );
			else if ( kb.keyCode == 83 ) {	// s
				var buf = new StringBuf ();
				drawInputPolysSvg ( buf );
				Clipboard.generalClipboard.setData ( ClipboardFormats.TEXT_FORMAT, buf.toString () );
			} else if ( kb.keyCode == 65 )	// a
				clipper.traceAel ();
			else if ( kb.keyCode == 73 )	// i
				clipper.traceIl ();
			else if ( kb.keyCode == 77 )	// m
				morpher.stopped = !morpher.stopped;
			else if ( kb.keyCode == 90 )	// z
				trace ( "zoom: " + panAndZoom.zoom );
			else if ( kb.keyCode == 67 ) {	// c
				rotateClipOperation ();
				
				trace ( clipOp );
			} else if ( kb.keyCode == 75 )	// k
				switchPolyKinds ();
		} );
	}
	
	private static function rotateClipOperation ():Void {
		switch ( clipOp ) {
		case ClipOperation.Intersection:
			clipOp = ClipOperation.Difference;
		case ClipOperation.Difference:
			clipOp = ClipOperation.Union;
		default:
			clipOp = ClipOperation.Intersection;
		}
	}
	
	private static function switchPolyKinds ():Void {
		for ( poly in inputPolys ) {
			poly.kind = poly.kind == PolyKind.Clip ? PolyKind.Subject : PolyKind.Clip;
		}
	}
	
	private static function addInputPolygon ( pts:Array <Point>, kind:PolyKind ):Void {
		inputPolys.add ( new InputPolygon ( pts, kind ) );
	}
	
	private static function drawCurrentStep ( zoom:Float = 1.0 ):Void {
		if ( zoom < 1 )
			zoom = 1;
		
		debugSprite.graphics.clear ();
		drawInputPolys ( debugSprite.graphics, zoom );
		
		clipper.drawCurrentScanbeam ( debugSprite.graphics, zoom );
		clipper.drawIntersectionScanline ( debugSprite.graphics, zoom );
		
		clipper.drawContributedPolys ( debugSprite.graphics, 0, 0.5, 2 / zoom, 0xaa7700, 0.5 );
		clipper.drawAelBySide ( debugSprite.graphics, zoom );
		clipper.drawIntersections ( debugSprite.graphics, zoom );
	}
	
	private static function drawInputPolys ( graphics:Graphics, zoom:Float = 1.0 ):Void {
		var subjPolys = new List <InputPolygon> ();
		var clipPolys = new List <InputPolygon> ();
		
		for ( inputPoly in inputPolys ) {
			if ( inputPoly.kind == PolyKind.Subject )
				subjPolys.add ( inputPoly );
			else
				clipPolys.add ( inputPoly );
		}
		
		VattiClipper.beginDrawPoly ( graphics, 0x777777, 0.7, 1 / zoom, 0xffdd77, 0.5 );
		
		for ( inputPoly in subjPolys )
			VattiClipper.drawPoly ( inputPoly.pts, graphics );
		
		VattiClipper.endDrawPoly ( graphics );
		
		VattiClipper.beginDrawPoly ( graphics, 0x777777, 0.7, 1 / zoom, 0x77ddff, 0.5 );
		
		for ( inputPoly in clipPolys )
			VattiClipper.drawPoly ( inputPoly.pts, graphics );
		
		VattiClipper.endDrawPoly ( graphics );
	}
	
	private static function drawInputPolysSvg ( buf:StringBuf ):Void {
		var subjPolys = new List <InputPolygon> ();
		var clipPolys = new List <InputPolygon> ();
		
		for ( inputPoly in inputPolys ) {
			if ( inputPoly.kind == PolyKind.Subject )
				subjPolys.add ( inputPoly );
			else
				clipPolys.add ( inputPoly );
		}
		
		buf.add ( '<g>\n' );
		VattiClipper.beginDrawPolySvg ( buf, 0x777777, 0.7, 1, 0xffdd77, 0.5 );
		
		for ( inputPoly in subjPolys )
			VattiClipper.drawPolySvg ( inputPoly.pts, buf );
		
		VattiClipper.endDrawPolySvg ( buf );
		
		VattiClipper.beginDrawPolySvg ( buf, 0x777777, 0.7, 1, 0x77ddff, 0.5 );
		
		for ( inputPoly in clipPolys )
			VattiClipper.drawPolySvg ( inputPoly.pts, buf );
		
		VattiClipper.endDrawPolySvg ( buf );
		buf.add ( '</g>\n' );
	}
}