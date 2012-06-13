package ;

import flash.desktop.Clipboard;
import flash.desktop.ClipboardFormats;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import flash.Lib;
import geom.clipper.ClipOperation;
import geom.clipper.ClipOutputSettings;
import geom.clipper.output.ClipOutput;
import geom.clipper.PolyFill;
import geom.clipper.PolyKind;
import geom.clipper.VattiClipper;

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
	static var subjectFill:PolyFill;
	static var clipFill:PolyFill;
	static var forceOneClip:Bool;
	static var randomOuputStrokes:Bool;
	static var emphasizeHoles:Bool;
	static var outputSettings:ClipOutputSettings;
	
	static function testRandomPolyClipping ( numTestsPerFrame:UInt = 20, numPoints:UInt = 100 ):Void {
		var stage = Lib.current.stage;
		var prevTime:Float = Date.now ().getTime ();
		var startTime:Float = prevTime;
		var numClipsMade:UInt = 0;
		var totalClipsMade:UInt = 0;
		stage.frameRate = 100;
		
		stage.addEventListener ( Event.ENTER_FRAME, function ( e:Event ) {
			for ( i in 0...numTestsPerFrame ) {
				inputPolys = new List <InputPolygon> ();
				
				inputPolys.add ( new InputPolygon ( DebugPolyMorpher.genRandomPoly ( numPoints, 0, 600 ), PolyKind.Subject ) );
				inputPolys.add ( new InputPolygon ( DebugPolyMorpher.genRandomPoly ( numPoints, 0, 600 ), PolyKind.Clip ) );
				
				clipper = new VattiClipper ( outputSettings );
				
				for ( inputPoly in inputPolys )
					clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
				
				clipper.clip ( clipOp, subjectFill, clipFill );
				
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
					var timeElapsed = nowTime - startTime;
					var avgClipsPerSecond = totalClipsMade / ( timeElapsed / 1000 );
					
					trace ( "Clips made: " + numClipsMade + ", total: " + totalClipsMade + ", avgClipsPerSecond: " + avgClipsPerSecond );
					numClipsMade = 0;
				}
			}
		} );
	}
	
	static function main () {
		forceOneClip = true;
		
		clipOp = ClipOperation.Intersection;
		//clipOp = ClipOperation.Difference;
		//clipOp = ClipOperation.Union;
		//clipOp = ClipOperation.Xor;
		
		subjectFill = PolyFill.EvenOdd;
		clipFill = PolyFill.EvenOdd;
		
		outputSettings = new ClipOutputSettings ( true, false, false, false, false );
		
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
		
		/*testRandomPolyClipping ( 100, 10 );
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
		
		// Test: simple case of one self-intersection (hourglass)
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
		addInputPolygon ( clip, PolyKind.Clip );
		
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
		
		/*// Test: horizontal edge pairing to terminating edge
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
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: one diamond standing next to other
		var subject = [
			new Point ( 100, 0 ),
			new Point ( 200, 100 ),
			new Point ( 100, 200 ),
			new Point ( 0, 100 ),
		];
		
		var clip = [
			new Point ( 200, 0 ),
			new Point ( 300, 100 ),
			new Point ( 200, 200 ),
			new Point ( 100, 100 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: one diamond above the other
		var subject = [
			new Point ( 100, 0 ),
			new Point ( 200, 100 ),
			new Point ( 100, 200 ),
			new Point ( 0, 100 ),
		];
		
		var clip = [
			new Point ( 100, 100 ),
			new Point ( 200, 200 ),
			new Point ( 0, 400 ),
			new Point ( 100, 500 ),
			new Point ( 200, 400 ),
			new Point ( 0, 200 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: one diamond germinating through the other
		var subject = [
			new Point ( 200, 0 ),
			new Point ( 300, 100 ),
			new Point ( 200, 200 ),
			new Point ( 100, 100 ),
		];
		
		var clip = [
			new Point ( 200, 50 ),
			new Point ( 400, 100 ),
			new Point ( 200, 150 ),
			new Point ( 0, 100 ),
		];
		
		addInputPolygon ( subject, PolyKind.Subject );
		addInputPolygon ( clip, PolyKind.Clip );*/
		
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
		
		/*// Test: horizontally penetrating triangles
		var subject = [
			new Point ( 0, 0 ),
			new Point ( 300, 100 ),
			new Point ( 0, 200 ),
		];
		
		var clip = [
			new Point ( 100, 140 ),
			new Point ( 250, 10 ),
			new Point ( 250, 125 ),
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
		
		/*// Test: simple nonzero test
		var subj1 = [
			new Point ( 100, 0 ),
			new Point ( 200, 100 ),
			new Point ( 100, 200 ),
			new Point ( 0, 100 ),
		];
		
		subj1.reverse ();
		
		var subj2 = [
			new Point ( 100, 100 ),
			new Point ( 200, 200 ),
			new Point ( 100, 300 ),
			new Point ( 0, 200 ),
		];
		
		subj2.reverse ();
		
		var subj3 = [
			new Point ( 100, -100 ),
			new Point ( 400, 200 ),
			new Point ( 100, 500 ),
			new Point ( -200, 200 ),
		];
		
		addInputPolygon ( subj1, PolyKind.Subject );
		addInputPolygon ( subj2, PolyKind.Subject );
		addInputPolygon ( subj3, PolyKind.Subject );
		subjectFill = PolyFill.NonZero;
		
		var clip = [
			new Point ( 0, 100 ),
			new Point ( 400, 300 ),
			new Point ( 300, 100 ),
		];
		
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: cross in circle nonzero test
		var subj1 = [
			new Point ( 0, 400 ),
			new Point ( 400, 0 ),
			new Point ( 500, 100 ),
			new Point ( 100, 500 ),
		];
		
		var subj2 = [
			new Point ( 100, 0 ),
			new Point ( 500, 400 ),
			new Point ( 400, 500 ),
			new Point ( 0, 100 ),
		];
		
		subj2.reverse ();
		
		var subj3 = [
			new Point ( -100, -100 ),
			new Point ( 600, -100 ),
			new Point ( 600, 600 ),
			new Point ( -100, 600 ),
		];
		
		addInputPolygon ( subj1, PolyKind.Subject );
		addInputPolygon ( subj2, PolyKind.Subject );
		addInputPolygon ( subj3, PolyKind.Subject );
		subjectFill = PolyFill.NonZero;
		
		var clip = [
			new Point ( 100, 100 ),
			new Point ( 400, 400 ),
			new Point ( 400, 100 ),
		];
		
		addInputPolygon ( clip, PolyKind.Clip );*/
		
		/*// Test: simple triangulation test
		var subj1 = [
			new Point ( 300, 500 ),
		];
		
		subj1.unshift ( new Point ( 200, 400 ) );
		subj1.unshift ( new Point ( 175, 350 ) );
		subj1.unshift ( new Point ( 175, 300 ) );
		subj1.unshift ( new Point ( 210, 275 ) );
		subj1.push ( new Point ( 250, 275 ) );
		subj1.push ( new Point ( 400, 0 ) );
		
		//subj1.push ( new Point ( 500, 200 ) );
		//subj1.push ( new Point ( 700, 400 ) );
		//subj1.push ( new Point ( 500, 300 ) );
		
		addInputPolygon ( subj1, PolyKind.Subject );
		clipOp = ClipOperation.Union;*/
		
		/*// Test: poly with hole triangulation
		var subj1 = [
			new Point ( 300, 0 ),
			new Point ( 600, 300 ),
			new Point ( 300, 600 ),
			new Point ( 0, 300 ),
		];
		
		var subj2 = [
			new Point ( 200, 200 ),
			new Point ( 200, 400 ),
			new Point ( 100, 300 ),
		];
		
		var subj3 = [
			new Point ( 350, 450 ),
			new Point ( 450, 350 ),
			new Point ( 300, 150 ),
		];
		
		addInputPolygon ( subj1, PolyKind.Subject );
		addInputPolygon ( subj2, PolyKind.Subject );
		addInputPolygon ( subj3, PolyKind.Subject );
		clipOp = ClipOperation.Union;*/
		
		/*// Test: poly with concave hole triangulation
		var subj1 = [
			new Point ( 300, 0 ),
			new Point ( 600, 300 ),
			new Point ( 300, 600 ),
			new Point ( 0, 300 ),
		];
		
		var subj2 = [
			new Point ( 200, 400 ),
			new Point ( 300, 300 ),
			new Point ( 400, 450 ),
			new Point ( 350, 200 ),
		];
		
		var subj3 = [
			new Point ( 300, 400 ),
			new Point ( 350, 450 ),
			new Point ( 250, 475 ),
		];
		
		addInputPolygon ( subj1, PolyKind.Subject );
		addInputPolygon ( subj2, PolyKind.Subject );
		addInputPolygon ( subj3, PolyKind.Subject );
		clipOp = ClipOperation.Union;*/
		
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
		morpher.stopped = true;
		var prevTime:Float = Date.now ().getTime () / 1000;
		
		stage.addEventListener ( Event.ENTER_FRAME, function ( e:Event ) {
			var nowTime:Float = Date.now ().getTime () / 1000;
			
			morpher.update ( nowTime - prevTime );
			prevTime = nowTime;
			
			if ( morpher.stopped ) {
				if ( forceOneClip )
					forceOneClip = false;
				else
					return;
			}
			
			clipper = new VattiClipper ( outputSettings );
			
			for ( inputPoly in inputPolys )
				clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
			
			clipper.clip ( clipOp, subjectFill, clipFill );
			
			//debugSprite.graphics.clear ();
			//drawInputPolys ( debugSprite.graphics, panAndZoom.zoom );
			//clipper.drawOutPolys ( debugSprite.graphics );
			
			drawCurrentStep ( panAndZoom.zoom );
		} );
		
		/*clipper = new VattiClipper ( outputSettings );
		
		for ( inputPoly in inputPolys )
			clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
		
		clipper.clip ();
		drawInputPolys ( debugSprite.graphics, panAndZoom.zoom );
		clipper.drawOutPolys ( debugSprite.graphics );*/
		
		//drawCurrentStep ( panAndZoom.zoom );
		
		stage.addEventListener ( KeyboardEvent.KEY_DOWN, function ( kb:KeyboardEvent ) {
			if ( kb.keyCode == 83 ) {	// s
				var buf = new StringBuf ();
				drawInputPolysSvg ( buf );
				Clipboard.generalClipboard.setData ( ClipboardFormats.TEXT_FORMAT, buf.toString () );
			} else if ( kb.keyCode == 77 )	// m
				morpher.stopped = !morpher.stopped;
			else if ( kb.keyCode == 90 )	// z
				trace ( "zoom: " + panAndZoom.zoom );
			else if ( kb.keyCode == 67 ) {	// c
				rotateClipOperation ();
				
				trace ( clipOp );
			} else if ( kb.keyCode == 75 )	// k
				swapPolyKinds ();
			else if ( kb.keyCode == 72 ) {	// h
				hideInputPolys = !hideInputPolys;
				forceOneClip = true;
			} else if ( kb.keyCode == 37 ) {	// left arrow
				if ( morpher.rotationVelocity > 0 )
					morpher.rotationVelocity = -morpher.rotationVelocity;
				
				if ( morpher.stopped ) {
					morpher.stopped = false;
					morpher.update ( 0.1 );
					morpher.stopped = true;
					forceOneClip = true;
				}
			} else if ( kb.keyCode == 39 ) {	// right arrow
				if ( morpher.rotationVelocity < 0 )
					morpher.rotationVelocity = -morpher.rotationVelocity;
				
				if ( morpher.stopped ) {
					morpher.stopped = false;
					morpher.update ( 0.1 );
					morpher.stopped = true;
					forceOneClip = true;
				}
			} else if ( kb.keyCode == 13 )		// enter
				forceOneClip = true;
			else if ( kb.keyCode == 82 ) {
				randomOuputStrokes = !randomOuputStrokes;
				forceOneClip = true;
			} else if ( kb.keyCode == 219 ) {	// "[" key
				subjectFill = subjectFill == PolyFill.EvenOdd ? PolyFill.NonZero : PolyFill.EvenOdd;
				forceOneClip = true;
				trace ( "subjectFill: " + subjectFill );
			} else if ( kb.keyCode == 221 ) {	// "]" key
				clipFill = clipFill == PolyFill.EvenOdd ? PolyFill.NonZero : PolyFill.EvenOdd;
				forceOneClip = true;
				trace ( "clipFill: " + clipFill );
			} else if ( kb.keyCode == 69 ) {	// e
				emphasizeHoles = !emphasizeHoles;
				forceOneClip = true;
			} else if ( kb.keyCode == 84 ) {	// t
				outputSettings.monotoneNoHoleTriangles = !outputSettings.monotoneNoHoleTriangles;
				forceOneClip = true;
			} else if ( kb.keyCode == 68 ) {	// d
				outputSettings.polygons = !outputSettings.polygons;
				forceOneClip = true;
			} else if ( kb.keyCode == 79 ) {	// o
				outputSettings.monotoneNoHolePolygons = !outputSettings.monotoneNoHolePolygons;
				forceOneClip = true;
			}
		} );
	}
	
	private static function rotateClipOperation ():Void {
		switch ( clipOp ) {
		case ClipOperation.Intersection:
			clipOp = ClipOperation.Difference;
		case ClipOperation.Difference:
			clipOp = ClipOperation.Union;
		case ClipOperation.Union:
			clipOp = ClipOperation.Xor;
		default:
			clipOp = ClipOperation.Intersection;
		}
		
		forceOneClip = true;
	}
	
	private static function swapPolyKinds ():Void {
		for ( poly in inputPolys ) {
			poly.kind = poly.kind == PolyKind.Clip ? PolyKind.Subject : PolyKind.Clip;
		}
		
		var tmpFill = subjectFill;
		subjectFill = clipFill;
		clipFill = tmpFill;
		
		trace ( "Swapped poly kinds and fills. subjectFill: " + subjectFill + ", clipFill: " + clipFill );
		forceOneClip = true;
	}
	
	private static function addInputPolygon ( pts:Array <Point>, kind:PolyKind ):Void {
		inputPolys.add ( new InputPolygon ( pts, kind ) );
	}
	
	private static var hideInputPolys:Bool;
	
	private static function drawCurrentStep ( zoom:Float = 1.0 ):Void {
		if ( zoom < 1 )
			zoom = 1;
		
		debugSprite.graphics.clear ();
		
		if ( !hideInputPolys )
			drawInputPolys ( debugSprite.graphics, zoom );
		
		var strokeColor:Null <UInt> = 0;
		var strokeOpacity:Float = 0.5;
		
		if ( randomOuputStrokes ) {
			strokeColor = null;
			strokeOpacity = 0.9;
		}
		
		if ( outputSettings.polygons )
			clipper.drawContributedPolys ( debugSprite.graphics, strokeColor, strokeOpacity, 2 / zoom, 0xaa7700, 0.5, emphasizeHoles );
		
		if ( outputSettings.monotoneNoHolePolygons ) {
			var fillColor:Null <UInt> = 0xaa7700;
			var fillOpacity:Float = 0.5;
			
			if ( randomOuputStrokes ) {
				fillColor = null;
				fillOpacity = 0.9;
				strokeColor = 0;
				strokeOpacity = 0.5;
			}
			
			clipper.drawOutMonos ( debugSprite.graphics, strokeColor, strokeOpacity, 2 / zoom, fillColor, fillOpacity );
		}
		
		if ( outputSettings.monotoneNoHoleTriangles )
			clipper.drawOutTriangles ( debugSprite.graphics, 1 / zoom );
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
			VattiClipper.drawPoly ( inputPoly.pts, graphics, inputPoly.kind == PolyKind.Subject ? subjectFill : clipFill );
		
		VattiClipper.endDrawPoly ( graphics );
		
		VattiClipper.beginDrawPoly ( graphics, 0x777777, 0.7, 1 / zoom, 0x77ddff, 0.5 );
		
		for ( inputPoly in clipPolys )
			VattiClipper.drawPoly ( inputPoly.pts, graphics, inputPoly.kind == PolyKind.Subject ? subjectFill : clipFill );
		
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