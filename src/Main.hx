package ;

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import flash.Lib;
import geom.ChainedPolygon;
import geom.clipper.ClipperState;
import geom.clipper.LocalMaxima;
import geom.clipper.PolyKind;
import geom.clipper.Side;
import geom.clipper.VattiClipper;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class Main {
	static var clipper:VattiClipper;
	static var debugSprite:Sprite;
	static var inputPolys:List <InputPolygon>;
	
	static function main () {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		inputPolys = new List <InputPolygon> ();
		
		/*var subject = [
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
		];*/
		
		/*var subject = [
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
		];*/
		
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
		addInputPolygon ( clip2, PolyKind.Clip );
		
		debugSprite = new Sprite ();
		debugSprite.x = 400;
		debugSprite.y = 25;
		stage.addChild ( debugSprite );
		
		clipper = new VattiClipper ();
		
		for ( inputPoly in inputPolys ) {
			clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
		}
		
		//clipper.drawLml ( debugSprite.graphics );
		//clipper.drawSbl ( debugSprite.graphics, -debugSprite.x, debugSprite.width + debugSprite.x * 2 );
		
		//clipper.clip ();
		//while ( clipper.clipStep () ) {}
		
		//clipper.drawOutPolys ( debugSprite.graphics );
		drawCurrentStep ();
		
		var stepNum = 0;
		
		// Setup stage for clipStep
		stage.addEventListener ( KeyboardEvent.KEY_DOWN, function ( kb:KeyboardEvent ) {
			if ( kb.keyCode == 32 ) {	// Space
				if ( clipper.clipStep () )
					stepNum++;
				
				drawCurrentStep ();
				
				if ( clipper.clipperState == ClipperState.Finished )
					clipper.drawOutPolys ( debugSprite.graphics );
				
				trace ( "clipStep () #" + stepNum + ", next action: " + clipper.clipperState );
			} else if ( kb.keyCode == 49 ) {	// 1
				clipper.drawAelSide ( debugSprite.graphics );
			}
		} );
	}
	
	private static function addInputPolygon ( pts:Array <Point>, kind:PolyKind ):Void {
		pts.push ( pts [0] );
		inputPolys.add ( new InputPolygon ( pts, kind ) );
	}
	
	private static function drawCurrentStep ():Void {
		debugSprite.graphics.clear ();
		
		for ( inputPoly in inputPolys ) {
			var color = inputPoly.kind == PolyKind.Subject ? 0xffdd77 : 0x77ddff;
			VattiClipper.drawPoly ( inputPoly.pts, debugSprite.graphics, 0x777777, 0.7, 1, color, 0.5 );
		}
		
		clipper.drawCurrentScanbeam ( debugSprite.graphics );
		
		clipper.drawContributedPolys ( debugSprite.graphics, 0, 0.5, 2, 0xaa7700, 0.5 );
		clipper.drawAelSide ( debugSprite.graphics );
		clipper.drawIntersections ( debugSprite.graphics );
	}
}