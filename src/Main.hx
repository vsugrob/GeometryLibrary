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
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class Main {
	static var clipper:VattiClipper;
	static var debugSprite:Sprite;
	static var inputPolys:List <InputPolygon>;
	static var panAndZoom:PanAndZoom;
	
	static function main () {
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
		
		// Test: poly with two contributing local maximas
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
		addInputPolygon ( subject, PolyKind.Subject );
		
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
			new Point ( -10, -10 ),
			new Point ( 600, 0 ),
			new Point ( 610, 610 ),
			new Point ( 0, 600 ),
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
			new Point ( -10, -10 ),
			new Point ( 600, 0 ),
			new Point ( 610, 610 ),
			new Point ( 0, 600 ),
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
			new Point ( -10, -10 ),
			new Point ( 600, 0 ),
			new Point ( 610, 610 ),
			new Point ( 0, 600 ),
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
			new Point ( -10, -10 ),
			new Point ( 600, 0 ),
			new Point ( 610, 610 ),
			new Point ( 0, 600 ),
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
		
		/*// Test: many-rooted tooth
		var bgPoly = [
			new Point ( -10, -10 ),
			new Point ( 600, 0 ),
			new Point ( 610, 610 ),
			new Point ( 0, 600 ),
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
			new Point ( -10, -10 ),
			new Point ( 600, 0 ),
			new Point ( 610, 610 ),
			new Point ( 0, 600 ),
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
		
		/*// Last unknown bug with:
		// var dAngle = 1;
		// break on angle >= 21
		
		var angle = 0.0;
		var dAngle = 2;
		
		while ( angle < 45 ) {
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
			
			var center = getPolyCenter ( bgPoly );
			rotatePoly ( bgPoly, angle * Math.PI / 180, center );
			rotatePoly ( clip, angle * Math.PI / 180, center );
			//inputPolys = new List <InputPolygon> ();
			addInputPolygon ( bgPoly, PolyKind.Subject );
			addInputPolygon ( clip, PolyKind.Clip );
			
			clipper = new VattiClipper ();
			
			for ( inputPoly in inputPolys ) {
				clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
			}
			
			try {
				clipper.clip ();
			} catch ( ex:Dynamic ) {
				trace ( 'EXCEPTION. angle: ' + angle + ' dAngle: ' + dAngle );
				trace ( ex );
				
				break;
			}
			
			angle += dAngle;
		}*/
		
		clipper = new VattiClipper ();
		
		for ( inputPoly in inputPolys )
			clipper.addPolygon ( inputPoly.pts, inputPoly.kind );
		
		//clipper.drawLml ( debugSprite.graphics );
		//clipper.drawSbl ( debugSprite.graphics, -debugSprite.x, debugSprite.width + debugSprite.x * 2 );
		
		//clipper.clip ();
		//while ( clipper.clipStep () ) {}
		
		//clipper.drawOutPolys ( debugSprite.graphics );
		drawCurrentStep ( panAndZoom.zoom );
		
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
		} );
	}
	
	private static function addInputPolygon ( pts:Array <Point>, kind:PolyKind ):Void {
		/*var n = 4;
		var m = Math.pow ( 10, n );
		
		for ( p in pts ) {
			p.x = Math.round ( p.x * m ) / m;
			p.y = Math.round ( p.y * m ) / m;
		}*/
		
		pts.push ( pts [0] );
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
	
	private static function rotatePoly ( pts:Iterable <Point>, angle:Float, center:Point = null ):Void {
		var m = new Matrix ();
		
		if ( center == null )
			center = getPolyCenter ( pts );
		
		m.translate ( -center.x, -center.y );
		m.rotate ( angle );
		m.translate ( center.x, center.y );
		
		for ( p in pts ) {
			var rp = m.transformPoint ( p );
			p.x = rp.x;
			p.y = rp.y;
		}
	}
	
	private static function getPolyCenter ( pts:Iterable <Point> ):Point {
		var x:Float = 0;
		var y:Float = 0;
		var num:Int = 0;
		
		for ( p in pts ) {
			x += p.x;
			y += p.y;
			num++;
		}
		
		var invNum:Float = 1 / num;
		
		return	new Point ( x * invNum, y * invNum );
	}
}