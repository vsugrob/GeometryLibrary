package geom.clipper;
import flash.display.Graphics;
import flash.geom.Point;
import geom.ConcatIterator;

/**
 * ...
 * @author vsugrob
 */

class PolyBounds {
	/**
	 * Pointer to first node of the singly-linked list of local maximas.
	 */
	public var lml:LocalMaxima;
	
	public function new ( poly:Iterable <Point> = null, kind:PolyKind = null ) {
		if ( poly != null ) {
			if ( kind == null )
				kind = PolyKind.Subject;
			
			initLml ( poly, kind );
		}
	}
	
	/**
	 * 
	 * @param	poly	Iterable of Point.
	 * @param	kind	Whether this poly is one that will be clipped (PolyKind.Subject) or that which
	 * will clip (PolyKind.Clip).
	 * @warning	Currently clipper accepts any kind of polygon. The only restriction is that coordinates
	 * cannot be NaN or +/-Infinity, it this case result is unpredictable and exceptions are possible.
	 * TODO: make promise-like system attached to polygon geometrical characteristics as it was implemented
	 * in previous developments of geometry library.
	 * Also remember about restriction when dx or dy is infinite.
	 */
	public function addPolygon ( poly:Iterable <Point>, kind:PolyKind ):Void {
		initLml ( poly, kind );
	}
	
	public function addPolyBounds ( polyBounds:PolyBounds ):Void {
		var lm = polyBounds.lml;
		
		while ( lm != null ) {
			addLocalMaxima ( lm.edge1, lm.edge2, lm.y, lm.kind );
			
			lm = lm.next;
		}
	}
	
	public function clear ():Void {
		lml = null;
	}
	
