#from pyspatiotemporalgeom.utilities.triangleLibrary import triangle3DTriangle3DIntersection as faces_intersect
import math
import numpy as np

def segment3DTriangle3DIntersection( seg, tri ):
    ray = seg   
        
    # easy test.  if the ray is a tri seg, return not intersecting
    # we don't consider a ray that is identical to a triangle edge to be intersecting
    tsegs = np.array(((tri[0], tri[1] ), (tri[1], tri[0] ), (tri[0], tri[2] ), (tri[2], tri[0] ), (tri[1], tri[2] ), (tri[2], tri[1] )))
    if ray in tsegs:
            return 0,None

    
    SMALL_NUM = 0.00000001
    #u v n will be triangle vectors
    # dir, w0 and w will be ray vectors
    # r, a, b will be params to calc ray-plane intersect
    
    # get triangle edge vects and normal to plane
    u = np.array((tri[1][0]-tri[0][0], tri[1][1]-tri[0][1], tri[1][2]-tri[0][2]))
    v = np.array((tri[2][0]-tri[0][0], tri[2][1]-tri[0][1], tri[2][2]-tri[0][2]))
    n = np.cross(u,v)
    if np.array_equal(n, np.array((0,0,0))):
            return -1,None #degenerate
    dir = (ray[1][0]-ray[0][0], ray[1][1]-ray[0][1], ray[1][2]-ray[0][2]) #ray direction vect
    w0 = (ray[0][0]-tri[0][0], ray[0][1]-tri[0][1], ray[0][2]-tri[0][2])
    a = float( -1*np.dot( n, w0 ) )
    b = float( np.dot( n, dir ) )
    if math.fabs( b ) < SMALL_NUM: #ray is parallel to tri
            if a == 0:  # ray lies in tri
                    return 2,None  # ray overlaps the triangle
            else:
                    return 0,None #ray disjoint from plane
    # get intersect point of ray with triangle plane
    r = a/float(b)
    #check if intersect is beyond end of seg.  For a ray, only test with 0.0
    # we use <= and >= becuase we don't care abount end point intersections
    if r <= 0.0 or r >= 1.0: 
            return 0,None
    #get the intersection point of the seg and plane
    I = ( ray[0][0]+r*dir[0], ray[0][1]+r*dir[1], ray[0][2]+r*dir[2]  )
    #find if the point is inside the tri
    uu = np.dot( u, u)
    uv = np.dot( u, v)
    vv = np.dot( v, v)
    w = ( I[0]-tri[0][0], I[1]-tri[0][1], I[2]-tri[0][2] )
    wu = np.dot( w, u)
    wv = np.dot( w, v)
    D = uv*uv - uu*vv
    # get and test the parametric coords
    s = (uv*wv - vv*wu)/float(D)
    if s < 0.0 or s > 1.0: # I is outside tri
            return 0,None
    t = (uv*wu - uu*wv)/float(D)
    if t < 0.0 or (s+t) > 1.0: # I is outside tri
            return 0,None
    return 1,I  # intersection!  I is in the tri

def unit_direction(p1, p2):
    v = p2 - p1
    norm = np.linalg.norm(v)
    if norm != 0:
        v = np.divide(v, norm)
    return v

def shared_edges(seg1, seg2):
    # Get normalized direction vectors for each segment
    u1 = unit_direction(seg1[1], seg1[0])
    u2 = unit_direction(seg2[1], seg2[0])
    # Unit vectors must be parallel 
    if np.array_equal(u1, u2) or np.array_equal(u1, -u2):
        # All vectors b/w vertices should match the direction
        sameDir = True
        for p1 in seg1:
            for p2 in seg2:
                u = unit_direction(p1, p2)
                if not np.array_equal(u, dir):
                    sameDir = False
        return sameDir
    else:
        return False

# from Geometrics
# https://github.com/EdwardSmith1884/GEOMetrics/blob/master/LICENSE
def PointInAABB(pt, c1, c2):
  return c2[0] <= pt[0] <= c1[0] and \
		 c2[1] <= pt[1] <= c1[1]

def PointInTriangle(tri, pt):
    v1, v2, v3 = tri
    b1 = sign(pt, v1, v2) <= 0
    b2 = sign(pt, v2, v3) <= 0
    b3 = sign(pt, v3, v1) <= 0

    return ((b1 == b2) and (b2 == b3)) and \
		 PointInAABB(pt, tri.max(0), tri.min(0))

def sign(p1, p2, p3):
  return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
#####################################################################

def faces_intersect(tri1, tri2):
    # T1 Segments
    t1s1 = (tri1[0], tri1[2])
    t1s2 = (tri1[1], tri1[2])
    t1s3 = (tri1[0], tri1[1])
    # T2 Segments
    t2s1 = (tri2[0], tri2[2])
    t2s2 = (tri2[1], tri2[2])
    t2s3 = (tri2[0], tri2[1])

    if segment3DTriangle3DIntersection( t1s1, tri2 )[0] > 0:
            return True
    elif segment3DTriangle3DIntersection( t1s2, tri2 )[0] > 0:
            return True
    elif segment3DTriangle3DIntersection( t2s1, tri1 )[0] > 0:
            return True
    elif segment3DTriangle3DIntersection( t2s2, tri1 )[0] > 0:
            return True

    # Pyspatio does not return true if edges shared
    for seg1 in [t1s1, t1s2, t1s3]:
        for seg2 in [t2s1, t2s2, t2s3]:
            if shared_edges(seg1, seg2):
                return True

    # Pyspatio does not return true if vertex on other triangle
    for v in tri1:
        if v in tri2:
            return True
        else: 
            if PointInTriangle(tri2, v):
                return True
    return False

if __name__ == "__main__":
    # t1 = np.array(( 
    #     (6,8,-2),
    #     (0,5,0),
    #     (5,0,0)
    # ))

    # t1 = np.array(( 
    #     (6,8,-2),
    #     (7,4,3),
    #     (12,4,3)
    # ))

    t1 = np.array(( 
        (2,0,5),
        (2,0,-.01),
        (2,0.1,-0.1)
    ))

    t2 = np.array((
        (0,5,0),
        (0,0,0),
        (5,0,0)
    ))

    print(faces_intersect(t1, t2))