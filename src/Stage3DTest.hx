package ;
import flash.display.Stage;
import flash.display3D.Context3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.geom.Matrix3D;
import flash.Vector;
import format.agal.Tools;

/**
 * ...
 * @author vsugrob
 */

class SimpleShader extends format.hxsl.Shader {
	static var SRC = {
		var input : {
			pos : Float2,
			vertexColor : Float3
		};
		
		var color : Float3;
		
		function vertex ( mproj : M44 ) {
			var ppos = pos.xyzw * mproj;
			ppos.x -= 1;
			ppos.y += 1;
			out = ppos;
			color = vertexColor;
		}
		
		function fragment () {
			out = color.xyzw;
		}
	};
}

class Stage3DTest {
	public function new () { }
	
	public static function test ( stage:Stage ):Void {
		var ctx:Context3D = null;
		trace ( 'There are ' + stage.stage3Ds.length + ' stage3Ds available.' );
		var stage3d = stage.stage3Ds [0];
		var viewWidth:Int = 400;
		var viewHeight:Int = 300;
		
		// Create geometry
		var vertexData = new Vector <Float> ();
		var vertexComponents:Int = 5;
		
		var pushVertex = function ( x, y, r, g, b ):Void {
			vertexData.push ( x ); vertexData.push ( y );
			vertexData.push ( r ); vertexData.push ( g ); vertexData.push ( b );
		};
		
		pushVertex ( 0, 0, 0.7, 0.5, 0.0 );
		pushVertex ( 400, 200, 0.5, 0.7, 0.0 );
		pushVertex ( 150, 300, 0.0, 0.5, 0.7 );
		
		var numVertices:Int = cast ( vertexData.length / vertexComponents );
		
		var indices = new Vector <UInt> ();
		indices.push ( 0 );
		indices.push ( 1 );
		indices.push ( 2 );
		
		var vb:VertexBuffer3D = null;
		var ib:IndexBuffer3D = null;
		var far = 100.0;
		var near = 0.0;
		
		// Matrix cells
		var mcs = new Vector <Float> ( 16, true );
		mcs [0] = 2 / viewWidth;
		mcs [5] = -2 / viewHeight;
		mcs [10] = 0;
		mcs [15] = 1;
		
		var projMatrix = new Matrix3D ( mcs );
		var shader:SimpleShader = null;
		
		var render = function () {
			//ctx.clear ( 1, 1, 1 );
			ctx.clear ();
			
			shader.init ( { mproj : projMatrix }, { } );
			shader.draw ( vb, ib );
			
			ctx.present ();
		};
		
		stage3d.addEventListener ( Event.CONTEXT3D_CREATE, function ( e:Event ) {
			ctx = stage3d.context3D;
			trace ( 'Context3D created. Driver: ' + ctx.driverInfo );
			
			ctx.configureBackBuffer ( viewWidth, viewHeight, 4, false );
			
			vb = ctx.createVertexBuffer ( numVertices, vertexComponents );
			vb.uploadFromVector ( vertexData, 0, numVertices );
			
			ib = ctx.createIndexBuffer ( indices.length );
			ib.uploadFromVector ( indices, 0, indices.length );
			
			shader = new SimpleShader ( ctx );
			
			render ();
		} );
		
		stage3d.addEventListener ( ErrorEvent.ERROR, function ( e:ErrorEvent ) {
			trace ( 'Error during requestContext3D (): ' + e );
		} );
		
		stage3d.requestContext3D ();
	}
}