	private function initLml ( pts:Iterable <Point>, kind:PolyKind ):Void {
		var it:Iterator <Point> = pts.iterator ();
		
		if ( !it.hasNext () )
			return;
		
		var p0:Point = it.next ();
		var p1:Point = null;
		var extrIdx:UInt = 0;	// Extremum vertex index
		var extrFound = false;	// Whether extemum was found during scan?
		var prevDy:Float = 0;	// Previous non-zero delta y
		var dx:Float = 0, dy:Float = 0;
		var k:Float = 0;
		
		// Seek for first extremum vertex index
		while ( it.hasNext () ) {
			p1 = it.next ();
			dy = p1.y - p0.y;
			
			if ( dy != 0 ) {
				dx = p1.x - p0.x;
				k = dx / dy;
				
				if ( !Math.isFinite ( k ) ) {	// Then edge is indistinguishable from horizontal
					// p0.y and p1.y slightly differs, fix it.
					p0 = new Point ( p1.x, p0.y );
					extrIdx++;
					
					continue;
				}
			} else /*if ( dy == 0 )*/ {
				p0 = p1;
				extrIdx++;
				
				continue;
			}
			
			if ( prevDy * dy < 0 ) {
				extrFound = true;
				
				break;
			}
			
			if ( dy != 0 )
				prevDy = dy;
			
			p0 = p1;
			extrIdx++;
		}
		
		var prevEdge:Edge = null;
		var firstEdge:Edge = null;
		var lastEdge:Edge = null;
		
		if ( extrIdx == 0 )			// 1-point polygon or polygon with all its points coincident
			return;
		else if ( !extrFound ) {	// Monotone polyline
			it = pts.iterator ();
			p0 = it.next ();
			var pFirst = p0;
			var isIncreasing = prevDy > 0;	// When prevDy == 0 it means that all edges of polygon are horizontal
			var prePrevEdge:Edge = null;	// In case when lastEdge is zero-length.
			
			while ( it.hasNext () ) {
				p1 = it.next ();
				
				dy = p1.y - p0.y;
				dx = p1.x - p0.x;
				var edge:Edge;
				
				if ( dy != 0 ) {
					k = dx / dy;
					
					if ( !Math.isFinite ( k ) ) {	// Then edge is indistinguishable from horizontal
						dy = 0;
						
						// p0.y and p1.y slightly differs, fix it.
						p1 = new Point ( p1.x, p0.y );
					}
				} else if ( dx == 0 /*&& dy == 0*/ ) {	// Skip zero-length edge
					continue;
				}
				
				if ( dy == 0 ) {
					if ( isIncreasing )
						edge = new Edge ( p1.x, p0.y, -dx );
					else
						edge = new Edge ( p0.x, p0.y, dx );
					
					edge.isHorizontal = true;
				} else if ( isIncreasing )
					edge = new Edge ( p1.x, p0.y, k );
				else
					edge = new Edge ( p0.x, p1.y, k );
				
				if ( prevEdge != null ) {
					if ( isIncreasing )
						edge.successor = prevEdge;
					else
						prevEdge.successor = edge;
				} else
					firstEdge = edge;
				
				prePrevEdge = prevEdge;
				prevEdge = edge;
				p0 = p1;
			}
			
			var pLast = p1;
			
			if ( prevDy == 0 ) {
				// Then last edge is horizontal as well as others, but unlike others is increasing.
				dx = pLast.x - pFirst.x;
				
				if ( dx == 0 ) {	// Last edge is zero-length
					lastEdge = prevEdge;
					pLast.x = lastEdge.bottomX;
					reverseHorizontalEdge ( lastEdge );
					prevEdge = prePrevEdge;
				} else {
					lastEdge = new Edge ( pFirst.x, pFirst.y, dx );
					lastEdge.isHorizontal = true;
				}
			} else {
				// Last edge cannot be neither horizontal nor zero-length
				k = ( pLast.x - pFirst.x ) / ( pLast.y - pFirst.y );
				
				if ( isIncreasing )	// Then the last edge is decreasing
					lastEdge = new Edge ( pLast.x, pFirst.y, k );
				else
					lastEdge = new Edge ( pFirst.x, pLast.y, k );
			}
			
			// Add local minima and local maxima
			if ( isIncreasing ) {
				// prevEdge : increasing, lastEdge : decreasing, firstEdge : increasing
				addLocalMaxima ( prevEdge, lastEdge, pLast.y, kind );
				addLocalMinima ( firstEdge, lastEdge, pFirst.x, pFirst.y );
			} else {
				// prevEdge : decreasing, lastEdge : increasing, firstEdge : decreasing
				addLocalMaxima ( lastEdge, firstEdge, pFirst.y, kind );
				addLocalMinima ( lastEdge, prevEdge, pLast.x, pLast.y );
			}
		} else {	// Ordinary polygon
			/* At this point iterator must be stopped on p1,
			 * prevDy must have sign opposite to dy.
			 * Also dx and k are set appropriately. */
			
			it = new ConcatIterator ( it, new TakeIterator ( pts.iterator (), extrIdx + 1 ) );
			
			prevDy = 0;
			var lastJointIsLocalMimima:Bool = false;
			var firstJointIsLocalMimima:Null <Bool> = null;
			
			while ( true ) {
				var edge:Edge;
				
				if ( dy == 0 ) {
					if ( prevDy > 0 )
						edge = new Edge ( p1.x, p0.y, -dx );
					else
						edge = new Edge ( p0.x, p0.y, dx );
					
					/* prevDy == 0 is a special case. It doesn't mean that 
					 * previous edge was horizontal as well as curent edge. It just means
					 * that this is the first edge being processed so we handle its
					 * orientation later when we connect first and last edge. */
					
					edge.isHorizontal = true;
				} else if ( dy > 0 )
					edge = new Edge ( p1.x, p0.y, k );
				else
					edge = new Edge ( p0.x, p1.y, k );
				
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
					} else if ( prevDy > 0 && dy < 0 )		// We got local maxima
						addLocalMaxima ( prevEdge, edge, p0.y, kind );
					else /*if ( prevDy < 0 && dy > 0 )*/ {	// We got local minima
						lastJointIsLocalMimima = true;
						
						if ( firstJointIsLocalMimima == null )
							firstJointIsLocalMimima = true;
						
						addLocalMinima ( edge, prevEdge, p0.x, p0.y );
					}
					
					if ( firstJointIsLocalMimima == null )
						firstJointIsLocalMimima = false;
				} else
					firstEdge = edge;
				
				prevEdge = edge;
				
				if ( dy != 0 )
					prevDy = dy;
				
				p0 = p1;
				
				if ( !it.hasNext () )
					break;
				
				do {
					p1 = it.next ();
					
					dy = p1.y - p0.y;
					dx = p1.x - p0.x;
					
					if ( dy != 0 ) {
						k = dx / dy;
						
						if ( !Math.isFinite ( k ) ) {
							dy = 0;
							
							// p0.y and p1.y slightly differs, fix it.
							p1 = new Point ( p1.x, p0.y );
						}
						
						// Edge is definitely not zero-length so we may proceed with it.
						break;
					}
					
					// Repeat while [p0;p1] is zero-length edge.
				} while ( dx == 0 /*&& dy == 0*/ && it.hasNext () );
			}
			
