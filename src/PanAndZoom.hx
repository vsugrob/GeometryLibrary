package ;
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class PanAndZoom extends EventDispatcher {
	private var zoomFactor:Float;
	private var invZoomFactor:Float;
	
	private var visual:DisplayObject;
	private var origTf:Matrix;
	
	public var zoom:Float;
	
	private var prevMousePos:Point;
	private var dragging:Bool;
	
	public function new ( visual:DisplayObject ) {
		super ();
		
		this.zoomFactor = 1.1;
		this.invZoomFactor = 1.0 / this.zoomFactor;
		
		this.visual = visual;
		this.origTf = visual.transform.matrix.clone ();
		
		this.zoom = 1.0;
		
		this.dragging = false;
		
		attachHandlers ();
	}
	
	private function attachHandlers ():Void {
		visual.stage.addEventListener ( MouseEvent.MOUSE_WHEEL, mouseWheelHandler );
		visual.stage.addEventListener ( MouseEvent.MOUSE_DOWN, startDrag );
		visual.stage.addEventListener ( MouseEvent.MOUSE_MOVE, mouseMoveHandler );
		visual.stage.addEventListener ( MouseEvent.MOUSE_UP, endDrag );
		visual.stage.addEventListener ( MouseEvent.MOUSE_OUT, endDrag );
	}
	
	private function mouseWheelHandler ( e:MouseEvent ):Void {
		var zf = e.delta > 0 ? zoomFactor : invZoomFactor;
		zoom *= zf;
		
		var p = visual.globalToLocal ( new Point ( e.stageX, e.stageY ) );
		p = origTf.transformPoint ( p );
		
		var tf = origTf.clone ();
		tf.translate ( -p.x, -p.y );
		tf.scale ( zoom, zoom );
		tf.translate ( e.stageX, e.stageY );
		
		visual.transform.matrix = tf;
		
		this.dispatchEvent ( new Event ( Event.COMPLETE ) );
	}
	
	private function startDrag ( e:MouseEvent ):Void {
		prevMousePos = new Point ( e.stageX, e.stageY );
		dragging = true;
	}
	
	private function mouseMoveHandler ( e:MouseEvent ):Void {
		if ( dragging ) {
			var mousePos = new Point ( e.stageX, e.stageY );
			
			var tf = visual.transform.matrix;
			tf.translate ( mousePos.x - prevMousePos.x, mousePos.y - prevMousePos.y );
			visual.transform.matrix = tf;
			
			prevMousePos = mousePos;
			
			this.dispatchEvent ( new Event ( Event.COMPLETE ) );
		}
	}
	
	private function endDrag ( e:MouseEvent ):Void {
		dragging = false;
	}
}