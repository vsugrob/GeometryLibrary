package geom.clipper;
import flash.display.Graphics;
import flash.display.GraphicsPathCommand;
import flash.display.GraphicsPathWinding;
import flash.geom.Point;
import flash.Vector;
import geom.ChainedPolygon;
import geom.clipper.output.ClipOutput;
import geom.clipper.output.ClipOutputTriangles;
import geom.clipper.output.PrimitiveType;
import geom.ConcatIterator;
import geom.DoublyListNode;
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
	 * Bottom Y-coordinate of the current scanbeam.
	 */
	private var sbBottom:Float;
	/**
	 * Top Y-coordinate of the current scanbeam.
	 */
	private var sbTop:Float;
	/**
	 * Height of the current scanbeam.
	 */
	private var sbHeight:Float;
	/**
	 * Pointer to first node of the doubly-linked list of active edges i.e.
	 * non-horizontal edges that intersected by current scanbeam.
	 */
	private var ael:ActiveEdge;
	/**
	 * Pointer to first node of the doubly-linked list of horizontal edges
	 * lying at the bottom of current scanbeam.
	 */
	private var hel:DoublyListNode <ActiveEdge>;
	/**
	 * List of outputs formed during clipping operation.
	 */
	private var outputs:List <ClipOutput>;
	/**
	 * Number of currently contributing polygons. Necessary for output polygon
	 * index determination.
	 */
	private var numContribugingPolys:UInt;
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
	/**
	 * Fill rule used for PolyKind.Subject polygons.
	 */
	private var subjectFill:PolyFill;
	/**
	 * Fill rule used for PolyKind.Clip polygons.
	 */
	private var clipFill:PolyFill;
	/**
	 * Whether one of the fills ( subjectFill or clipFill ) uses winding rule.
	 */
	private var thereIsWindingFill:Bool;
	public var outputSettings:ClipOutputSettings;
	
	public inline function new ( outputSettings:ClipOutputSettings = null ) {
		this.outputs = new List <ClipOutput> ();
		this.outputSettings = outputSettings == null ? new ClipOutputSettings () : outputSettings;
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
		initLmlAndSbl ( poly, kind );
	}
	
	public function setFillRules ( subjectFill:PolyFill, clipFill:PolyFill ):Void {
		if ( this.subjectFill != subjectFill || this.clipFill != clipFill )
			clear ();
		
		this.subjectFill = subjectFill;
		this.clipFill = clipFill;
	}
	
	/**
	 * Clears added polygons and all data that was accumulated during last clip operation.
	 */
	public function clear ():Void {
		lml = null;
		sbl = null;
		ael = null;
		hel = null;
		outputs = new List <ClipOutput> ();
		numContribugingPolys = 0;
		il = null;
		ilLast = null;
	}
	
	public function clip ( operation:ClipOperation,
		subjectFill:PolyFill = null, clipFill:PolyFill = null,
		outputSettings:ClipOutputSettings = null ):Void
	{
		if ( outputSettings != null )
			this.outputSettings = outputSettings;
		
		if ( this.outputSettings.noOutput ) {
			// TODO: no need to process anything
		}
		
		if ( sbl == null )	// Scanbeam list is empty
			return;
		
		this.clipOp = operation;
		this.subjectFill = subjectFill == null ? PolyFill.EvenOdd : subjectFill;
		this.clipFill = clipFill == null ? PolyFill.EvenOdd : clipFill;
		this.thereIsWindingFill = this.subjectFill != PolyFill.EvenOdd || this.clipFill != PolyFill.EvenOdd;
		
		sbBottom = popScanbeam ();	// Bottom of the current scanbeam
		
		do {
			addNewBoundPairs ();		// Modifies ael
			processHorizontalEdges ();
			
			if ( sbl == null ) {
				// It is only possible when all polygons
				// are on the same horizontal line.
				
				return;
			}
			
			sbTop = popScanbeam ();	// Top of the current scanbeam
			sbHeight = sbTop - sbBottom;
			
			processIntersectionsInAel ();
			processEdgesInAel ();
			
			sbBottom = sbTop;
			sbHeight = 0;
			processHorizontalEdges ();
		} while ( sbl != null );
	}
	
	private function initLmlAndSbl ( pts:Iterable <Point>, kind:PolyKind ):Void {
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
	
	private inline function addLocalMaxima ( edge1:Edge, edge2:Edge, y:Float, kind:PolyKind ):Void {
		var lm = new LocalMaxima ( edge1, edge2, y, kind );
		
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
	
	private function addNewBoundPairs ():Void {
		while ( lml != null && lml.y == sbBottom ) {
			addEdgesToAel ( lml.edge1, lml.edge2, lml.kind );
			
			// Delete bound pair from lml
			var lm = lml;
			lml = lml.next;
			lm.next = null;
		}
	}
	
	public inline function getFillRule ( kind:PolyKind ):PolyFill {
		return	kind == PolyKind.Subject ? subjectFill : clipFill;
	}
	
	/**
	 * Add edges edge1 and edge2 (or their nonhorizontal successors) to active edge list maintaining increasing x order.
	 * Also set side and contributing fields of edge1 and edge2 using a parity argument.
	 * @param	edge1	Increasing edge.
	 * @param	edge2	Decreasing edge.
	 * @param	kind	Whether edges belong to subject or clip polygon?
	 */
	private function addEdgesToAel ( edge1:Edge, edge2:Edge, kind:PolyKind ):Void {
		var thisFill = getFillRule ( kind );
		var otherKind = kind == PolyKind.Subject ? PolyKind.Clip : PolyKind.Subject;
		var otherFill = getFillRule ( otherKind );
		
		// Calculate insideness
		var insideThis:Bool, insideOther:Bool;
		var numLikeEdges:Int = 0;
		var numUnlikeEdges:Int = 0;
		var thisWindingSum:Int = 0;
		var otherWindingSum:Int = 0;
		var closestContribNode:ActiveEdge = null;
		var aelNode = ael;
		var prevAelNode:ActiveEdge = null;
		
		if ( thisFill == PolyFill.EvenOdd ) {
			if ( otherFill == PolyFill.EvenOdd ) {
				while ( aelNode != null && aelNode.bottomXIntercept < edge1.bottomX ) {
					if ( aelNode.kind == kind )
						numLikeEdges++;
					else
						numUnlikeEdges++;
					
					if ( aelNode.output != null )
						closestContribNode = aelNode;
					
					prevAelNode = aelNode;
					aelNode = aelNode.next;
				}
				
				insideOther = numUnlikeEdges % 2 == 1;
			} else /*if ( otherFill == PolyFill.NonZero )*/ {
				while ( aelNode != null && aelNode.bottomXIntercept < edge1.bottomX ) {
					if ( aelNode.kind == kind )
						numLikeEdges++;
					else
						otherWindingSum = cast ( aelNode, ActiveWindingEdge ).windingSum;
					
					if ( aelNode.output != null )
						closestContribNode = aelNode;
					
					prevAelNode = aelNode;
					aelNode = aelNode.next;
				}
				
				insideOther = otherWindingSum != 0;
			}
			
			insideThis = numLikeEdges % 2 == 1;
		} else /*if ( thisFill == PolyFill.NonZero )*/ {
			if ( otherFill == PolyFill.EvenOdd ) {
				while ( aelNode != null && aelNode.bottomXIntercept < edge1.bottomX ) {
					if ( aelNode.kind == kind )
						thisWindingSum = cast ( aelNode, ActiveWindingEdge ).windingSum;
					else
						numUnlikeEdges++;
					
					if ( aelNode.output != null )
						closestContribNode = aelNode;
					
					prevAelNode = aelNode;
					aelNode = aelNode.next;
				}
				
				insideOther = numUnlikeEdges % 2 == 1;
			} else /*if ( otherFill == PolyFill.NonZero )*/ {
				while ( aelNode != null && aelNode.bottomXIntercept < edge1.bottomX ) {
					if ( aelNode.kind == kind )
						thisWindingSum = cast ( aelNode, ActiveWindingEdge ).windingSum;
					else
						otherWindingSum = cast ( aelNode, ActiveWindingEdge ).windingSum;
					
					if ( aelNode.output != null )
						closestContribNode = aelNode;
					
					prevAelNode = aelNode;
					aelNode = aelNode.next;
				}
				
				insideOther = otherWindingSum != 0;
			}
			
			insideThis = thisWindingSum != 0;
		}
		
		var likeEdgesEven:Bool;
		var contribVertex:Bool;
		
		if ( clipOp == ClipOperation.Intersection ) {
			likeEdgesEven = !insideThis;
			contribVertex = insideOther;
		} else if ( clipOp == ClipOperation.Difference ) {
			if ( !insideOther )
				contribVertex = kind == PolyKind.Subject;
			else
				contribVertex = kind == PolyKind.Clip;
			
			if ( kind == PolyKind.Subject )
				likeEdgesEven = !insideThis;
			else
				likeEdgesEven = insideThis;	// Invert sides
		} else if ( clipOp == ClipOperation.Union ) {
			likeEdgesEven = !insideThis;
			contribVertex = !insideOther;
		} else /*if ( clipOp == ClipOperation.Xor )*/ {
			likeEdgesEven = ( !insideThis ) == ( !insideOther );
			contribVertex = true;
		}
		
		var aelNode1:ActiveEdge, aelNode2:ActiveEdge;
		var aelWinNode1:ActiveWindingEdge, aelWinNode2:ActiveWindingEdge;
		
		if ( thisFill == PolyFill.EvenOdd ) {
			aelNode1 = new ActiveEdge ( edge1, kind );
			aelNode2 = new ActiveEdge ( edge2, kind );
		} else /*if ( thisFill == PolyFill.NonZero )*/ {
			aelWinNode1 = new ActiveWindingEdge ( edge1, kind );
			aelWinNode2 = new ActiveWindingEdge ( edge2, kind );
			aelWinNode1.winding = 1;
			aelWinNode2.winding = -1;
			aelNode1 = aelWinNode1;
			aelNode2 = aelWinNode2;
		}
		
		aelNode1.bottomXIntercept = edge1.bottomX;
		aelNode2.bottomXIntercept = edge1.bottomX;
		aelNode1.topXIntercept = edge1.bottomX;	// Top-x intercept necessary for buildHorizontalIntersectionList ().
		aelNode2.topXIntercept = edge1.bottomX;
		aelNode1.bottomY = sbBottom;
		aelNode2.bottomY = sbBottom;
		
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
		
		if ( thisFill == PolyFill.NonZero ) {
			// At this point order of aelNode1 and aelNode2 could be changed
			aelWinNode1 = cast ( aelNode1, ActiveWindingEdge );
			aelWinNode2 = cast ( aelNode2, ActiveWindingEdge );
			
			aelWinNode1.windingSum = thisWindingSum + aelWinNode1.winding;
			aelWinNode2.windingSum = aelWinNode1.windingSum + aelWinNode2.winding;
			
			if ( aelWinNode1.windingSum == 0 || aelWinNode2.windingSum == 0 ) {
				// If one thisWindingSum is zero then other is either +1 or -1
				aelWinNode1.isGhost = false;
				aelWinNode2.isGhost = false;
			} else {
				aelWinNode1.isGhost = true;
				aelWinNode2.isGhost = true;
				contribVertex = false;
			}
		}
		
		aelNode1.contributing = contribVertex;
		aelNode2.contributing = contribVertex;
		
		if ( contribVertex )
			processLocalMax ( aelNode1, aelNode2, closestContribNode, new Point ( edge1.bottomX, sbBottom ) );
	}
	
	private inline function addHorizontalEdge ( eNode:ActiveEdge ):Void {
		if ( hel == null )
			hel = new DoublyListNode <ActiveEdge> ( eNode );
		else
			hel.insertNext ( eNode );
	}
	
	private inline function processLocalMax ( e1Node:ActiveEdge, e2Node:ActiveEdge, closestContribNode:ActiveEdge, p:Point ):Void {
		var output = new ClipOutput ( outputSettings, numContribugingPolys++ );
		output.addLocalMax ( e1Node, e2Node, closestContribNode, p );
		
		e1Node.output = output;
		e2Node.output = output;
	}
	
	/**
	 * Active Edge List must have no horizontal edges.
	 */
	private function processEdgesInAel ():Void {
		if ( ael == null )
			return;
		
		var aelNode = ael;
		
		do {
			var edge = aelNode.edge;
			
			if ( edge.topY == sbTop ) {	// Edge terminates at the top of the scanbeam
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
					
					// Next edge should be also contributing and its topY should be equal to sbTop
					if ( aelNode.contributing )
						processLocalMin ( aelNode, aelNode.next, new Point ( edge.successor.bottomX, sbTop ) );
					
					var nextAelNode:ActiveEdge = aelNode.next.next;
					aelNode.removeNext ();
					aelNode.removeSelf ();
					
					if ( ael == aelNode )
						ael = nextAelNode;
					
					aelNode = nextAelNode;
					
					continue;
				} else {
					// Advance edge to its successor
					aelNode.edge = edge.successor;
					aelNode.bottomXIntercept = aelNode.edge.bottomX;
					aelNode.bottomY = sbTop;
					
					if ( aelNode.contributing ) {
						var p = new Point ( edge.successor.bottomX, sbTop );
						
						if ( aelNode.side == Side.Left )
							addPointToLeftBound ( aelNode, p );
						else
							addPointToRightBound ( aelNode, p );
					}
					
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
				
				// Next edge should be also contributing and its topY should be equal to sbTop
				if ( aelNode1.contributing )
					processLocalMin ( aelNode1, aelNode2, new Point ( edge.successor.bottomX, edge.topY ) );
				
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
				// Advance edge to its successor
				aelNode.edge = edge.successor;
				aelNode.bottomXIntercept = aelNode.edge.bottomX;
				
				if ( aelNode.contributing ) {
					var p = new Point ( edge.successor.bottomX, edge.topY );
					
					if ( aelNode.side == Side.Left )
						addPointToLeftBound ( aelNode, p );
					else
						addPointToRightBound ( aelNode, p );
				}
				
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
	
	private inline function processHorizontalEdges ():Void {
		while ( hel != null && ael != null ) {
			buildHorizontalIntersectionList ();
			processIntersectionList ();	// Zero-height scanbeam
			processEdgesInAelHorizontal ();
		}
	}
	
	// TODO: funcs addPointTo(Left/Right)Bound are redudant. Refactor.
	private inline function addPointToLeftBound ( aelNode:ActiveEdge, p:Point ):Void {
		aelNode.output.addPointToLeftBound ( p, aelNode );
	}
	
	private inline function addPointToRightBound ( aelNode:ActiveEdge, p:Point ):Void {
		aelNode.output.addPointToRightBound ( p, aelNode );
	}
	
	private inline function processLocalMin ( aelNode1:ActiveEdge, aelNode2:ActiveEdge, p:Point ):Void {
		aelNode1.output.addLocalMin ( aelNode1, aelNode2, p );
		
		if ( aelNode1.output != aelNode2.output )	// aelNode1 and aelNode2 have different output instances. Merge them.
			mergeOutput ( aelNode1, aelNode2 );
		else
			outputs.add ( aelNode1.output );
	}
	
	private function mergeOutput ( e1:ActiveEdge, f1:ActiveEdge ):Void {
		e1.output.merge ( f1.output, e1, f1 );
		
		var f2 = ael;
		
		do {
			if ( f2.output == f1.output && f2 != f1 ) {
				f2.output = e1.output;	// e1.output absorbed output of f2
				
				break;
			}
			
			f2 = f2.next;
		} while ( f2 != null );
	}
	
	private function processIntersectionsInAel ():Void {
		if ( ael == null )
			return;
		
		buildIntersectionList ();
		processIntersectionList ();
	}
	
	private function buildIntersectionList ():Void {
		il = null; // Initialize IL to empty;
		ilLast = null;
		
		// Set Sorted Edge List to first node in Active Edge List
		var selLeft = new DoublyListNode <ActiveEdge> ( ael );
		var selRight = selLeft;
		
		ael.topXIntercept = ael.topX ( sbTop );
		var e1Node = ael.next;
		
		while ( e1Node != null ) {
			e1Node.topXIntercept = e1Node.topX ( sbTop );
			
			/* Starting with the rightmost node of SEL we shall now move from right
			 * to left through the nodes of SEL checking for an intersection with e1.
			 * Let e2 denote the rightmost edge of SEL. */
			var e2Node = selRight;
			
			while ( e2Node != null && e1Node.topXIntercept < e2Node.value.topXIntercept ) {
				// Make deferred intersection.
				var isec = intersectionOf ( e2Node.value, e1Node );	// e2 is to the left of the e1 in the ael
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
		
		buildApexIntersections ( selLeft, selRight, true );
	}
	
	private function buildHorizontalIntersectionList ():Void {
		il = null; // Initialize IL to empty;
		ilLast = null;
		
		var helNode = hel;
		
		do {
			helNode.value.topXIntercept = helNode.value.edge.successor.bottomX;
			helNode = helNode.next;
		} while ( helNode != null );
		
		// Set Sorted Edge List to first node in Active Edge List
		var selLeft = new DoublyListNode <ActiveEdge> ( ael );
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
		
		buildApexIntersections ( selLeft, selRight, false );
	}
	
	/**
	 * Processes intersections lying exactly in local minimas which wasn't able to detect
	 * using standard algorithm such as buildIntersectionList ().
	 * @param	selLeft	First element of Sorted Edge List.
	 * @param	selRight	Last element of Sorted Edge List.
	 * @param	skipHorizontalPair	Should we skip terminating edge when its pairing edge is horizontal?
	 */
	private function buildApexIntersections ( selLeft:DoublyListNode <ActiveEdge>, selRight:DoublyListNode <ActiveEdge>, skipHorizontalPair:Bool ):Void {
		do {
			if ( selLeft.value.edge.topY == sbTop && selLeft.value.edge.successor.isLocalMinima () ) {
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
					/* There are two possible cases:
					 * 1. Other edge ending at local minima is horizontal while selLeft is not.
					 *	This case will be handled faster if skipHorizontalPair argument is set to true.
					 * 2. Both edges are horizontal but one of the bellows have more horizontal edges
					 * 	than the other and that's why it does not ends right now.
					 * We must defer its processing.*/
					
					if ( !otherEdge.isHorizontal )
						throw "Assertion failed";
					
					selLeft = selLeft.next;
					
					continue;
				}
				
				// Intersect right edge with all edges between bounds
				while ( selRight.prev != selLeft ) {
					/* Create Intersection object with intersection point already set.
					 * Since the point has already been calculated, it doesn't matter whether intersection was
					 * horizontal or not. */
					var isec = new Intersection ( selRight.prev.value, selRight.value,
						new Point ( lMin.bottomX, lMin.topY ), Math.POSITIVE_INFINITY );
					DoublyListNode.swapAdjacent ( selRight.prev, selRight );
					
					// Add isec to the END of the IL
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
	 * @param	e1Node	First edge AEL node known to intersect other edge.
	 * @param	e2Node	Second edge AEL node. Should be to the right of the e1 in Active Edge List!
	 * @return	Intersection of two edges.
	 */
	private static inline function intersectionOf ( e1Node:ActiveEdge, e2Node:ActiveEdge ):Intersection {
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
	
	private function processIntersectionList ():Void {
		while ( il != null ) {
			var isec = il;
			var prevIsec:Intersection = null;
			
			if ( !ActiveEdge.areAdjacent ( isec.e1Node, isec.e2Node ) ) {
				do {
					prevIsec = isec;
					isec = isec.next;
				} while ( !ActiveEdge.areAdjacent ( isec.e1Node, isec.e2Node ) );
			}
			
			processIntersection ( isec );
			
			// Swap e1Node and e2Node position in AEL
			ActiveEdge.swapAdjacent ( isec.e1Node, isec.e2Node );
			
			if ( isec.e1Node.prev == null )
				ael = isec.e1Node;
			else if ( isec.e2Node.prev == null )
				ael = isec.e2Node;
			
			if ( prevIsec == null )
				il = il.next;
			else
				prevIsec.next = isec.next;
		}
	}
	
	private function processIntersection ( isec:Intersection ):Void {
		// e1Node precedes e2Node in AEL
		var e1Node:ActiveEdge = isec.e1Node;
		var e2Node:ActiveEdge = isec.e2Node;
		var closestContribNode:ActiveEdge = null;
		
		if ( e1Node.kind == e2Node.kind ) {
			var thisFill = getFillRule ( e1Node.kind );
			
			if ( thisFill == PolyFill.EvenOdd ) {
				/* Like edge intersection:
				 * (LC × RC) or (RC × LC) → LI and RI
				 * (LS × RS) or (RS × LS) → LI and RI */
				swapOutputs ( e1Node, e2Node );
				swapSides ( e1Node, e2Node );
				
				if ( e1Node.contributing ) {			// Then e2Node is contributing also
					isec.calculateIntersectionPoint ( sbBottom, sbHeight );
					
					if ( e1Node.side == Side.Left ) {	// e2Node's side is right
						addPointToLeftBound ( e1Node, isec.p );
						addPointToRightBound ( e2Node, isec.p );
					} else {
						addPointToLeftBound ( e2Node, isec.p );
						addPointToRightBound ( e1Node, isec.p );
					}
				}
			} else /*if ( thisFill == PolyFill.NonZero )*/ {
				/* Classify self-intersection.
				 * Code below uses notation [Case #] to denote
				 * correponding illustration from "doc/nonzero_isecs.svg" file.*/
				var e1WinNode = e1Node.asWindingEdge;
				var e2WinNode = e2Node.asWindingEdge;
				var ws1:Int = AbsInt ( e1WinNode.windingSum );
				var ws2:Int = AbsInt ( e2WinNode.windingSum );
				
				if ( ws1 == 1 ) {
					if ( ws2 == 2 && e1WinNode.winding == e2WinNode.winding ) {	// 1 × 2 → LI, [Case 1 and 2]
						swapOutputs ( e1Node, e2Node );
						swapContribs ( e1Node, e2Node );
						e2Node.side = e1Node.side;	// Inherit side
						
						if ( e2Node.contributing ) {
							isec.calculateIntersectionPoint ( sbBottom, sbHeight );
							
							if ( e2Node.side == Side.Left )
								addPointToLeftBound ( e2Node, isec.p );
							else
								addPointToRightBound ( e2Node, isec.p );
						}
						
						e1WinNode.isGhost = true;
						e2WinNode.isGhost = false;
					} else /*if ( ws2 == 0 )*/ {
						if ( e1WinNode.winding == e2WinNode.winding ) {	// 1 × 0 (same winding) → RI, [Case 9 and 10]
							swapOutputs ( e1Node, e2Node );
							swapContribs ( e1Node, e2Node );
							e1Node.side = e2Node.side;	// Inherit side
							
							if ( e1Node.contributing ) {
								isec.calculateIntersectionPoint ( sbBottom, sbHeight );
								
								if ( e1Node.side == Side.Right )
									addPointToRightBound ( e1Node, isec.p );
								else
									addPointToLeftBound ( e1Node, isec.p );
							}
							
							e2WinNode.isGhost = true;
							e1WinNode.isGhost = false;
						} else {	// 1 × 0 (diff winding) → LI and RI, [Case 3 and 4]
							swapOutputs ( e1Node, e2Node );
							swapSides ( e1Node, e2Node );
							
							if ( e1Node.contributing ) {	// Then e2Node is also contributing
								isec.calculateIntersectionPoint ( sbBottom, sbHeight );
								
								if ( e1Node.side == Side.Left ) {	// Then e2Node's side is right
									addPointToLeftBound ( e1Node, isec.p );
									addPointToRightBound ( e2Node, isec.p );
								} else {
									addPointToRightBound ( e1Node, isec.p );
									addPointToLeftBound ( e2Node, isec.p );
								}
							}
						}
					}
				} else if ( ws1 == 0 /*&& ws2 == 1*/ ) {
					if ( e1WinNode.winding == e2WinNode.winding ) {	// 0 × 1 (same winding) → RI and LI, [Case 5 and 6]
						swapOutputs ( e1Node, e2Node );
						swapSides ( e1Node, e2Node );
						
						if ( e1Node.contributing ) {	// Then e2Node is also contributing
							isec.calculateIntersectionPoint ( sbBottom, sbHeight );
							
							if ( e1Node.side == Side.Right ) {	// Then e2Node's side is left
								addPointToRightBound ( e1Node, isec.p );
								addPointToLeftBound ( e2Node, isec.p );
							} else {
								addPointToLeftBound ( e1Node, isec.p );
								addPointToRightBound ( e2Node, isec.p );
							}
						}
					} else {	// 0 × 1 (diff winding) → MN, [Case 7 and 8]
						if ( e1Node.contributing ) {	// Then e2Node is also contributing
							isec.calculateIntersectionPoint ( sbBottom, sbHeight );
							
							processLocalMin ( e1Node, e2Node, isec.p );
							e1Node.contributing = false;
							e2Node.contributing = false;
							e1Node.output = null;
							e2Node.output = null;
						}
						
						e1WinNode.isGhost = true;
						e2WinNode.isGhost = true;
					}
				} else if ( ws1 == 2 && ws2 == 1 && e1WinNode.winding != e2WinNode.winding ) {	// 2 × 1 → MX, [Case 11 and 12]
					var thisKind = e1Node.kind;
					var otherKind = thisKind == PolyKind.Subject ? PolyKind.Clip : PolyKind.Subject;
					var otherFill = getFillRule ( otherKind );
					
					// Calculate insideness
					var insideThis:Bool, insideOther:Bool;
					var numLikeEdges:Int = 0;
					var numUnlikeEdges:Int = 0;
					var thisWindingSum:Int = 0;
					var otherWindingSum:Int = 0;
					var aelNode = e1Node.prev;
					
					if ( otherFill == PolyFill.EvenOdd ) {
						while ( aelNode != null ) {
							if ( aelNode.kind == otherKind )
								numUnlikeEdges++;
							
							if ( aelNode.output != null )
								closestContribNode = aelNode;
							
							aelNode = aelNode.prev;
						}
						
						insideOther = numUnlikeEdges % 2 == 1;
					} else /*if ( otherFill == PolyFill.NonZero )*/ {
						while ( aelNode != null ) {
							if ( closestContribNode == null && aelNode.output != null )
								closestContribNode = aelNode;
							
							if ( aelNode.kind == otherKind ) {
								otherWindingSum = cast ( aelNode, ActiveWindingEdge ).windingSum;
								aelNode = aelNode.prev;
								
								/* We've found otherWindingSum and no longer need this "if" branch
								 * so proceed to the next, more "lightweight" loop.*/
								break;
							}
							
							aelNode = aelNode.prev;
						}
						
						if ( closestContribNode == null ) {
							while ( aelNode != null ) {
								if ( aelNode.output != null ) {
									closestContribNode = aelNode;
									
									break;
								}
								
								aelNode = aelNode.prev;
							}
						}
						
						insideOther = otherWindingSum != 0;
					}
					
					thisWindingSum = e1WinNode.windingSum - e1WinNode.winding;
					insideThis = thisWindingSum != 0;
					
					var likeEdgesEven:Bool;
					var contribVertex:Bool;
					
					if ( clipOp == ClipOperation.Intersection ) {
						likeEdgesEven = !insideThis;
						contribVertex = insideOther;
					} else if ( clipOp == ClipOperation.Difference ) {
						if ( !insideOther )
							contribVertex = thisKind == PolyKind.Subject;
						else
							contribVertex = thisKind == PolyKind.Clip;
						
						if ( thisKind == PolyKind.Subject )
							likeEdgesEven = !insideThis;
						else
							likeEdgesEven = insideThis;	// Invert sides
					} else if ( clipOp == ClipOperation.Union ) {
						likeEdgesEven = !insideThis;
						contribVertex = !insideOther;
					} else /*if ( clipOp == ClipOperation.Xor )*/ {
						likeEdgesEven = ( !insideThis ) == ( !insideOther );
						contribVertex = true;
					}
					
					if ( likeEdgesEven ) {
						// e2Node will be to the left of e1Node after swapping
						e2Node.side = Side.Left;
						e1Node.side = Side.Right;
					} else {
						e1Node.side = Side.Left;
						e2Node.side = Side.Right;
					}
					
					if ( contribVertex ) {
						isec.calculateIntersectionPoint ( sbBottom, sbHeight );
						processLocalMax ( e2Node, e1Node, closestContribNode, isec.p );	// e2Node will be to the left of e1Node in AEL
						e1Node.contributing = true;
						e2Node.contributing = true;
					}
					
					e1WinNode.isGhost = false;
					e2WinNode.isGhost = false;
				}
				
				e1WinNode.windingSum = e2WinNode.windingSum;
				e2WinNode.windingSum -= e1WinNode.winding;
			}
		} else {
			// Check whether any of the edges is a ghost
			var thereIsGhost:Bool = thereIsWindingFill &&
				( ( e1Node.asWindingEdge != null && e1Node.asWindingEdge.isGhost ) ||
				  ( e2Node.asWindingEdge != null && e2Node.asWindingEdge.isGhost ) );
			
			if ( !thereIsGhost ) {
				isec.calculateIntersectionPoint ( sbBottom, sbHeight );
				
				if ( clipOp != ClipOperation.Xor ) {
					var isecType = isec.classify ( clipOp );
					
					switch ( isecType ) {
					case IntersectionType.LeftIntermediate:
						swapOutputs ( e1Node, e2Node );
						swapContribs ( e1Node, e2Node );
						
						if ( clipOp == ClipOperation.Union )
							addPointToLeftBound ( e2Node, isec.p );
						else
							addPointToLeftBound ( e1Node, isec.p );
					case IntersectionType.RightIntermediate:
						swapOutputs ( e1Node, e2Node );
						swapContribs ( e1Node, e2Node );
						
						if ( clipOp == ClipOperation.Union )
							addPointToRightBound ( e1Node, isec.p );
						else
							addPointToRightBound ( e2Node, isec.p );
					case IntersectionType.LocalMinima:
						processLocalMin ( e1Node, e2Node, isec.p );
						e1Node.contributing = false;
						e2Node.contributing = false;
						e1Node.output = null;
						e2Node.output = null;
					case IntersectionType.LocalMaxima:
						closestContribNode = seekClosestContributingPoly ( e1Node.prev );
						processLocalMax ( e2Node, e1Node, closestContribNode, isec.p );	// e2Node will be to the left of e1Node in AEL
						e1Node.contributing = true;
						e2Node.contributing = true;
					}
				} else {
					swapOutputs ( e1Node, e2Node );
					swapContribs ( e1Node, e2Node );
					swapSides ( e1Node, e2Node );
					
					if ( e1Node.side == Side.Left )
						addPointToLeftBound ( e1Node, isec.p );
					else
						addPointToRightBound ( e1Node, isec.p );
					
					if ( e2Node.side == Side.Left )
						addPointToLeftBound ( e2Node, isec.p );
					else
						addPointToRightBound ( e2Node, isec.p );
				}
			}
		}
	}
	
	private static inline function seekClosestContributingPoly ( aelNode:ActiveEdge ):ActiveEdge {
		var closestContribNode:ActiveEdge = null;
		
		while ( aelNode != null ) {
			if ( aelNode.output != null ) {
				closestContribNode = aelNode;
				
				break;
			}
			
			aelNode = aelNode.prev;
		}
		
		return	closestContribNode;
	}
	
	private static inline function swapSides ( e1Node:ActiveEdge, e2Node:ActiveEdge ):Void {
		var tmpSide = e1Node.side;
		e1Node.side = e2Node.side;
		e2Node.side = tmpSide;
	}
	
	private static inline function swapOutputs ( e1Node:ActiveEdge, e2Node:ActiveEdge ):Void {
		var tmpPoly = e1Node.output;
		e1Node.output = e2Node.output;
		e2Node.output = tmpPoly;
	}
	
	private static inline function swapContribs ( e1Node:ActiveEdge, e2Node:ActiveEdge ):Void {
		var tmpContrib = e1Node.contributing;
		e1Node.contributing = e2Node.contributing;
		e2Node.contributing = tmpContrib;
	}
	
	private static inline function AbsInt ( value:Int ):Int {
		return	value < 0 ? -value : value;
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
	
	public static function drawPoly ( pts:Iterable <Point>, graphics:Graphics, fill:PolyFill = null ):Void {
		if ( pts == null )
			return;
		
		var it = pts.iterator ();
		
		if ( !it.hasNext () )
			return;
		
		if ( fill == null )
			fill = PolyFill.EvenOdd;
		
		var cmds:Vector <Int> = new Vector <Int> ();
		var coords:Vector <Float> = new Vector <Float> ();
		var p = it.next ();
		var pFirst = p;
		cmds.push ( GraphicsPathCommand.MOVE_TO );
		coords.push ( p.x );
		coords.push ( p.y );
		
		while ( it.hasNext () ) {
			p = it.next ();
			cmds.push ( GraphicsPathCommand.LINE_TO );
			coords.push ( p.x );
			coords.push ( p.y );
			
			//graphics.drawCircle ( p.x, p.y, 2 );
		}
		
		cmds.push ( GraphicsPathCommand.LINE_TO );
		coords.push ( pFirst.x );
		coords.push ( pFirst.y );
		
		graphics.drawPath ( cmds, coords, fill == PolyFill.EvenOdd ? GraphicsPathWinding.EVEN_ODD : GraphicsPathWinding.NON_ZERO );
	}
	
	public static function drawTriangles ( triOut:ClipOutputTriangles, graphics:Graphics, strokeWidth:Float = 1 ):Void {
		if ( triOut == null )
			return;
		
		var primIt = triOut.primities.iterator ();
		
		if ( !primIt.hasNext () )
			return;
		
		while ( primIt.hasNext () ) {
			var primitive = primIt.next ();
			var it = primitive.points.iterator ();
			var p0:Point, p1:Point, p2:Point;
			
			p0 = it.next ();
			p1 = it.next ();
			
			do {
				p2 = it.next ();
				
				graphics.beginFill ( primitive.type == PrimitiveType.TriangleStrip ? 0x00ff00 : 0xff0000, 0.5 );
				graphics.lineStyle ( strokeWidth, 0, 1 );
				
				graphics.moveTo ( p0.x, p0.y );
				graphics.lineTo ( p1.x, p1.y );
				graphics.lineTo ( p2.x, p2.y );
				graphics.lineTo ( p0.x, p0.y );
				
				graphics.endFill ();
				
				if ( primitive.type == PrimitiveType.TriangleStrip ) {
					p0 = p1;
					p1 = p2;
				} else if ( primitive.type == PrimitiveType.TriangleFan )
					p1 = p2;
			} while ( it.hasNext () );
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
		for ( output in outputs ) {
			beginDrawPoly ( graphics, null, 1, 2, null, 0.5 );
			drawPoly ( output.polyOut, graphics );
			endDrawPoly ( graphics );
		}
	}
	
	public function drawOutTriangles ( graphics:Graphics, strokeWidth:Float = 1 ):Void {
		for ( output in outputs ) {
			drawTriangles ( output.triOut, graphics, strokeWidth );
		}
	}
	
	public function drawContributedPolys ( graphics:Graphics,
		stroke:Null <UInt> = null, strokeOpacity:Float = 1, strokeWidth:Float = 1,
		fill:Null <UInt> = null, fillOpacity = 0.5, emphasizeHoles:Bool = false ):Void
	{
		var allOutputs = new List <ClipOutput> ();
		var aelNode = ael;
		
		while ( aelNode != null ) {
			if ( aelNode.output != null ) {
				if ( !Lambda.has ( allOutputs, aelNode.output ) )
					allOutputs.add ( aelNode.output );
			}
			
			aelNode = aelNode.next;
		}
		
		for ( output in outputs ) {
			if ( !Lambda.has ( allOutputs, output ) )
				allOutputs.add ( output );
		}
		
		// Draw fills
		beginDrawPoly ( graphics, null, 0.0, 0.0,
			fill, fillOpacity );
		
		for ( output in allOutputs ) {
			drawPoly ( output.polyOut, graphics );
		}
		
		endDrawPoly ( graphics );
		
		// Draw strokes
		for ( output in allOutputs ) {
			var effectiveStrokeColor:Null <UInt>;
			
			if ( emphasizeHoles && output.polyOut.isHole )
				effectiveStrokeColor = 0xff0000;
			else
				effectiveStrokeColor = stroke;
			
			beginDrawPoly ( graphics, effectiveStrokeColor, strokeOpacity, strokeWidth, 0, 0.0 );
			drawPoly ( output.polyOut, graphics );
			endDrawPoly ( graphics );
		}
	}
}