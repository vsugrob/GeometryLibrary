package geom.clipper;
import flash.display.Graphics;
import flash.geom.Point;
import geom.ChainedPolygon;
import geom.ClosedPolygonIterator;
import geom.ConcatIterator;
import geom.DoublyList;
import geom.TakeIterator;

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
	private var ael:ActiveEdge;
	/**
	 * Pointer to first node of the doubly-linked list of horizontal edges
	 * lying at the bottom of current scanbeam.
	 */
	private var hel:DoublyList <ActiveEdge>;
	/**
	 * List of polygons being formed during clipping operation.
	 */
	private var outPolys:List <ChainedPolygon>;
	/**
	 * List of intersections calculated in buildIntersectionList ().
	 */
	private var il:Intersection;
	/**
	 * Pointer to last intersection in il.
	 */
	private var ilLast:Intersection;
	/**
	 * Currently processed clipping operation (Intersection, Difference, Union or XOR ).
	 */
	private var clipOp:ClipOperation;
	
	public function new () {
		this.outPolys = new List <ChainedPolygon> ();
		this.clipperState = ClipperState.NotStarted; // DEBUG
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
	 */
	public function addPolygon ( poly:Iterable <Point>, kind:PolyKind ):Void {
		initLmlAndSbl ( poly, kind );
	}
	
	/**
	 * Clears added polygons and all data that was accumulated during last clip operation.
	 */
	public function clear ():Void {
		lml = null;
		sbl = null;
		ael = null;
		outPolys = new List <ChainedPolygon> ();
		il = null;
	}
	
	public function clip ( operation:ClipOperation ):Void {
		if ( sbl == null )	// Scanbeam list is empty
			return;
		
		this.clipOp = operation;
		var yb = popScanbeam ();	// Bottom of current scanbeam
		
		do {
			addNewBoundPairs ( yb );		// Modifies ael
			processHorizontalEdges ( yb );
			
			if ( sbl == null ) {
				// It is only possible when all polygons
				// are on the same horizontal line.
				
				return;
			}
			
			var yt = popScanbeam ();	// Top of the current scan beam
			
			processIntersections ( yb, yt );
			processEdgesInAel ( yb, yt );
			processHorizontalEdges ( yt );
			
			yb = yt;
		} while ( sbl != null );
	}
	
	// <clipStep>
	public var clipperState:ClipperState;
	public var cs_yb:Null <Float>;
	public var cs_yt:Null <Float>;
	
	public function clipStep ():Bool {
		if ( clipperState == ClipperState.Finished )
			return	false;
		
		/*if ( sbl == null )	// Scanbeam list is empty
			return	false;*/
		
		if ( clipperState == ClipperState.NotStarted ) {
			cs_yb = popScanbeam ();	// Bottom of current scanbeam
			
			clipperState = ClipperState.AddNewBoundPairs;
			
			return	true;
		}
		
		if ( clipperState == ClipperState.AddNewBoundPairs ) {
			addNewBoundPairs ( cs_yb );	// Modifies ael
			cs_yt = popScanbeam ();	// Top of the current scan beam
			
			clipperState = ClipperState.BuildIntersectionList;
			
			return	true;
		}
		
		if ( clipperState == ClipperState.BuildIntersectionList ||
			 clipperState == ClipperState.ProcessIntersectionList )
		{
			if ( !processIntersectionsStep ( cs_yb, cs_yt ) )
				clipperState = ClipperState.ProcessEdgesInAel;
			
			return	true;
		}
		
		if ( clipperState == ClipperState.ProcessEdgesInAel ) {
			processEdgesInAel ( cs_yb, cs_yt );
			
			cs_yb = cs_yt;
			cs_yt = null;
			clipperState = sbl != null ? ClipperState.AddNewBoundPairs : ClipperState.Finished;
			
			return	sbl != null;
		}
		
		return	sbl != null;
	}
	
	private function processIntersectionsStep ( yb:Float, yt:Float ):Bool {
		if ( ael == null ) {
			clipperState = ClipperState.ProcessEdgesInAel;
			
			return	false;
		}
		
		if ( clipperState == ClipperState.BuildIntersectionList ) {
			buildIntersectionList ( yb, yt );
			clipperState = ClipperState.ProcessIntersectionList;
			
			return	true;
		}
		
		if ( clipperState == ClipperState.ProcessIntersectionList )
			return	processIntersectionListStep ();
		
		return	false;
	}
	
	private function processIntersectionListStep ():Bool {
		if ( il == null )
			return	false;
		
		var isec = il;
		var prevIsec:Intersection = null;
		
		if ( !ActiveEdge.areAdjacent ( isec.e1Node, isec.e2Node ) ) {
			do {
				prevIsec = isec;
				isec = isec.next;
			} while ( !ActiveEdge.areAdjacent ( isec.e1Node, isec.e2Node ) );
		}
		
		// e1 precedes e2 in AEL
		var e1Node = isec.e1Node;
		var e2Node = isec.e2Node;
		var msg:String = "    ";
		msg += e1Node.side + " " + e1Node.kind + " x " + e2Node.side + " " + e2Node.kind + "\n";
		
		if ( !ActiveEdge.areAdjacent ( e1Node, e2Node ) )
			throw "ATTEMPT TO SWAP NON-ADJACENT NODES";
		
		if ( e1Node.kind == e2Node.kind ) {
			msg += "Like edge intersection";
			/* Like edge intersection:
			 * (LC ∩ RC) or (RC ∩ LC) → LI and RI
			 * (LS ∩ RS) or (RS ∩ LS) → LI and RI */
			if ( e1Node.contributing ) {			// Then e2 is contributing also
				if ( e1Node.side == Side.Left ) {	// Then we assume that e2 is right
					addLeft ( e1Node, isec.p );
					addRight ( e2Node, isec.p );
					msg += "\naddLeft ( e1Node, isec.p );\naddRight ( e2Node, isec.p );";
				} else {						// e1 is right e2 is left
					addLeft ( e2Node, isec.p );
					addRight ( e1Node, isec.p );
					msg += "\naddLeft ( e2Node, isec.p );\naddRight ( e1Node, isec.p );";
				}
			} else
				msg += " non-contributing";
			
			// Exchange side values of edges
			var tmpSide = e1Node.side;
			e1Node.side = e2Node.side;
			e2Node.side = tmpSide;
		} else if ( e1Node.side == Side.Left ) {
			if ( e2Node.side == Side.Left ) { 				// (LC ∩ LS) or (LS ∩ LC) → LI
				addLeft ( e2Node, isec.p );
				msg += "addLeft ( e2Node, isec.p );";
			} else /*if ( e2Node.side == Side.Right )*/ {	// (LS ∩ RC) or (LC ∩ RS) → MN
				addLocalMin ( e1Node, e2Node, isec.p );
				e1Node.contributing = false;
				e2Node.contributing = false;
				e1Node.poly = null;
				e2Node.poly = null;
				msg += "addLocalMin ( e1Node, e2Node, isec.p );";
			}
		} else /*if ( e1Node.side == Side.Right )*/ {
			if ( e2Node.side == Side.Right ) {				// (RC ∩ RS) or (RS ∩ RC) → RI
				addRight ( e1Node, isec.p );
				msg += "addRight ( e1Node, isec.p );";
			} else if ( e2Node.side == Side.Left ) { 		// (RS ∩ LC) or (RC ∩ LS) → MX
				addLocalMax ( e1Node, e2Node, isec.p );
				e1Node.contributing = true;
				e2Node.contributing = true;
				msg += "addLocalMax ( e1Node, e2Node, isec.p );";
			}
		}
		
		// Swap e1 and e2 position in AEL
		ActiveEdge.swapAdjacent ( e1Node, e2Node );
		
		if ( e1Node.prev == null )
			ael = e1Node;
		else if ( e2Node.prev == null )
			ael = e2Node;
		
		// Exchange adjPolyPtr pointers in edges
		var tmpPoly = e1Node.poly;
		e1Node.poly = e2Node.poly;
		e2Node.poly = tmpPoly;
		
		var tmpContrib = e1Node.contributing;
		e1Node.contributing = e2Node.contributing;
		e2Node.contributing = tmpContrib;
		
		if ( prevIsec == null )
			il = il.next;
		else
			prevIsec.next = isec.next;
		
		trace ( msg );
		
		return	il != null;
	}
	// </clipStep>
	
	private function initLmlAndSbl ( pts:Iterable <Point>, polyKind:PolyKind ):Void {
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
		
		if ( extrIdx == 0 )			// 1-point polygon
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
					
					if ( !Math.isFinite ( k ) ) {
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
				} else
					lastEdge = new Edge ( pFirst.x, pFirst.y, dx );
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
				addLocalMaxima ( lastEdge, prevEdge, pLast.y, polyKind );
				addLocalMinima ( lastEdge, firstEdge, pFirst.x, pFirst.y );
			} else {
				addLocalMaxima ( lastEdge, firstEdge, pFirst.y, polyKind );
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
					} else if ( prevDy > 0 && dy < 0 )	// We got local maxima
						addLocalMaxima ( prevEdge, edge, p0.y, polyKind );
					else {								// We got local minima
						lastJointIsLocalMimima = true;
						
						if ( firstJointIsLocalMimima == null )
							firstJointIsLocalMimima = true;
						
						addLocalMinima ( prevEdge, edge, p0.x, p0.y );
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
							addLocalMaxima ( lastEdge, firstEdge, p0.y, polyKind );	// [Case 1]
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
						
						addLocalMinima ( lastEdge, firstEdge, p0.x, p0.y );
					}
				} else {
					if ( firstJointIsLocalMimima ) {
						addLocalMaxima ( lastEdge, firstEdge, p0.y, polyKind );	// [Case 5]
						
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
						addLocalMaxima ( lastEdge, firstEdge, p0.y, polyKind );	// [Case 7]
					else
						lastEdge.successor = firstEdge;	// [Case 8]
				} else	// Local maximum
					addLocalMaxima ( lastEdge, firstEdge, p0.y, polyKind );	// [Case 9]
			}
		}
	}
	
	private inline function addLocalMaxima ( edge1:Edge, edge2:Edge, y:Float, polyKind:PolyKind ):Void {
		var lm = new LocalMaxima ( edge1, edge2, y, polyKind );
		
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
	
	private inline function addLocalMinima ( edge1:Edge, edge2:Edge, x:Float, y:Float ):Void {
		var lMin = new LocalMinima ( x, y, edge1, edge2 );
		edge1.successor = lMin;
		edge2.successor = lMin;
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
			addEdgesToAel ( lml.edge1, lml.edge2, yb, lml.kind );
			
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
	 * @param	kind
	 */
	private function addEdgesToAel ( edge1:Edge, edge2:Edge, yb:Float, kind:PolyKind ):Void {
		// Calculate parity
		var numLikeEdges:Int = 0;
		var numUnlikeEdges:Int = 0;
		var aelNode = ael;
		var prevAelNode:ActiveEdge = null;
		
		while ( aelNode != null && aelNode.bottomXIntercept < edge1.bottomX ) {
			if ( aelNode.kind == kind )
				numLikeEdges++;
			else
				numUnlikeEdges++;
			
			prevAelNode = aelNode;
			aelNode = aelNode.next;
		}
		
		var likeEdgesEven:Bool;
		var contribVertex:Bool;
		
		if ( clipOp == ClipOperation.Intersection ) {
			likeEdgesEven = numLikeEdges % 2 == 0;
			contribVertex = numUnlikeEdges % 2 == 1;
		} else if ( clipOp == ClipOperation.Difference ) {
			if ( numUnlikeEdges % 2 == 0 )
				contribVertex = kind == PolyKind.Subject;
			else
				contribVertex = kind == PolyKind.Clip;
			
			if ( kind == PolyKind.Subject )
				likeEdgesEven = numLikeEdges % 2 == 0;
			else
				likeEdgesEven = numLikeEdges % 2 == 1;	// Invert sides
		} else /*if ( clipOp == ClipOperation.Union )*/ {
			likeEdgesEven = numLikeEdges % 2 == 0;
			contribVertex = numUnlikeEdges % 2 == 0;
		}
		
		var aelNode1 = new ActiveEdge ( edge1, kind );
		var aelNode2 = new ActiveEdge ( edge2, kind );
		
		aelNode1.bottomXIntercept = edge1.bottomX;
		aelNode2.bottomXIntercept = edge1.bottomX;
		aelNode1.topXIntercept = edge1.bottomX;	// Top-x intercept necessary for buildHorizontalIntersectionList ().
		aelNode2.topXIntercept = edge1.bottomX;
		aelNode1.bottomY = yb;
		aelNode2.bottomY = yb;
		aelNode1.contributing = contribVertex;
		aelNode2.contributing = contribVertex;
		
		var cmp:Bool;	// Whether edge1 directed to the left relative to edge2?
		
		if ( edge1.isHorizontal ) {
			if ( edge2.isHorizontal ) {
				cmp = edge1.dx < edge2.dx;
				addHorizontalEdge ( aelNode2 );
			} else
				cmp = edge1.dx < 0;	// edge1.dx can't be 0
			
			addHorizontalEdge ( aelNode1 );
		} else if ( edge2.isHorizontal ) {
			cmp = edge2.dx > 0;		// edge2.dx can't be 0
			addHorizontalEdge ( aelNode2 );
		} else
			cmp = edge1.dx > edge2.dx;
		
		if ( cmp == likeEdgesEven ) {
			aelNode1.side = Side.Left;
			aelNode2.side = Side.Right;
		} else {
			aelNode1.side = Side.Right;
			aelNode2.side = Side.Left;
		}
		
		if ( !cmp ) {	// edge2 is to the left of the edge1
			var tmpNode = aelNode1;
			aelNode1 = aelNode2;
			aelNode2 = tmpNode;
		}
		
		// Insert edges into Active Edge List
		if ( prevAelNode != null ) {
			prevAelNode.next = aelNode1;
			aelNode1.prev = prevAelNode;
		}
		
		aelNode1.next = aelNode2;
		aelNode2.prev = aelNode1;
		
		if ( aelNode != null ) {
			aelNode2.next = aelNode;
			aelNode.prev = aelNode2;
		}
		
		if ( ael == null || ael.prev != null )
			ael = aelNode1;
		
		if ( contribVertex )
			addLocalMax ( aelNode1, aelNode2, new Point ( edge1.bottomX, yb ) );
	}
	
	private inline function addHorizontalEdge ( eNode:ActiveEdge ):Void {
		if ( hel == null )
			hel = new DoublyList <ActiveEdge> ( eNode );
		else
			hel.insertNext ( eNode );
	}
	
	private inline function addLocalMax ( e1Node:ActiveEdge, e2Node:ActiveEdge, p:Point ):Void {
		var pNode:DoublyList <Point> = new DoublyList <Point> ( p );
		var poly:ChainedPolygon = new ChainedPolygon ( pNode, pNode );
		
		e1Node.poly = poly;
		e2Node.poly = poly;
	}
	
	/**
	 * Active Edge List must have no horizontal edges.
	 * @param	yb	Bottom of the scanbeam.
	 * @param	yt	Top of the scanbeam.
	 */
	private function processEdgesInAel ( yb:Float, yt:Float ):Void {
		if ( ael == null )
			return;
		
		var aelNode = ael;
		
		do {
			var edge = aelNode.edge;
			
			if ( edge.topY == yt ) {	// Edge terminates at the top of the scanbeam
				if ( edge.successor.isLocalMinima () ) {
					var lMin = cast ( edge.successor, LocalMinima );
					var otherEdge:Edge = edge == lMin.edge2 ? lMin.edge1 : lMin.edge2;
					
					if ( aelNode.next == null || aelNode.next.edge != otherEdge ) {
						// Then other edge is horizontal while current edge is not.
						// We must defer processing of this edge until processing of horizontal edges.
						
						if ( edge.isHorizontal || !otherEdge.isHorizontal )
							throw "Assertion failed";
						
						aelNode = aelNode.next;
						
						continue;
					}
					
					// Next edge should be also contributing and its topY should be equal to yt
					if ( aelNode.contributing )
						addLocalMin ( aelNode, aelNode.next, new Point ( edge.successor.bottomX, yt ) );
					
					var nextAelNode:ActiveEdge = aelNode.next.next;
					aelNode.removeNext ();
					aelNode.removeSelf ();
					
					if ( ael == aelNode )
						ael = nextAelNode;
					
					aelNode = nextAelNode;
					
					continue;
				} else {
					if ( aelNode.contributing ) {
						var p = new Point ( edge.successor.bottomX, yt );
						
						if ( aelNode.side == Side.Left )
							addLeft ( aelNode, p );
						else
							addRight ( aelNode, p );
					}
					
					aelNode.edge = edge.successor;
					aelNode.bottomXIntercept = aelNode.edge.bottomX;
					aelNode.bottomY = yt;
					
					addScanbeam ( edge.successor.topY );
					
					if ( aelNode.edge.isHorizontal )
						addHorizontalEdge ( aelNode );
				}
			} else
				aelNode.bottomXIntercept = aelNode.topXIntercept;
			
			aelNode = aelNode.next;
		} while ( aelNode != null );
	}
	
	/**
	 * Processes horizontal edges.
	 */
	private function processEdgesInAelHorizontal ():Void {
		var helNode = hel;
		
		// First of all remove terminating edges from HEL
		do {
			var aelNode = helNode.value;
			var edge = aelNode.edge;
			var removeHelNode = false;
			
			if ( edge.successor.isLocalMinima () ) {
				var lMin = cast ( edge.successor, LocalMinima );
				var otherEdge:Edge = edge == lMin.edge2 ? lMin.edge1 : lMin.edge2;
				
				if ( !( ( aelNode.next != null && aelNode.next.edge == otherEdge ) ||
				        ( aelNode.prev != null && aelNode.prev.edge == otherEdge ) ) )
				{
					// Then other edge is horizontal too but it is not ending right now.
					// We must defer its processing.
					
					if ( !edge.isHorizontal || !otherEdge.isHorizontal )
						throw "Assertion failed";
					
					helNode = helNode.next;
					
					continue;
				}
				
				var aelNode1:ActiveEdge, aelNode2:ActiveEdge;
				
				if ( aelNode.next != null && aelNode.next.edge == otherEdge ) {
					aelNode1 = aelNode;
					aelNode2 = aelNode.next;
				} else {
					aelNode1 = aelNode.prev;
					aelNode2 = aelNode;
				}
				
				var nextAelNode:ActiveEdge = aelNode2.next;
				
				// Next edge should be also contributing and its topY should be equal to yt
				if ( aelNode1.contributing )
					addLocalMin ( aelNode1, aelNode2, new Point ( edge.successor.bottomX, edge.topY ) );
				
				aelNode1.removeSelf ();
				aelNode2.removeSelf ();
				
				if ( ael == aelNode1 )
					ael = nextAelNode;
				
				if ( otherEdge.isHorizontal ) {	// Then it should be removed from HEL as well as current edge
					// Find helNode wrapping otherEdge
					var otherHelNode = helNode.next;
					while ( otherHelNode.value.edge != otherEdge ) { otherHelNode = otherHelNode.next; }
					
					otherHelNode.removeSelf ();
				}
				
				removeHelNode = true;
			}
			
			if ( removeHelNode ) {
				var nextHelNode = helNode.next;
				
				helNode.removeSelf ();
				
				if ( hel == helNode )
					hel = nextHelNode;
				
				helNode = nextHelNode;
			} else
				helNode = helNode.next;
		} while ( helNode != null );
		
		helNode = hel;
		
		// Now advance remaining HEL nodes to their successors
		while ( helNode != null ) {
			var aelNode = helNode.value;
			var edge = aelNode.edge;
			var removeHelNode = false;
			
			if ( !edge.successor.isLocalMinima () ) {
				if ( aelNode.contributing ) {
					var p = new Point ( edge.successor.bottomX, edge.topY );
					
					if ( aelNode.side == Side.Left )
						addLeft ( aelNode, p );
					else
						addRight ( aelNode, p );
				}
				
				aelNode.edge = edge.successor;
				aelNode.bottomXIntercept = aelNode.edge.bottomX;
				
				if ( !edge.successor.isHorizontal ) {
					addScanbeam ( edge.successor.topY );
					removeHelNode = true;
				}
			}
			
			if ( removeHelNode ) {
				var nextHelNode = helNode.next;
				
				helNode.removeSelf ();
				
				if ( hel == helNode )
					hel = nextHelNode;
				
				helNode = nextHelNode;
			} else
				helNode = helNode.next;
		}
	}
	
	private inline function processHorizontalEdges ( y:Float ):Void {
		while ( hel != null && ael != null ) {
			buildHorizontalIntersectionList ( y );
			processIntersectionList ( y, y );	// Zero-height scanbeam
			processEdgesInAelHorizontal ();
		}
	}
	
	private inline function addLeft ( aelNode:ActiveEdge, p:Point ):Void {
		aelNode.poly.prependPoint ( p );
	}
	
	private inline function addRight ( aelNode:ActiveEdge, p:Point ):Void {
		aelNode.poly.appendPoint ( p );
	}
	
	private inline function addLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		if ( aelNode1.side == Side.Left )
			addLeft ( aelNode1, p );
		else
			addRight ( aelNode1, p );
		
		if ( aelNode1.poly != aelNode2.poly )	// aelNode1 and aelNode2 have different output polygons
			appendPolygon ( aelNode1, aelNode2 );
		else
			outPolys.add ( aelNode1.poly );
	}
	
	private function appendPolygon ( e1:ActiveEdge, f1:ActiveEdge ):Void {
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
			e1.poly.first = f1.poly.first;
			
			var f2 = ael;
			
			do {
				if ( f2.poly == f1.poly && f2 != f1 ) {
					f2.poly = e1.poly;	// Make P1 the adjacent polygon of f2
					
					break;
				}
				
				f2 = f2.next;
			} while ( f2 != null );
		} else {
			/* Quote from VattiClip.pdf:
			 * "Add vertex list of P1 to the right of vertex list of P2, that is,
			 * replace P2 by P[q0q1…qspnpn−1…p0]
			 * Make P2 the adjacent polygon of e2;"
			 * I think there is a mistake. Hereby we assume that the right edge e1 ALWAYS
			 * connects with the LEFT edge f1.*/
			
			e1.poly.last.next = f1.poly.first;
			f1.poly.first.prev = e1.poly.last;
			f1.poly.first = e1.poly.first;
			
			var e2 = ael;
			
			do {
				if ( e2.poly == e1.poly && e2 != e1 ) {
					e2.poly = f1.poly;	// Make P2 the adjacent polygon of e2
					
					break;
				}
				
				e2 = e2.next;
			} while ( e2 != null );
		}
	}
	
	private function processIntersections ( yb:Float, yt:Float ):Void {
		if ( ael == null )
			return;
		
		buildIntersectionList ( yb, yt );
		processIntersectionList ( yb, yt );
	}
	
	private function buildIntersectionList ( yb:Float, yt:Float ):Void {
		il = null; // Initialize IL to empty;
		ilLast = null;
		var dy = yt - yb;
		
		// Set Sorted Edge List to first node in Active Edge List
		var selLeft = new DoublyList <ActiveEdge> ( ael );
		var selRight = selLeft;
		
		ael.topXIntercept = ael.topX ( yt );
		var e1Node = ael.next;
		
		while ( e1Node != null ) {
			e1Node.topXIntercept = e1Node.topX ( yt );
			
			/* Starting with the rightmost node of SEL we shall now move from right
			 * to left through the nodes of SEL checking for an intersection with e1.
			 * Let e2 denote the rightmost edge of SEL. */
			var e2Node = selRight;
			
			while ( e2Node != null && e1Node.topXIntercept < e2Node.value.topXIntercept ) {
				// Make deferred intersection.
				var isec = intersectionOf ( e2Node.value, e1Node, yb, dy );	// e2 is to the left of the e1 in the ael
				addIntersection ( isec );
				
				// Update e2 to denote edge to its left in SEL
				e2Node = e2Node.prev;
			}
			
			// Now insert e1 into SEL at the point where we quit the while loop
			if ( e2Node != null ) {
				// Insert e1 to the right of e2 in SEL
				if ( e2Node.next == null ) {
					e2Node.insertNext ( e1Node );
					selRight = e2Node.next;
				} else
					e2Node.insertNext ( e1Node );
			} else {
				// Insert e1 at the left end of SEL
				selLeft.insertPrev ( e1Node );
				selLeft = selLeft.prev;
			}
			
			e1Node = e1Node.next;
		}
		
		buildApexIntersections ( selLeft, selRight, yt, true );
	}
	
	private function buildHorizontalIntersectionList ( yb:Float ):Void {
		il = null; // Initialize IL to empty;
		ilLast = null;
		
		var helNode = hel;
		
		do {
			helNode.value.topXIntercept = helNode.value.edge.successor.bottomX;
			helNode = helNode.next;
		} while ( helNode != null );
		
		// Set Sorted Edge List to first node in Active Edge List
		var selLeft = new DoublyList <ActiveEdge> ( ael );
		var selRight = selLeft;
		
		var e1Node = ael.next;
		
		while ( e1Node != null ) {
			/* Starting with the rightmost node of SEL we shall now move from right
			 * to left through the nodes of SEL checking for an intersection with e1.
			 * Let e2 denote the rightmost edge of SEL. */
			var e2Node = selRight;
			
			while ( e2Node != null && e1Node.topXIntercept < e2Node.value.topXIntercept ) {
				// Make deferred horizontal intersection.
				var isec = new Intersection ( e2Node.value, e1Node, null, 0, true );	// e2 is to the left of the e1 in the ael
				addIntersectionLast ( isec );
				
				// Update e2 to denote edge to its left in SEL
				e2Node = e2Node.prev;
			}
			
			// Now insert e1 into SEL at the point where we quit the while loop
			if ( e2Node != null ) {
				// Insert e1 to the right of e2 in SEL
				if ( e2Node.next == null ) {
					e2Node.insertNext ( e1Node );
					selRight = e2Node.next;
				} else
					e2Node.insertNext ( e1Node );
			} else {
				// Insert e1 at the left end of SEL
				selLeft.insertPrev ( e1Node );
				selLeft = selLeft.prev;
			}
			
			e1Node = e1Node.next;
		}
		
		buildApexIntersections ( selLeft, selRight, yb, false );
	}
	
	/**
	 * Processes intersections lying exactly in local minimas which wasn't able to detect
	 * using standard algorithm such as buildIntersectionList ().
	 * @param	selLeft	First element of Sorted Edge List.
	 * @param	selRight	Last element of Sorted Edge List.
	 * @param	yt	Y-coordinate of top of the scanbeam.
	 * @param	skipHorizontalPair	Should we skip terminating edge when its pairing edge is horizontal?
	 */
	private function buildApexIntersections ( selLeft:DoublyList <ActiveEdge>, selRight:DoublyList <ActiveEdge>, yt:Float, skipHorizontalPair:Bool ):Void {
		do {
			if ( selLeft.value.edge.topY == yt && selLeft.value.edge.successor.isLocalMinima () ) {
				var lMin = cast ( selLeft.value.edge.successor, LocalMinima );
				var otherEdge:Edge = selLeft.value.edge == lMin.edge2 ? lMin.edge1 : lMin.edge2;
				
				if ( skipHorizontalPair && otherEdge.isHorizontal ) {
					/* When buildApexIntersections () called from buildIntersectionList (), it is only necessary
					 * to check whether otherEdge is horizontal in order to skip edge. */
					selLeft = selLeft.next;
					
					continue;
				}
				
				// Find selNode pointing to other edge ending at local minima
				selRight = selLeft.next;
				
				while ( selRight != null && selRight.value.edge != otherEdge ) { selRight = selRight.next; }
				
				if ( selRight == null ) {
					// There are two possible cases:
					// 1. Other edge ending at local minima is horizontal while selLeft is not.
					// 2. Both edges are horizontal but one of the bellows have more horizontal edges
					//   than the other and that's why it does not ends right now.
					// We must defer its processing.
					
					if ( !otherEdge.isHorizontal )
						throw "Assertion failed";
					
					selLeft = selLeft.next;
					
					continue;
				}
				
				var p = new Point ( lMin.bottomX, lMin.topY );
				
				// Intersect right edge with all edges between bounds
				while ( selRight.prev != selLeft ) {
					/* Create Intersection object with intersection point already set.
					 * Since the point has already been calculated, it doesn't matter whether intersection was
					 * horizontal or not. */
					var isec = new Intersection ( selRight.prev.value, selRight.value, p, Math.POSITIVE_INFINITY );
					DoublyList.swapAdjacent ( selRight.prev, selRight );
					
					// Add isec to the END of the il
					addIntersectionLast ( isec );
				}
				
				selLeft = selRight;
			}
			
			selLeft = selLeft.next;
		} while ( selLeft != null );
	}
	
	private inline function addIntersection ( isec:Intersection ):Void {
		if ( il == null ) {
			il = isec;
			ilLast = isec;
		} else {
			il.insert ( isec );
			
			if ( isec.k < il.k )
				il = isec;
			else if ( isec.k >= ilLast.k )
				ilLast = isec;
		}
	}
	
	private inline function addIntersectionLast ( isec:Intersection ):Void {
		if ( ilLast != null )
			ilLast.next = isec;
		else
			il = isec;
		
		ilLast = isec;
	}
	
	/**
	 * Creates deferred Intersection object which is in turn aimed to find intersection point of two edges.
	 * Note that it should be known apriori that two given edges intersects.
	 * @param	e1	First edge known to intersect other edge.
	 * @param	e2	Second edge. Should be to the right of the e1 in Active Edge List!
	 * @param	yb	Bottom of the scanbeam.
	 * @param	dy	Difference between top and bottom of the scanbeam.
	 * @return	Intersection of two edges.
	 */
	private static inline function intersectionOf ( e1Node:ActiveEdge, e2Node:ActiveEdge, yb:Float, dy:Float ):Intersection {
		/* Let dxt be absolute value of difference between top x intercepts.
		 * Let dxb be absolute value of difference between bottom x intercepts.
		 * Given dxb and dxt we can calculate ratio k = dxb / dxt which
		 * is similarity ratio of two triangles formed by intersecting e1, e2 and
		 * two horizontal lines of the scanbeam.
		 * 
		 * NOTE on why we chose k to be equal dxb / dxt, not dxt / dxb:
		 * dxb can be zero while dxt can't.*/
		var dxt = Math.abs ( e1Node.topXIntercept - e2Node.topXIntercept );
		var dxb = Math.abs ( e1Node.bottomXIntercept - e2Node.bottomXIntercept );
		var k = dxb / dxt;
		
		return	new Intersection ( e1Node, e2Node, null, k );
	}
	
	private function processIntersectionList ( yb:Float, yt:Float ):Void {
		var dy = yt - yb;
		
		while ( il != null ) {
			var isec = il;
			var prevIsec:Intersection = null;
			
			if ( !ActiveEdge.areAdjacent ( isec.e1Node, isec.e2Node ) ) {
				do {
					prevIsec = isec;
					isec = isec.next;
				} while ( !ActiveEdge.areAdjacent ( isec.e1Node, isec.e2Node ) );
			}
			
			// e1Node precedes e2Node in AEL
			var e1Node = isec.e1Node;
			var e2Node = isec.e2Node;
			
			if ( e1Node.kind == e2Node.kind ) {
				/* Like edge intersection:
				 * (LC ∩ RC) or (RC ∩ LC) → LI and RI
				 * (LS ∩ RS) or (RS ∩ LS) → LI and RI */
				if ( e1Node.contributing ) {			// Then e2Node is contributing also
					isec.calculateIntersectionPoint ( yb, dy );
					
					if ( e1Node.side == Side.Left ) {
						addLeft ( e1Node, isec.p );
						addRight ( e2Node, isec.p );
					} else {
						addLeft ( e2Node, isec.p );
						addRight ( e1Node, isec.p );
					}
				}
				
				// Exchange side values of edges
				var tmpSide = e1Node.side;
				e1Node.side = e2Node.side;
				e2Node.side = tmpSide;
			} else {
				isec.calculateIntersectionPoint ( yb, dy );
				var isecType = isec.classify ( clipOp );
				
				switch ( isecType ) {
				case IntersectionType.LeftIntermediate:
					if ( clipOp == ClipOperation.Union )
						addLeft ( e1Node, isec.p );
					else
						addLeft ( e2Node, isec.p );
				case IntersectionType.RightIntermediate:
					if ( clipOp == ClipOperation.Union )
						addRight ( e2Node, isec.p );
					else
						addRight ( e1Node, isec.p );
				case IntersectionType.LocalMinima:
					addLocalMin ( e1Node, e2Node, isec.p );
					e1Node.contributing = false;
					e2Node.contributing = false;
					e1Node.poly = null;
					e2Node.poly = null;
				case IntersectionType.LocalMaxima:
					addLocalMax ( e1Node, e2Node, isec.p );
					e1Node.contributing = true;
					e2Node.contributing = true;
				}
			}
			
			// Swap e1Node and e2Node position in AEL
			ActiveEdge.swapAdjacent ( e1Node, e2Node );
			
			if ( isec.e1Node.prev == null )
				ael = isec.e1Node;
			else if ( isec.e2Node.prev == null )
				ael = isec.e2Node;
			
			// Exchange adjPolyPtr pointers in edges
			var tmpPoly = e1Node.poly;
			e1Node.poly = e2Node.poly;
			e2Node.poly = tmpPoly;
			
			var tmpContrib = e1Node.contributing;
			e1Node.contributing = e2Node.contributing;
			e2Node.contributing = tmpContrib;
			
			if ( prevIsec == null )
				il = il.next;
			else
				prevIsec.next = isec.next;
		}
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
		} while ( !edge.isLocalMinima () );
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
	
	public static function beginDrawPoly ( graphics:Graphics,
		stroke:Null <UInt> = null, strokeOpacity:Float = 1, strokeWidth:Float = 1,
		fill:Null <UInt> = null, fillOpacity = 0.5 ):Void
	{
		if ( stroke == null )
			stroke = getRandomColor ();
		
		if ( fill == null )
			fill = getRandomColor ();
		
		graphics.lineStyle ( strokeWidth, stroke, strokeOpacity );
		graphics.beginFill ( fill, fillOpacity );
	}
	
	public static function endDrawPoly ( graphics:Graphics ):Void {
		graphics.endFill ();
	}
	
	public static function drawPoly ( pts:Iterable <Point>, graphics:Graphics ):Void {
		var it = pts.iterator ();
		
		if ( !it.hasNext () )
			return;
		
		var p = it.next ();
		graphics.moveTo ( p.x, p.y );
		
		while ( it.hasNext () ) {
			p = it.next ();
			graphics.lineTo ( p.x, p.y );
			
			//graphics.drawCircle ( p.x, p.y, 2 );
		}
	}
	
	public static function beginDrawPolySvg ( buf:StringBuf,
		stroke:Null <UInt> = null, strokeOpacity:Float = 1, strokeWidth:Float = 1,
		fill:Null <UInt> = null, fillOpacity = 0.5 ):Void
	{
		if ( stroke == null )
			stroke = getRandomColor ();
		
		if ( fill == null )
			fill = getRandomColor ();
		
		buf.add ( '<path stroke="#' + StringTools.hex ( stroke, 6 ) +
			'" stroke-width="' + strokeWidth + '" stroke-opacity="' + strokeOpacity + '"' );
		
		buf.add ( ' fill="#' + StringTools.hex ( fill, 6 ) +
			'" fill-opacity="' + fillOpacity + '"' );
		
		buf.add ( ' d="' );
	}
	
	public static function drawPolySvg ( pts:Iterable <Point>, buf:StringBuf ):Void {
		var it = pts.iterator ();
		
		if ( !it.hasNext () )
			return;
		
		var p = it.next ();
		buf.add ( 'M' + p.x + ',' + p.y + ' ' );
		
		while ( it.hasNext () ) {
			p = it.next ();
			buf.add ( p.x + ',' + p.y + ' ' );
		}
	}
	
	public static function endDrawPolySvg ( buf:StringBuf ):Void {
		buf.add ( '" />\n' );
	}
	
	public function drawOutPolys ( graphics:Graphics ):Void {
		for ( poly in outPolys ) {
			beginDrawPoly ( graphics, null, 1, 2, null, 0.5 );
			drawPoly ( poly, graphics );
			endDrawPoly ( graphics );
		}
	}
	
	/* We can draw ael with color legend illustrating its:
	 * 1. Contributing status
	 * 2. 'poly' field
	 * 3. 'kind' field (clip/subject)
	 * 4. 'side' field (left/right)
	 * 5. Position in ael*/
	public function drawAelBySide ( graphics:Graphics, zoom:Float = 1.0 ):Void {
		if ( cs_yb == null || cs_yt == null )
			return;
		
		var aelNode = ael;
		
		while ( aelNode != null ) {
			drawAelNodeBySide ( graphics, aelNode, zoom );
			
			aelNode = aelNode.next;
		}
	}
	
	private function drawAelNodeBySide ( graphics:Graphics, aelNode:ActiveEdge, zoom:Float = 1.0 ):Void {
		var dy = cs_yt - cs_yb;
		var e = aelNode.edge;
		var topX = aelNode.topX ( cs_yt );
		
		var color = aelNode.side == Side.Left ? 0xff0000 : 0x00ff00;
		graphics.lineStyle ( 1 / zoom, color, 1 );
		graphics.moveTo ( aelNode.bottomXIntercept, cs_yb );
		graphics.lineTo ( topX, cs_yt );
	}
	
	public function drawAelByPoly ( graphics:Graphics ):Void {
		if ( cs_yb == null || cs_yt == null )
			return;
		
		var polys = new List <ChainedPolygon> ();
		var aelNode = ael;
		
		while ( aelNode != null ) {
			if ( aelNode.contributing ) {
				if ( !Lambda.has ( polys, aelNode.poly ) )
					polys.add ( aelNode.poly );
			}
			
			aelNode = aelNode.next;
		}
		
		var colorDelta = polys.length < 2 ? 0 : 255 / ( polys.length - 1 );
		
		var dy = cs_yt - cs_yb;
		aelNode = ael;
		
		while ( aelNode != null ) {
			var e = aelNode.edge;
			var topX = aelNode.topX ( cs_yt );
			
			var color:UInt;
			
			if ( aelNode.contributing ) {
				var polyIdx = Lambda.indexOf ( polys, aelNode.poly );
				color = Std.int ( polyIdx * colorDelta ) << 8;
			} else
				color = 0x445599;
			
			graphics.lineStyle ( 1, color, 1 );
			graphics.moveTo ( aelNode.bottomXIntercept, cs_yb );
			graphics.lineTo ( topX, cs_yt );
			
			aelNode = aelNode.next;
		}
	}
	
	public function drawContributedPolys ( graphics:Graphics,
		stroke:Null <UInt> = null, strokeOpacity:Float = 1, strokeWidth:Float = 1,
		fill:Null <UInt> = null, fillOpacity = 0.5 ):Void
	{
		var polys = new List <ChainedPolygon> ();
		var aelNode = ael;
		
		while ( aelNode != null ) {
			if ( aelNode.poly != null ) {
				if ( !Lambda.has ( polys, aelNode.poly ) )
					polys.add ( aelNode.poly );
			}
			
			aelNode = aelNode.next;
		}
		
		for ( poly in outPolys ) {
			if ( !Lambda.has ( polys, poly ) )
				polys.add ( poly );
		}
		
		beginDrawPoly ( graphics, stroke, strokeOpacity, strokeWidth,
			fill, fillOpacity );
		
		for ( poly in polys ) {
			drawPoly ( poly, graphics );
		}
		
		endDrawPoly ( graphics );
	}
	
	public function drawCurrentScanbeam ( graphics:Graphics, zoom:Float = 1.0 ):Void {
		if ( cs_yb != null ) {
			graphics.lineStyle ( 1 / zoom, 0xaa9900, 1 );
			graphics.moveTo ( -10000, cs_yb );
			graphics.lineTo ( 10000, cs_yb );
		}
		
		if ( cs_yt != null ) {
			graphics.lineStyle ( 1 / zoom, 0x99aa00, 1 );
			graphics.moveTo ( -10000, cs_yt );
			graphics.lineTo ( 10000, cs_yt );
		}
		
		if ( cs_yb != null && cs_yt != null ) {
			graphics.lineStyle ( 0, 0, 0 );
			graphics.beginFill ( 0x9957aa, 0.3 );
			graphics.drawRect ( -10000, cs_yb, 20000, cs_yt - cs_yb );
			graphics.endFill ();
		}
	}
	
	public function drawIntersectionScanline ( graphics:Graphics, zoom:Float = 1.0 ):Void {
		if ( il == null )
			return;
		
		if ( cs_yb != null ) {
			graphics.lineStyle ( 0, 0, 0 );
			graphics.beginFill ( 0x0, 0.2 );
			graphics.drawRect ( -10000, cs_yb, 20000, il.p.y - cs_yb );
			graphics.endFill ();
		}
		
		graphics.lineStyle ( 1 / zoom, 0xaa9977, 1 );
		graphics.moveTo ( -10000, il.p.y );
		graphics.lineTo ( 10000, il.p.y );
	}
	
	public function drawIntersections ( graphics:Graphics, zoom:Float = 1.0 ):Void {
		if ( zoom > 50 )
			zoom = 50;
		
		var isec:Intersection;
		graphics.lineStyle ( 0, 0, 0 );
		
		if ( il != null ) {
			isec = il.next;
			
			while ( isec != null ) {
				graphics.beginFill ( 0x0000ff, 0.7 );
				graphics.drawCircle ( isec.p.x, isec.p.y, 2 / zoom );
				graphics.endFill ();
				
				isec = isec.next;
			}
		}
		
		isec = il;
		
		if ( isec != null ) {
			drawAelNodeBySide ( graphics, isec.e1Node, zoom );
			drawAelNodeBySide ( graphics, isec.e2Node, zoom );
			
			graphics.lineStyle ( 0, 0, 0 );
			graphics.beginFill ( 0x5599ff, 1 );
			graphics.drawCircle ( isec.p.x, isec.p.y, 2 / zoom );
			graphics.endFill ();
		}
	}
	
	public function traceNextIntersection ():Void {
		var isec = il;
		
		if ( isec != null ) {
			trace ( 'Next intersection: ' +
				getActiveEdgeDescription ( isec.e1Node ) + ' x ' +
				getActiveEdgeDescription ( isec.e2Node )
			);
		}
	}
	
	private function getActiveEdgeDescription ( aelNode:ActiveEdge ):String {
		return	( aelNode.contributing ? 'c' : '' ) +
			( aelNode.side == Side.Left ? 'l' : 'r' ) +
			( aelNode.kind == PolyKind.Clip ? 'c' : 's' );
	}
	
	public function traceAel ():Void {
		var msg = 'Active Edge List:';
		
		if ( ael != null ) {
			var aelNode = ael;
			
			while ( aelNode != null ) {
				msg += ' ' + getActiveEdgeDescription ( aelNode );
				
				aelNode = aelNode.next;
			}
		} else
			msg += ' NONE';
		
		trace ( msg );
	}
	
	public function traceIl ():Void {
		var msg = 'Intersection List';
		
		if ( il != null ) {
			var count = 0;
			var isec = il;
			
			while ( isec != null ) {
				isec = isec.next;
				count++;
			}
			
			msg += ' (' + count + '):\n';
			
			isec = il;
			
			while ( isec != null ) {
				msg += '(' + getActiveEdgeDescription ( isec.e1Node ) + ' x ' +
					getActiveEdgeDescription ( isec.e2Node ) + ' at k: ' +
					isec.k + ')\n';
				
				isec = isec.next;
			}
		} else
			msg += ': NONE';
		
		trace ( msg );
	}
}