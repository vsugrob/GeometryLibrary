package geom.clipper;
import flash.display.Graphics;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.DoublyList;

/**
 * ...
 * @author vsugrob
 */

class VattiClipper {
	/**
	 * Pointer to first node of the singly-linked list of local maximas.
	 */
	private var lml:LocalMaxima;
	/**
	 * Pointer to first node of the singly-linked list of scanbeams.
	 */
	private var sbl:Scanbeam;
	/**
	 * Pointer to first node of the doubly-linked list of active edges i.e.
	 * non-horizontal edges that intersected by current scanbeam.
	 */
	private var ael:DoublyList <Edge>;
	/**
	 * List of polygons being formed during clipping operation.
	 */
	private var outPolys:List <ChainedPolygon>;
	
	public function new () {
		this.outPolys = new List <ChainedPolygon> ();
	}
	
	/**
	 * @param	subject	Iterable of Point where last point coincide to first point.
	 * @param	clip	Iterable of Point where last point coincide to first point.
	 */
	public function clip ( subject:Iterable <Point>, clip:Iterable <Point> ):Void {
		initLmlAndSbl ( subject, PolyKind.Subject );
		initLmlAndSbl ( clip, PolyKind.Clip );
		
		if ( sbl == null )	// Scanbeam list is empty
			return;
		
		var yb = popScanbeam ();	// Bottom of current scanbeam
		
		do {
			addNewBoundPairs ( yb );	// Modifies ael
			
			var yt = popScanbeam ();	// Top of current scan beam
			
			processIntersections ( yb, yt );
			processEdgesInAel ( yb, yt );
			
			yb = yt;
		} while ( sbl != null );
	}
	
	private function initLmlAndSbl ( pts:Iterable <Point>, polyKind:PolyKind ):Void {
		var it:Iterator <Point> = pts.iterator ();
		
		if ( !it.hasNext () )
			return;
		
		var p0:Point = it.next ();
		var prevEdge:Edge = null;
		var firstEdge:Edge = null;
		var prevDy:Float = 0;	// Previous non-zero delta y
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
					addLocalMaxima ( prevEdge, edge, p0.y );
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
			var lastEdge:Edge = prevEdge;
			
			if ( firstEdge.successor == null ) {
				if ( lastEdge.successor == null ) {
					if ( firstJointIsLocalMimima ) {
						if ( lastJointIsLocalMimima )
							addLocalMaxima ( lastEdge, firstEdge, p0.y );	// [Case 1]
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
					}
				} else {
					if ( firstJointIsLocalMimima ) {
						addLocalMaxima ( lastEdge, firstEdge, p0.y );	// [Case 5]
						
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
						addLocalMaxima ( lastEdge, firstEdge, p0.y );	// [Case 7]
					else
						lastEdge.successor = firstEdge;	// [Case 8]
				} else	// Local maximum
					addLocalMaxima ( lastEdge, firstEdge, p0.y );	// [Case 9]
			}
		}
	}
	
	private inline function addLocalMaxima ( edge1:Edge, edge2:Edge, y:Float ):Void {
		var lm = new LocalMaxima ( edge1, edge2, y );
		
		if ( lml == null )
			lml = lm;
		else {
			lml.insert ( lm );
			
			if ( lm.y >= lml.y )
				lml = lm;
		}
		
		addScanbeam ( y );
		addScanbeam ( edge1.topY );
		addScanbeam ( edge2.topY );
	}
	
	private inline function addScanbeam ( y:Float ):Void {
		var sb = new Scanbeam ( y );
		
		if ( sbl == null )
			sbl = sb;
		else {
			sbl.insert ( sb );
			
			if ( sb.y > sbl.y )
				sbl = sb;
		}
	}
	
	private inline function popScanbeam ():Float {
		var sb = sbl;
		sbl = sbl.next;
		sb.next = null;
		
		return	sb.y;
	}
	
	private inline function reverseHorizontalEdge ( edge:Edge ):Void {
		edge.bottomX += edge.dx;
		edge.dx = -edge.dx;
	}
	
	private function addNewBoundPairs ( yb:Float ):Void {
		while ( lml != null && lml.y == yb ) {
			addEdgesToAel ( lml.edge1, lml.edge2, yb );
			
			// Delete bound pair from lml
			var lm = lml;
			lml = lml.next;
			lm.next = null;
		}
	}
	
