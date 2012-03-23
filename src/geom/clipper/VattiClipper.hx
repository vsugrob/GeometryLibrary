package geom.clipper;
import flash.display.Graphics;
import flash.geom.Point;

/**
 * ...
 * @author vsugrob
 */

class VattiClipper {
	/**
	 * Pointer to first node of the signle-linked list of local maximas.
	 */
	private var lml:LocalMaxima;
	
	public function new () { }
	
	/**
	 * @param	subject	Iterable of Point where last point coincide to first point.
	 * @param	clip	Iterable of Point where last point coincide to first point.
	 */
	public function clip ( subject:Iterable <Point>, clip:Iterable <Point> ):Void {
		initLmlAndSbl ( subject, PolyKind.Subject );
		//initLmlAndSbl ( clip, PolyKind.Clip );
	}
	
	private function initLmlAndSbl ( pts:Iterable <Point>, polyKind:PolyKind ):Void {
		var it:Iterator <Point> = pts.iterator ();
		
		if ( !it.hasNext () )
			return;
		
		var p0:Point = it.next ();
		var prevEdge:Edge = null;
		var firstEdge:Edge = null;
		var prevDy:Float = 0;
		var lastJointIsLocalMimima:Bool = false;
		var firstJointIsLocalMimima:Null <Bool> = null;
		
		while ( it.hasNext () ) {
			var p1:Point = it.next ();
			
			var dy = p1.y - p0.y;
			var dx = p1.x - p0.x;
			var edge:Edge;
			
			if ( dy == 0 ) {
				if ( prevDy > 0 )
					edge = new Edge ( p1.x, p0.y, -dx, polyKind );
				else
					edge = new Edge ( p0.x, p0.y, dx, polyKind );
				
				/* prevDy == 0 is a special case. It doesn't mean that 
				 * previous edge was horizontal as well as curent edge (which is
				 * impossible because of the collinear edge removal stage that
				 * must precede clipping). It just mean that this is the first edge
				 * being processed so we handle its orientation later when we connect
				 * first and last edge. */
				
				edge.isHorizontal = true;
			} else if ( dy > 0 )
				edge = new Edge ( p1.x, p0.y, dx / dy, polyKind );
			else
				edge = new Edge ( p0.x, p1.y, dx / dy, polyKind );
			
			if ( prevEdge != null ) {
				lastJointIsLocalMimima = false;
				
				if ( dy * prevDy >= 0 ) {	// Monotonicity preserved
					if ( dy == 0 ) {
						if ( prevDy > 0 )
							edge.successor = prevEdge;
						else
							prevEdge.successor = edge;
					} else if ( dy > 0 )
						edge.successor = prevEdge;
					else
						prevEdge.successor = edge;
				} else if ( prevDy > 0 && dy < 0 )	// We got local maxima
					addLocalMaximum ( prevEdge, edge, p0.y );
				else {								// We got local minima
					lastJointIsLocalMimima = true;
					
					if ( firstJointIsLocalMimima == null )
						firstJointIsLocalMimima = true;
				}
				
				if ( firstJointIsLocalMimima == null )
					firstJointIsLocalMimima = false;
			} else
				firstEdge = edge;
			
			prevEdge = edge;
			
			if ( dy != 0 )
				prevDy = dy;
			
			p0 = p1;
		}
		
		/* Now process first and last edge. This is necessary because in previous loop they
		 * weren't processed in pair so they could be not connected appropriately or we might have
		 * missed local maximum settled in the first vertex. Also first or last edge might be
		 * horizontal with wrong orientation which must be fixed.
		 * Following cases illustrated in document "/doc/initLmlAndSbl connect first and last edge cases.svg"
		 * and code refers to illustrations using comments in form [Case #].*/
		if ( firstEdge != null ) {	// It may be null if pts contains only one point
			/* Note that at this point prevEdge contains last edge
			 * and p0 coincides with first point of the polygon. */
			
			if ( firstEdge.successor == null ) {
				if ( prevEdge.successor == null ) {
					if ( firstJointIsLocalMimima ) {
						if ( lastJointIsLocalMimima )
							addLocalMaximum ( prevEdge, firstEdge, p0.y );	// [Case 1]
						else
							prevEdge.successor = firstEdge;	// [Case 2]
					} else if ( lastJointIsLocalMimima ) {
						firstEdge.successor = prevEdge;	// [Case 3]
						
						if ( firstEdge.isHorizontal )
							reverseHorizontalEdge ( firstEdge );	// [Case 3 subcase]
					} else {
						if ( firstEdge.isHorizontal )
							reverseHorizontalEdge ( firstEdge );	// [Case 4 subcase]
						else {
							// [Case 4]
						}
					}
				} else {
					if ( firstJointIsLocalMimima ) {
						addLocalMaximum ( prevEdge, firstEdge, p0.y );	// [Case 5]
						
						if ( prevEdge.isHorizontal )
							reverseHorizontalEdge ( prevEdge );	// [Case 5 subcase]
					} else {
						firstEdge.successor = prevEdge;	// [Case 6]
						
						if ( firstEdge.isHorizontal )
							reverseHorizontalEdge ( firstEdge );	// [Case 6 subcase]
					}
				}
			} else {
				if ( prevEdge.successor == null ) {
					if ( lastJointIsLocalMimima )
						addLocalMaximum ( prevEdge, firstEdge, p0.y );	// [Case 7]
					else
						prevEdge.successor = firstEdge;	// [Case 8]
				} else	// Local maximum
					addLocalMaximum ( prevEdge, firstEdge, p0.y );	// [Case 9]
			}
		}
	}
	
	private inline function addLocalMaximum ( edge1:Edge, edge2:Edge, y:Float ):Void {
		var lm = new LocalMaxima ( edge1, edge2, y );
		
		if ( lml == null )
			lml = lm;
		else {
			lml.insert ( lm );
			
			if ( lm.y >= lml.y )
				lml = lm;
		}
	}
	
	private inline function reverseHorizontalEdge ( edge:Edge ):Void {
		edge.bottomX += edge.dx;
		edge.dx = -edge.dx;
	}
	
	private static function getRandomColor ():UInt {
		return	( Std.int ( Math.random () * 0x80 + 0x5f ) << 16 ) |
			( Std.int ( Math.random () * 0x80 + 0x5f ) << 8 ) |
			( Std.int ( Math.random () * 0x80 + 0x5f ) );
	}
	
	public function drawLml ( graphics:Graphics ):Void {
		var lm = lml;
		
		do {
			drawBound ( graphics, lm.edge1, lm.y );
			drawBound ( graphics, lm.edge2, lm.y );
			
			graphics.lineStyle ();
			graphics.beginFill ( 0x00ff00 );
			graphics.drawCircle ( lm.edge1.bottomX, lm.y, 2 );
			graphics.endFill ();
			
			lm = lm.next;
		} while ( lm != null );
	}
	
	private function drawBound ( graphics:Graphics, edge:Edge, startY:Float ):Void {
		graphics.lineStyle ( 2, getRandomColor () );
		var bottomX = edge.bottomX;
		
		do {
			var dy = edge.topY - startY;
			
			if ( dy == 0 )
				dy = 1;
			
			var topX = edge.bottomX + edge.dx * dy;
			
			graphics.moveTo ( bottomX, startY );
			graphics.lineTo ( topX, edge.topY );
			
			bottomX = topX;
			startY = edge.topY;
			edge = edge.successor;
		} while ( edge != null );
	}
}