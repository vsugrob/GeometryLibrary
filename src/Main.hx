package ;

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.geom.Point;
import flash.Lib;
import geom.clipper.LocalMaxima;
import geom.clipper.Side;
import geom.clipper.VattiClipper;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class Main {
	static function main () {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
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
			new Point ( 200, 200 ),
			new Point ( 100, 0 )
		];
		
		var clip = [
			new Point ( 100, 300 ),
			new Point ( 200, 290 ),
			new Point ( 100, 100 ),
			new Point ( 200, 200 ),
		];
		
		subject.push ( subject [0] );
		clip.push ( clip [0] );
		
		var clipper = new VattiClipper ();
		clipper.clip ( subject, clip );
		
		var debugSprite = new Sprite ();
		debugSprite.x = 50;
		debugSprite.y = 50;
		stage.addChild ( debugSprite );
		
		clipper.drawLml ( debugSprite.graphics );
		clipper.drawSbl ( debugSprite.graphics, -debugSprite.x, debugSprite.width + debugSprite.x * 2 );
		
		VattiClipper.drawPoly ( subject, debugSprite.graphics, 0x777777, 0.7, 1, 0xffdd77, 0.5 );
		VattiClipper.drawPoly ( clip, debugSprite.graphics, 0x777777, 0.7, 1, 0x77ddff, 0.5 );
		clipper.drawOutPolys ( debugSprite.graphics );
	}
}