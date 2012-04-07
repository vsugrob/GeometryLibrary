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
	private var ael:ActiveEdge;
	/**
	 * List of polygons being formed during clipping operation.
	 */
	private var outPolys:List <ChainedPolygon>;
	/**
	 * List of intersections calculated in buildIntersectionList ().
	 */
	private var il:Intersection;
	
	public function new () {
		this.outPolys = new List <ChainedPolygon> ();
		this.clipperState = ClipperState.NotStarted; // DEBUG
	}
	
	/**
	 * 
	 * @param	poly	Iterable of Point where last point coincide to first point.
	 * @param	kind	Whether this poly is one that will be clipped (PolyKind.Subject) or that which
	 * will clip (PolyKind.Clip).
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
	
	public function clip ():Void {
		if ( sbl == null )	// Scanbeam list is empty
			return;
		
		var yb = popScanbeam ();	// Bottom of current scanbeam
		
		do {
			addNewBoundPairs ( yb );	// Modifies ael
			
			var yt = popScanbeam ();	// Top of the current scan beam
			
			processIntersections ( yb, yt );
			processEdgesInAel ( yb, yt );
			
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
		var isec = il;
		
		if ( isec == null )
			return	false;
		
		// e1 precedes e2 in AEL
		var e1Node = isec.e1Node;
		var e2Node = isec.e2Node;
		var msg:String = "    ";
		msg += e1Node.side + " " + e1Node.kind + " x " + e2Node.side + " " + e2Node.kind + "\n";
		
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
		} else if ( ( e1Node.side == Side.Left  && e1Node.kind == PolyKind.Subject &&
					  e2Node.side == Side.Right && e2Node.kind == PolyKind.Clip ) ||
					( e1Node.side == Side.Left  && e1Node.kind == PolyKind.Clip &&
					  e2Node.side == Side.Right && e2Node.kind == PolyKind.Subject ) )	// (LS ∩ RC) or (LC ∩ RS) → MX
		{
			addLocalMin ( e1Node, e2Node, isec.p );
			e1Node.contributing = false;
			e2Node.contributing = false;
			e1Node.poly = null;
			e2Node.poly = null;
			
			msg += "addLocalMin ( e1Node, e2Node, isec.p );";
		} else if ( ( e1Node.side == Side.Left && e1Node.kind == PolyKind.Clip &&
					  e2Node.side == Side.Left && e2Node.kind == PolyKind.Subject ) ||
					( e1Node.side == Side.Left && e1Node.kind == PolyKind.Subject &&
					  e2Node.side == Side.Left && e2Node.kind == PolyKind.Clip ) )		// (LC ∩ LS) or (LS ∩ LC) → LI
		{
			addLeft ( e2Node, isec.p );
			msg += "addLeft ( e2Node, isec.p );";
		} else if ( ( e1Node.side == Side.Right && e1Node.kind == PolyKind.Clip &&
					  e2Node.side == Side.Right && e2Node.kind == PolyKind.Subject ) ||
					( e1Node.side == Side.Right && e1Node.kind == PolyKind.Subject &&
					  e2Node.side == Side.Right && e2Node.kind == PolyKind.Clip ) )		// (RC ∩ RS) or (RS ∩ RC) → RI
		{
			addRight ( e1Node, isec.p );
			msg += "addRight ( e1Node, isec.p );";
		} else if ( ( e1Node.side == Side.Right && e1Node.kind == PolyKind.Subject &&
					  e2Node.side == Side.Left  && e2Node.kind == PolyKind.Clip ) ||
					( e1Node.side == Side.Right && e1Node.kind == PolyKind.Clip &&
					  e2Node.side == Side.Left  && e2Node.kind == PolyKind.Subject ) )	// (RS ∩ LC) or (RC ∩ LS) → MN
		{
			addLocalMax ( e1Node, e2Node, isec.p );
			e1Node.contributing = true;
			e2Node.contributing = true;
			msg += "addLocalMax ( e1Node, e2Node, isec.p );";
		}
		
		// Swap e1 and e2 position in AEL
		ActiveEdge.swap ( e1Node, e2Node );
		
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
		
		isec = isec.next;
		il = il.next;
		
		trace ( msg );
		
		return	isec != null;
	}
	// </clipStep>
	
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
					edge = new Edge ( p1.x, p0.y, -dx );
				else
					edge = new Edge ( p0.x, p0.y, dx );
				
				/* prevDy == 0 is a special case. It doesn't mean that 
				 * previous edge was horizontal as well as curent edge (which is
				 * impossible because of the collinear edge removal stage that
				 * must precede clipping). It just mean that this is the first edge
				 * being processed so we handle its orientation later when we connect
				 * first and last edge. */
				
				edge.isHorizontal = true;
			} else if ( dy > 0 )
				edge = new Edge ( p1.x, p0.y, dx / dy );
			else
				edge = new Edge ( p0.x, p1.y, dx / dy );
			
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
		var p:Point = new Point ( edge1.bottomX, yb );
		var likeEdgesEven = numLeftAelNodesEven ( p.x, kind );	// Number of edges in ael to the left of
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
		
		var e1Side:Side, e2Side:Side;
		
		if ( cmp == likeEdgesEven ) {
			e1Side = Side.Left;
			e2Side = Side.Right;
		} else {
			e1Side = Side.Right;
			e2Side = Side.Left;
		}
		
		if ( !cmp ) {
			var tmpEdge = edge1;
			edge1 = edge2;
			edge2 = tmpEdge;
			
			var tmpSide = e1Side;
			e1Side = e2Side;
			e2Side = tmpSide;
		}
		
		var aelNode1:ActiveEdge, aelNode2:ActiveEdge;
		
		if ( ael == null )
			aelNode1 = ael = new ActiveEdge ( edge1, kind );
		else
			aelNode1 = addActiveEdge ( ael, edge1, kind );
		
		aelNode2 = addActiveEdge ( aelNode1, edge2, kind );
		
		aelNode1.side = e1Side;
		aelNode2.side = e2Side;
		aelNode1.bottomXIntercept = aelNode1.edge.bottomX;
		aelNode2.bottomXIntercept = aelNode2.edge.bottomX;
		aelNode1.bottomY = yb;
		aelNode2.bottomY = yb;
		
		initEdgeContributingStatus ( aelNode1 );
		initEdgeContributingStatus ( aelNode2 );
		
		if ( aelNode1.contributing && aelNode2.contributing )
			addLocalMax ( aelNode1, aelNode2, p );
	}
	
	private inline function initEdgeContributingStatus ( aelNode:ActiveEdge ):Void {
		var i = 0;
		var kind:PolyKind = aelNode.kind;
		var startNode = aelNode;
		aelNode = aelNode.prev;
		
		while ( aelNode != null ) {
			if ( aelNode.kind != kind )
				i++;
			
			aelNode = aelNode.prev;
		}
		
		startNode.contributing = i % 2 == 1;
	}
	
	private inline function numLeftAelNodesEven ( x:Float, kind:PolyKind ):Bool {
		var i:Int = 0;
		var aelNode = ael;
		
		while ( aelNode != null && aelNode.bottomXIntercept < x ) {
			if ( aelNode.kind == kind )
				i++;
			
			aelNode = aelNode.next;
		}
		
		return	i % 2 == 0;
	}
	
	/**
	 * Insert an edge into active edge list after aelNode maintaining x-order.
	 * @param	node	Origin node.
	 * @param	edge	An edge being inserted.
	 * @param	kind	PolyKind of the edge.
	 * @return	Newly generated node that holds reference to an edge.
	 */
	private inline function addActiveEdge ( aelNode:ActiveEdge, edge:Edge, kind:PolyKind ):ActiveEdge {
		var newNode:ActiveEdge = null;
		
		if ( edge.bottomX < aelNode.bottomXIntercept ) {
			aelNode.insertPrev ( edge, kind );
			newNode = aelNode.prev;
		} else {
			while ( aelNode.next != null ) {
				if ( edge.bottomX < aelNode.next.bottomXIntercept ) {
					aelNode.next.insertPrev ( edge, kind );
					newNode = aelNode.next;
					
					break;
				}
				
				aelNode = aelNode.next;
			}
			
			if ( newNode == null ) {
				aelNode.insertNext ( edge, kind );
				newNode = aelNode.next;
			}
		}
		
		newNode.kind = kind;
		
		if ( newNode.next == ael )
			ael = aelNode;
		
		return	newNode;
	}
	
	private function addLocalMax ( e1Node:ActiveEdge, e2Node:ActiveEdge, p:Point ):Void {
		var pNode:DoublyList <Point> = new DoublyList <Point> ( p );
		var poly:ChainedPolygon = new ChainedPolygon ( pNode, pNode );
		
		e1Node.poly = poly;
		e2Node.poly = poly;
	}
	
	/**
	 * Assumption: Polygons have no horizontal edges.
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
				if ( edge.successor == null ) {			// Local minima
					var nextAelNode:ActiveEdge;
					
					if ( aelNode.contributing ) {	// Next edge should be also contributing
						addLocalMin ( aelNode, aelNode.next, new Point ( aelNode.topXIntercept, yt ) );
						
						nextAelNode = aelNode.next.next;
						aelNode.removeNext ();
						aelNode.removeSelf ();
					} else {
						nextAelNode = aelNode.next;
						aelNode.removeSelf ();
					}
					
					if ( ael == aelNode )
						ael = nextAelNode;
					
					aelNode = nextAelNode;
					
					continue;
				} else {
					if ( aelNode.contributing ) {
						if ( aelNode.side == Side.Left )	// Left intermediate
							addLeft ( aelNode, new Point ( edge.successor.bottomX, yt ) );
						else 								// Right intermediate
							addRight ( aelNode, new Point ( edge.successor.bottomX, yt ) );
					}
					
					aelNode.edge = edge.successor;
					aelNode.bottomXIntercept = aelNode.edge.bottomX;
					aelNode.bottomY = yt;
					
					addScanbeam ( edge.successor.topY );
				}
			} else
				aelNode.bottomXIntercept = aelNode.topXIntercept;
			
			aelNode = aelNode.next;
		} while ( aelNode != null );
	}
	
	private inline function addLeft ( aelNode:ActiveEdge, p:Point ):Void {
		aelNode.poly.prependPoint ( p );
	}
	
	private inline function addRight ( aelNode:ActiveEdge, p:Point ):Void {
		aelNode.poly.appendPoint ( p );
	}
	
	private static inline function topX ( aelNode:ActiveEdge, y:Float ):Float {
		return	aelNode.edge.bottomX + aelNode.edge.dx * ( y - aelNode.bottomY );
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
		processIntersectionList ();
	}
	
	private function buildIntersectionList ( yb:Float, yt:Float ):Void {
		il = null; // Initialize IL to empty;
		
		// Set Sorted Edge List to first node in Active Edge List
		var selLeft = new DoublyList <ActiveEdge> ( ael );
		var selRight = selLeft;
		
		ael.topXIntercept = topX ( ael, yt );
		var e1Node = ael.next;
		
		while ( e1Node != null ) {
			e1Node.topXIntercept = topX ( e1Node, yt );
			
			/* Starting with the rightmost node of SEL we shall now move from right
			 * to left through the nodes of SEL checking for an intersection with e1.
			 * Let e2 denote the rightmost edge of SEL. */
			var e2Node = selRight;
			
			while ( e2Node != null && e1Node.topXIntercept < e2Node.value.topXIntercept ) {
				var p = intersectionOf ( e1Node, e2Node.value, yb );
				addIntersection ( e2Node.value, e1Node, p );	// e2 is to the left of the e1 in the ael
				
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
	}
	
	private inline function addIntersection ( e1Node:ActiveEdge, e2Node:ActiveEdge, p:Point ):Void {
		var isec = new Intersection ( e1Node, e2Node, p );
		
		if ( il == null )
			il = isec;
		else {
			il.insert ( isec );
			
			if ( p.y > il.p.y )
				il = isec;
		}
	}
	
	/**
	 * Finds intersection point of two edges. Note that it should be known apriori that two given
	 * edges intersects. This function only calculates where exactly intersection is and it may have
	 * unpredicted behavior in case when edges are parallel to each other.
	 * @param	e1	First edge known to intersect other edge.
	 * @param	e2	Second edge.
	 * @param	yb	Bottom of the scanbeam.
	 * @return	Point of intersection between two edges.
	 */
	private static inline function intersectionOf ( e1Node:ActiveEdge, e2Node:ActiveEdge, yb:Float ):Point {
		/* ix, iy		- isec point
		 * bx1, bx2		- bottom x-es of the edges
		 * idy			- is eq to: iy minus bottom of the scanbeam
		 * 
		 * Given:
		 *	ix == bx1 + dx1 * idy == bx2 + dx2 * idy
		 * Rearrange:
		 *	bx1 - bx2 == ( dx2 - dx1 ) * idy
		 * Get the idy (and therefore iy too):
		 *	idy == ( bx1 - bx2 ) / ( dx2 - dx1 )
		 * Get the ix:
		 *	ix == bx1 + dx1 * idy */
		
		var idy = ( e1Node.bottomXIntercept - e2Node.bottomXIntercept ) / ( e2Node.edge.dx - e1Node.edge.dx );
		var yIsec = yb + idy;
		var p = new Point ( topX ( e1Node, yIsec ), yIsec );
		
		return	p;
	}
	
	private function processIntersectionList ():Void {
		var isec = il;
		
		while ( isec != null ) {
			// e1Node precedes e2Node in AEL
			var e1Node = isec.e1Node;
			var e2Node = isec.e2Node;
			
			if ( e1Node.kind == e2Node.kind ) {
				/* Like edge intersection:
				 * (LC ∩ RC) or (RC ∩ LC) → LI and RI
				 * (LS ∩ RS) or (RS ∩ LS) → LI and RI */
				if ( e1Node.contributing ) {			// Then e2Node is contributing also
					if ( e1Node.side == Side.Left ) {	// Then we assume that e2Node is right
						addLeft ( e1Node, isec.p );
						addRight ( e2Node, isec.p );
					} else {						// e1Node is right e2Node is left
						addLeft ( e2Node, isec.p );
						addRight ( e1Node, isec.p );
					}
				}
				
				// Exchange side values of edges
				var tmpSide = e1Node.side;
				e1Node.side = e2Node.side;
				e2Node.side = tmpSide;
			} else if ( ( e1Node.side == Side.Left  && e1Node.kind == PolyKind.Subject &&
						  e2Node.side == Side.Right && e2Node.kind == PolyKind.Clip ) ||
						( e1Node.side == Side.Left  && e1Node.kind == PolyKind.Clip &&
						  e2Node.side == Side.Right && e2Node.kind == PolyKind.Subject ) )	// (LS ∩ RC) or (LC ∩ RS) → MX
			{
				addLocalMin ( e1Node, e2Node, isec.p );
				e1Node.contributing = false;
				e2Node.contributing = false;
				e1Node.poly = null;
				e2Node.poly = null;
			} else if ( ( e1Node.side == Side.Left && e1Node.kind == PolyKind.Clip &&
						  e2Node.side == Side.Left && e2Node.kind == PolyKind.Subject ) ||
						( e1Node.side == Side.Left && e1Node.kind == PolyKind.Subject &&
						  e2Node.side == Side.Left && e2Node.kind == PolyKind.Clip ) )		// (LC ∩ LS) or (LS ∩ LC) → LI
			{
				addLeft ( e2Node, isec.p );
			} else if ( ( e1Node.side == Side.Right && e1Node.kind == PolyKind.Clip &&
						  e2Node.side == Side.Right && e2Node.kind == PolyKind.Subject ) ||
						( e1Node.side == Side.Right && e1Node.kind == PolyKind.Subject &&
						  e2Node.side == Side.Right && e2Node.kind == PolyKind.Clip ) )		// (RC ∩ RS) or (RS ∩ RC) → RI
			{
				addRight ( e1Node, isec.p );
			} else if ( ( e1Node.side == Side.Right && e1Node.kind == PolyKind.Subject &&
						  e2Node.side == Side.Left  && e2Node.kind == PolyKind.Clip ) ||
						( e1Node.side == Side.Right && e1Node.kind == PolyKind.Clip &&
						  e2Node.side == Side.Left  && e2Node.kind == PolyKind.Subject ) )	// (RS ∩ LC) or (RC ∩ LS) → MN
			{
				addLocalMax ( e1Node, e2Node, isec.p );
				e1Node.contributing = true;
				e2Node.contributing = true;
			}
			
			// Swap e1Node and e2Node position in AEL
			ActiveEdge.swap ( isec.e1Node, isec.e2Node );
			
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
			
			isec = isec.next;
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
	public function drawAelBySide ( graphics:Graphics ):Void {
		if ( cs_yb == null || cs_yt == null )
			return;
		
		var dy = cs_yt - cs_yb;
		var aelNode = ael;
		
		while ( aelNode != null ) {
			var e = aelNode.edge;
			var topX = topX ( aelNode, cs_yt );
			
			var color = aelNode.side == Side.Left ? 0xff0000 : 0x00ff00;
			graphics.lineStyle ( 1, color, 1 );
			graphics.moveTo ( aelNode.bottomXIntercept, cs_yb );
			graphics.lineTo ( topX, cs_yt );
			
			aelNode = aelNode.next;
		}
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
			var topX = topX ( aelNode, cs_yt );
			
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
		
		for ( poly in polys ) {
			beginDrawPoly ( graphics, stroke, strokeOpacity, strokeWidth,
				fill, fillOpacity );
			drawPoly ( poly, graphics );
			endDrawPoly ( graphics );
		}
	}
	
	public function drawCurrentScanbeam ( graphics:Graphics ):Void {
		if ( cs_yb != null ) {
			graphics.lineStyle ( 1, 0xaa9900, 1 );
			graphics.moveTo ( -10000, cs_yb );
			graphics.lineTo ( 10000, cs_yb );
		}
		
		if ( cs_yt != null ) {
			graphics.lineStyle ( 1, 0x99aa00, 1 );
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
	
	public function drawIntersectionScanline ( graphics:Graphics ):Void {
		if ( il == null )
			return;
		
		if ( cs_yb != null ) {
			graphics.lineStyle ( 0, 0, 0 );
			graphics.beginFill ( 0x0, 0.2 );
			graphics.drawRect ( -10000, cs_yb, 20000, il.p.y - cs_yb );
			graphics.endFill ();
		}
		
		graphics.lineStyle ( 1, 0xaa9977, 1 );
		graphics.moveTo ( -10000, il.p.y );
		graphics.lineTo ( 10000, il.p.y );
	}
	
	public function drawIntersections ( graphics:Graphics ):Void {
		var isec = il;
		graphics.lineStyle ( 0, 0, 0 );
		
		if ( isec != null ) {
			graphics.beginFill ( 0x5599ff, 1 );
			graphics.drawCircle ( isec.p.x, isec.p.y, 2 );
			graphics.endFill ();
			
			isec = isec.next;
		}
		
		while ( isec != null ) {
			graphics.beginFill ( 0x0000ff, 0.7 );
			graphics.drawCircle ( isec.p.x, isec.p.y, 2 );
			graphics.endFill ();
			
			isec = isec.next;
		}
	}
}