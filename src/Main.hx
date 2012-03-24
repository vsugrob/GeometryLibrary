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
		
		/*var v0 = new DoublyList <Point> ( new Point ( 10, 14 ) );
		var v1 = new DoublyList <Point> ( new Point ( 1988, 1 ), v0 );
		v0.next = v1;
		
		for ( p in v1.reverse () )
			trace ( p );*/
		
		
		/*var pts = [new Point ( 1, 1 ), new Point ( 2, 2 ), new Point ( 3, 3 )];
		var pc0 = DoublyList.fromIterable ( pts.iterator () );
		pc0.next.insertPrev ( new Point ( 14, 14 ) );
		
		pc0.removeNext ();
		
		for ( p in pc0 )
			trace ( p );*/
		
		
		/*var pts = [new Point ( 1, 1 ), new Point ( 2, 2 ), new Point ( 3, 3 )];
		var pc0 = DoublyList.fromIterable ( pts.iterator () );
		
		trace ( "]Chain:" );
		
		for ( p in pc0 )
			trace ( p );
		
		trace ( "]First:" );
		trace ( pc0.first () );
		
		trace ( "]Last:" );
		trace ( pc0.last () );*/
		
		
		/*var lm0:LocalMaxima = new LocalMaxima ( null, null, 10 );
		var lm1:LocalMaxima = new LocalMaxima ( null, null, 9 );
		var lm2:LocalMaxima = new LocalMaxima ( null, null, 7 );
		var lm3:LocalMaxima = new LocalMaxima ( null, null, 8 );
		var lm4:LocalMaxima = new LocalMaxima ( null, null, 12 );
		lm0.insert ( lm1 );
		lm0.insert ( lm2 );
		lm0.insert ( lm3 );
		lm0.insert ( lm4 );*/
		
		
		/*var subject = [
			new Point ( 0, 50 ),
			new Point ( 50, 100 ),
			new Point ( 100, 50 ),
			new Point ( 50, 0 )
		];
		
		subject.push ( subject.shift () );
		subject.push ( subject.shift () );*/
		
		/*var subject = [
			new Point ( 0, 50 ),
			new Point ( 50, 100 ),
			new Point ( 100, 50 ),
			new Point ( 150, 100 ),
			new Point ( 200, 50 ),
			new Point ( 100, 0 )
		];*/
		
		/*var subject = [
			new Point ( 0, 0 ),
			new Point ( 100, 0 ),
			new Point ( 100, 100 ),
			new Point ( 0, 100 )
		];
		
		subject.push ( subject.shift () );
		subject.push ( subject.shift () );
		subject.push ( subject.shift () );*/
		
		/*var subject = [
			new Point ( 0, 50 ),
			new Point ( 50, 25 ),
			new Point ( 100, 50 ),
			new Point ( 50, 0 )
		];*/
		
		var subject = [
			new Point ( 50, 50 ),
			new Point ( 100, 0 ),
			new Point ( 0, 0 ),
		];
		
		subject.push ( subject [0] );
		
		var clipper = new VattiClipper ();
		clipper.clip ( subject, null );
		
		var debugSprite = new Sprite ();
		debugSprite.x = 50;
		debugSprite.y = 50;
		stage.addChild ( debugSprite );
		
		clipper.drawLml ( debugSprite.graphics );
		clipper.drawSbl ( debugSprite.graphics, -debugSprite.x, debugSprite.width + debugSprite.x * 2 );
	}
}