	/**
	 * Add edges edge1 and edge2 (or their nonhorizontal successors) to active edge list maintaining increasing x order.
	 * Also set side and contributing fields of edge1 and edge2 using a parity argument.
	 * @param	edge1
	 * @param	edge2
	 * @param	yb
	 */
	private function addEdgesToAel ( edge1:Edge, edge2:Edge, yb:Float ):Void {
		var p:Point = new Point ( edge1.bottomX, yb );
		var likeEdgesEven = numLeftAelNodesEven ( p.x, edge1.kind );	// Number of edges in ael to the left of
																		// local maxima (of the same kind) is even or odd?
		var cmp:Bool;					// Edges x-coordinate comparison
		
		// Remember that both edges can't be horizontal simultaneously
		if ( edge1.isHorizontal ) {
			cmp = edge1.successor.bottomX < edge2.bottomX;
			edge1 = edge1.successor;
		} else if ( edge2.isHorizontal ) {
			cmp = edge1.bottomX > edge2.successor.bottomX;
			edge2 = edge2.successor;
		} else {
			cmp = edge1.dx > edge2.dx;
		}
		
		if ( cmp == likeEdgesEven ) {
			edge1.side = Side.Left;
			edge2.side = Side.Right;
		} else {
			edge1.side = Side.Right;
			edge2.side = Side.Left;
		}
		
		if ( !cmp ) {
			var tmp = edge1;
			edge1 = edge2;
			edge2 = tmp;
		}
		
		var aelNode1:DoublyList <Edge>, aelNode2:DoublyList <Edge>;
		
		if ( ael == null )
			aelNode1 = ael = new DoublyList <Edge> ( edge1 );
		else
			aelNode1 = addActiveEdge ( ael, edge1 );
		
		aelNode2 = addActiveEdge ( aelNode1, edge2 );
		
		initEdgeContributingStatus ( aelNode1 );
		initEdgeContributingStatus ( aelNode2 );
		
		if ( edge1.contributing && edge1.contributing )
			addLocalMax ( edge1, edge2, p );
	}
	
	private inline function initEdgeContributingStatus ( aelNode:DoublyList <Edge> ):Void {
		var i = 0;
		var kind:PolyKind = aelNode.value.kind;
		var startNode = aelNode;
		aelNode = aelNode.prev;
		
		while ( aelNode != null ) {
			if ( aelNode.value.kind != kind )
				i++;
			
			aelNode = aelNode.prev;
		}
		
		startNode.value.contributing = i % 2 == 1;
	}
	
	private inline function numLeftAelNodesEven ( x:Float, kind:PolyKind ):Bool {
		var i:Int = 0;
		var aelNode = ael;
		
		while ( aelNode != null && aelNode.value.bottomX < x ) {
			if ( aelNode.value.kind == kind )
				i++;
			
			aelNode = aelNode.next;
		}
		
		return	i % 2 == 0;
	}
	
	/**
	 * Insert an edge into active edge list after aelNode maintaining x-order.
	 * @param	node	Origin node.
	 * @param	edge	An edge being inserted.
	 * @return	Newly generated node that holds reference to an edge.
	 */
	private inline function addActiveEdge ( aelNode:DoublyList <Edge>, edge:Edge ):DoublyList <Edge> {
		var newNode:DoublyList <Edge> = null;
		
		if ( edge.bottomX < aelNode.value.bottomX ) {
			aelNode.insertPrev ( edge );
			newNode = aelNode.prev;
		} else {
			while ( aelNode.next != null ) {
				if ( edge.bottomX < aelNode.next.value.bottomX ) {
					aelNode.next.insertPrev ( edge );
					newNode = aelNode.next;
					
					break;
				}
				
				aelNode = aelNode.next;
			}
			
			if ( newNode == null ) {
				aelNode.insertNext ( edge );
				newNode = aelNode.next;
			}
		}
		
		if ( newNode.next == ael )
			ael = aelNode;
		
		return	newNode;
	}
	
	private function addLocalMax ( edge1:Edge, edge2:Edge, p:Point ):Void {
		var pNode:DoublyList <Point> = new DoublyList <Point> ( p );
		var poly:ChainedPolygon = new ChainedPolygon ( pNode, pNode );
		
		edge1.poly = poly;
		edge2.poly = poly;
	}
	
	/**
	 * Assumption: Polygons have no horizontal edges.
	 * @param	yb	Bottom of the scanbeam.
	 * @param	yt	Top of the scanbeam.
	 */
	private function processEdgesInAel ( yb:Float, yt:Float ):Void {
		if ( ael == null )
			return;
		
		var dy = yt - yb;
		var aelNode = ael;
		
		do {
			var edge = aelNode.value;
			
			if ( edge.topY == yt ) {	// Edge terminates at the top of the scanbeam
				if ( edge.successor == null ) {			// Local minima
					var nextEdge = aelNode.next.value;
					
					if ( edge.contributing )
						addLocalMin ( edge, nextEdge, new Point ( topX ( edge, dy ), yt ) );
					
					var nextAelNode = aelNode.next.next;
					aelNode.removeNext ();
					aelNode.removeSelf ();
					
					if ( ael == aelNode )
						ael = nextAelNode;
					
					aelNode = nextAelNode;
					
					if ( aelNode == null )
						break;
					else
						continue;
				} else if ( edge.side == Side.Left ) {		// Left intermediate
					if ( edge.contributing )
						addLeft ( edge, new Point ( edge.successor.bottomX, yt ) );
					
					edge.successor.poly = edge.poly;
					edge.successor.contributing = edge.contributing;
					edge.successor.side = edge.side;
					aelNode.value = edge.successor;
					
					addScanbeam ( edge.successor.topY );
				} else { 									// Right intermediate
					if ( edge.contributing )
						addRight ( edge, new Point ( edge.successor.bottomX, yt ) );
					
					edge.successor.poly = edge.poly;
					edge.successor.contributing = edge.contributing;
					edge.successor.side = edge.side;
					aelNode.value = edge.successor;
					
					addScanbeam ( edge.successor.topY );
				}
			} else
				edge.bottomX = topX ( edge, dy );
			
			aelNode = aelNode.next;
		} while ( aelNode != null );
	}
	
