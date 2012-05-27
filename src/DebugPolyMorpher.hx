package ;
import flash.geom.Matrix;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class DebugPolyMorpher {
	private var rotVel:Float;
	private var inputPolys:List <InputPolygon>;
	private var center:Point;
	public var stopped:Bool;
	
	public function new ( inputPolys:List <InputPolygon>, rotationVelocity:Float = 90.0 ) {
		this.inputPolys = inputPolys;
		this.rotVel = rotationVelocity * Math.PI / 180.0;
		this.center = getPolyCenter ( inputPolys.first ().pts );
	}
	
	public function update ( dt:Float ) {
		if ( stopped )
			return;
		
		var da:Float = dt * rotVel;
		var it = inputPolys.iterator ();
		it.next ();
		
		for ( poly in it ) {
			rotatePoly ( poly.pts, da, center );
		}
	}
	
	public static function getPolyCenter ( pts:Iterable <Point> ):Point {
		var x:Float = 0;
		var y:Float = 0;
		var num:Int = 0;
		
		for ( p in pts ) {
			x += p.x;
			y += p.y;
			num++;
		}
		
		var invNum:Float = 1.0 / num;
		
		return	new Point ( x * invNum, y * invNum );
	}
	
	public static function rotatePoly ( pts:Iterable <Point>, angle:Float, center:Point = null ):Void {
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
	
	public static function roundPolyCoords ( pts:Iterable <Point>, numDecimalPlaces:Int = 0 ):Void {
		var mul:Float = Math.pow ( 10, numDecimalPlaces );
		
		for ( p in pts ) {
			p.x = Math.round ( p.x * mul );
			p.y = Math.round ( p.y * mul );
		}
	}
	
	public static function genRandomPoly ( numPoints:UInt = 100, minCoord:Float = -1e6, maxCoord:Float = 1e6 ):Array <Point> {
		var pts = new Array <Point> ();
		var rndSpan = maxCoord - minCoord;
		
		for ( i in 1...numPoints ) {
			var p = new Point (
				Math.random () * rndSpan + minCoord,
				Math.random () * rndSpan + minCoord
			);
			
			pts.push ( p );
		}
		
		return	pts;
	}
}