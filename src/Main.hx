package ;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.geom.Point;
import flash.Lib;
import geom.PointChain;

/**
 * ...
 * @author vsugrob
 */

class Main {
	static function main () {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// entry point
		
		/*var v0 = new PointChain ( new Point ( 10, 14 ) );
		var v1 = new PointChain ( new Point ( 1988, 1 ), v0 );
		v0.next = v1;
		
		for ( p in v1.reverse () )
			trace ( p );*/
		
		var pts = [new Point ( 1, 1 ), new Point ( 2, 2 ), new Point ( 3, 3 )];
		var pc0 = PointChain.fromIterable ( pts.iterator () );
		pc0.next.insertPrev ( new Point ( 14, 14 ) );
		
		pc0.removeNext ();
		
		for ( p in pc0 )
			trace ( p );
	}
}