	private inline function addLeft ( edge:Edge, p:Point ):Void {
		edge.poly.prependPoint ( p );
	}
	
	private inline function addRight ( edge:Edge, p:Point ):Void {
		edge.poly.appendPoint ( p );
	}
	
	private inline function topX ( edge:Edge, dy:Float ):Float {
		return	edge.bottomX + edge.dx * dy;
	}
	
	private inline function addLocalMin ( e1:Edge, e2:Edge, p:Point ):Void {
		if ( e1.side == Side.Left )
			addLeft ( e1, p );
		else
			addRight ( e1, p );
		
		if ( e1.poly != e2.poly )	// e1 and e2 have different output polygons
			appendPolygon ( e1, e2 );
		else
			outPolys.add ( e1.poly );
	}
	
	private function appendPolygon ( e1:Edge, f1:Edge ):Void {
		/* Let P1 = P[p0p1…pn] and P2 = P[q0q1…qs] be the polygons adjacent
		 * to e1 and f1, respectively. Let e2 and f2 be the other top edges of P1 and P2,
		 * respectively. */
		if ( e1.side == Side.Left ) {
			/* Quote from VattiClip.pdf:
			 * "Add vertex list of P2 to the left of vertex list of P1, that is,
			 * replace P1 by P[qsqs−1…q0p0p1…pn]
			 * Make P1 the adjacent polygon of f2;"
			 * I think there is a mistake. Hereby we assume that the left edge e1 ALWAYS
			 * connects with the RIGHT edge f1.*/
			
			e1.poly.first.prev = f1.poly.last;
			f1.poly.last.next = e1.poly.first;
			
			var aelNode = ael;
			
			do {
				var f2 = aelNode.value;
				
				if ( f2.poly == f1.poly ) {
					f2.poly = e1.poly;	// Make P1 the adjacent polygon of f2
					
					break;
				}
				
				aelNode = aelNode.next;
			} while ( aelNode != null );
		} else {
			/* Quote from VattiClip.pdf:
			 * "Add vertex list of P1 to the right of vertex list of P2, that is,
			 * replace P2 by P[q0q1…qspnpn−1…p0]
			 * Make P2 the adjacent polygon of e2;"
			 * I think there is a mistake. Hereby we assume that the right edge e1 ALWAYS
			 * connects with the LEFT edge f1.*/
			
			e1.poly.last.next = f1.poly.first;
			f1.poly.first.prev = e1.poly.last;
			
			var aelNode = ael;
			
			do {
				var e2 = aelNode.value;
				
				if ( e2.poly == e1.poly ) {
					e2.poly = f1.poly;	// Make P2 the adjacent polygon of e2
					
					break;
				}
				
				aelNode = aelNode.next;
			} while ( aelNode != null );
		}
	}
	
	private function processIntersections ( yb:Float, yt:Float ):Void {
		buildIntersectionList ( yt - yb );
		//processIntersectionList ();
	}
	
	private function buildIntersectionList ( dy:Float ):Void {
		
	}
	
	private static function getRandomColor ():UInt {
		return	( Std.int ( Math.random () * 0x80 + 0x5f ) << 16 ) |
			( Std.int ( Math.random () * 0x80 + 0x5f ) << 8 ) |
			( Std.int ( Math.random () * 0x80 + 0x5f ) );
	}
	
	public function drawLml ( graphics:Graphics ):Void {
		var lm = lml;
		
		while ( lm != null ) {
			drawBound ( graphics, lm.edge1, lm.y );
			drawBound ( graphics, lm.edge2, lm.y );
			
			graphics.lineStyle ();
			graphics.beginFill ( 0x00ff00 );
			graphics.drawCircle ( lm.edge1.bottomX, lm.y, 2 );
			graphics.endFill ();
			
			lm = lm.next;
		}
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
	
	public function drawSbl ( graphics:Graphics, startX:Float, width:Float ):Void {
		var sb = sbl;
		var num:Int = 0;
		
		while ( sb != null ) {
			graphics.lineStyle ( 1, 0xd45500, 0.4 );
			graphics.moveTo ( startX, sb.y );
			graphics.lineTo ( startX + width, sb.y );
			
			sb = sb.next;
			num++;
		}
		
		trace ( "there are " + num + " scanbeams" );
	}
}