			/* Now process first and last edge. This is necessary because in previous loop they
			 * weren't processed in pair so they could be not connected appropriately or we might have
			 * missed local extremum settled in the first vertex. Also first or last edge might be
			 * horizontal with wrong orientation which must be fixed.
			 * Following cases illustrated in document "/doc/initLmlAndSbl connect first and last edge cases.svg".
			 * Code refers to illustrations using comments in form [Case #].*/
			
			/* firstEdge may not be null because it was only possible in 1-point polygon.*/
			/* Note that at this point prevEdge contains last edge
			 * and p0 coincides with first point of the polygon. */
			lastEdge = prevEdge;
			
			if ( firstEdge.successor == null ) {
				if ( lastEdge.successor == null ) {
					if ( firstJointIsLocalMimima ) {
						if ( lastJointIsLocalMimima )
							addLocalMaxima ( lastEdge, firstEdge, p0.y, kind );	// [Case 1]
						else
							lastEdge.successor = firstEdge;	// [Case 2]
					} else if ( lastJointIsLocalMimima ) {
						firstEdge.successor = lastEdge;	// [Case 3]
						
						if ( firstEdge.isHorizontal )
							reverseHorizontalEdge ( firstEdge );	// [Case 3 subcase]
					} else {
						if ( firstEdge.isHorizontal )
							reverseHorizontalEdge ( firstEdge );	// [Case 4 subcase]
						else {
							// Pure local minimum, [Case 4]
						}
						
						addLocalMinima ( firstEdge, lastEdge, p0.x, p0.y );
					}
				} else {
					if ( firstJointIsLocalMimima ) {
						addLocalMaxima ( lastEdge, firstEdge, p0.y, kind );	// [Case 5]
						
						if ( lastEdge.isHorizontal )
							reverseHorizontalEdge ( lastEdge );	// [Case 5 subcase]
					} else {
						firstEdge.successor = lastEdge;	// [Case 6]
						
						if ( firstEdge.isHorizontal )
							reverseHorizontalEdge ( firstEdge );	// [Case 6 subcase]
					}
				}
			} else {
				if ( lastEdge.successor == null ) {
					if ( lastJointIsLocalMimima )
						addLocalMaxima ( lastEdge, firstEdge, p0.y, kind );	// [Case 7]
					else
						lastEdge.successor = firstEdge;	// [Case 8]
				} else	// Local maximum
					addLocalMaxima ( lastEdge, firstEdge, p0.y, kind );	// [Case 9]
			}
		}
	}
	
	/**
	 * Creates "point of divergence".
	 * @param	edge1	Must be an Edge instance created from vertically increasing polygon edge.
	 * @param	edge2	Must be an Edge instance created from vertically decreasing polygon edge.
	 * @param	y	Y-coordinate of the point common for both edges.
	 * @param	kind	Whether edges are clip or subject?
	 */
	public inline function addLocalMaxima ( edge1:Edge, edge2:Edge, y:Float, kind:PolyKind ):Void {
		var lm = new LocalMaxima ( edge1, edge2, y, kind );
		
		if ( lml == null )
			lml = lm;
		else {
			lml.insert ( lm );
			
			if ( lm.y >= lml.y )
				lml = lm;
		}
	}
	
	/**
	 * Joins edge with LocalMinima instance and sets it to their successor property.
	 * @param	edge1	Must be an Edge instance created from vertically increasing polygon edge.
	 * @param	edge2	Must be an Edge instance created from vertically decreasing polygon edge.
	 * @param	x	X-coordinate of the join point.
	 * @param	y	Y-coordinate of the join point.
	 */
	public inline function addLocalMinima ( edge1:Edge, edge2:Edge, x:Float, y:Float ):Void {
		var lMin = new LocalMinima ( x, y, edge1, edge2 );
		edge1.successor = lMin;
		edge2.successor = lMin;
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
	
	public function drawLml ( graphics:Graphics, zoom:Float ):Void {
		var lm = lml;
		
		while ( lm != null ) {
			drawBound ( graphics, lm.edge1, lm.y, zoom );
			drawBound ( graphics, lm.edge2, lm.y, zoom );
			
			graphics.lineStyle ();
			graphics.beginFill ( 0x00ff00 );
			graphics.drawCircle ( lm.edge1.bottomX, lm.y, 2 / zoom );
			graphics.endFill ();
			
			lm = lm.next;
		}
	}
	
	private function drawBound ( graphics:Graphics, edge:Edge, startY:Float, zoom:Float ):Void {
		graphics.lineStyle ( 2 / zoom, getRandomColor () );
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
		} while ( !edge.isLocalMinima () );
	}
}