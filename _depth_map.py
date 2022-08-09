import numpy as np
import trimesh
from PySide6.QtQml import QmlElement
from PySide6.QtQuick3D import QQuick3DGeometry

QML_IMPORT_NAME = "PointCloud"
QML_IMPORT_MAJOR_VERSION = 1

''' Custom geometry that can be loaded into a Qt Quick 3D scene.
The geometry is a point cloud that uses colored points to represent
the distance/similarity between two 3D model files. '''
@QmlElement
class PointCloud(QQuick3DGeometry):
    def __init__(self):
        QQuick3DGeometry.__init__(self)
        self.setStride(1)

    def get_points(self, cad_file, scan_file, samples=10000):
        # Load new data from user input
        self.cad = trimesh.load(cad_file, force='mesh')
        self.scan = trimesh.load(scan_file, force='mesh')

        # Run vertex comparison algorithm
        self.closest, self.colors = self.sort_sampled_vertices(self.cad, self.scan, samples)

        # Init custom geometry format
        FLOAT_SIZE = 4
        stride = 7
        self.setStride(stride * FLOAT_SIZE)
        self.setPrimitiveType(QQuick3DGeometry.PrimitiveType.Points)

        # Combine all vertex information into a single array (1 index per vertex, w/ all info)
        data = np.concatenate((self.closest, self.colors), axis=1, dtype='float32')
        # Pass vertex data to byte stream
        self.setVertexData(data.tobytes())

        # Add attribute descriptors for data
        self.addAttribute(
            # Position (x,y,z)
            QQuick3DGeometry.Attribute.PositionSemantic, 0, QQuick3DGeometry.Attribute.F32Type
        )
        self.addAttribute(
            # Color (r,g,b,a)
            QQuick3DGeometry.Attribute.ColorSemantic, 3*FLOAT_SIZE, QQuick3DGeometry.Attribute.F32Type
        )

        # Update model in GUI
        self.update()

    def sort_sampled_vertices(self, cad, scan, samples):
        # Sample scan's vertices/surface
        scan_pts = self.key_points(scan, samples)

        # Find nearest CAD point to each scan point sampled
        # closest, distance, _ = cad.nearest.on_surface(scan_pts)

        d = cad.nearest.signed_distance(scan_pts)
        colors = np.zeros((samples, 4), dtype='float32')
        NUM_COLORS = 13
        min = np.min(d)
        thresh_level = (np.max(d) - min) / NUM_COLORS
        for count, dist in enumerate(d):
            if (-thresh_level < dist and dist < thresh_level):
                # Highly similar
                colors[count] = np.array(self.depth_color(0, 255))
            else:
                # Check whether over or under extrusion occured
                sign = 1
                if (-thresh_level > dist):
                # Points outside mesh have NEGATIVE distance
                    sign = -1
                for i in range(1, round(NUM_COLORS/2)+1):
                    if (dist > (sign*i*thresh_level)):
                        colors[count] = self.depth_color(sign*i, 255)
                        break
        # Return the closest CAD points, as well as their threshold colors 
        return scan_pts, colors

    # from Trimesh's registration.py module
    def key_points(self, m, count):
        """
        Return a combination of mesh vertices and surface samples
        with vertices chosen by likelihood to be important
        to registation.
        """
        if len(m.vertices) < (count / 2):
            return np.vstack((
                m.vertices,
                m.sample(count - len(m.vertices))))
        else:
            return m.sample(count)

    # def depth_color(self, index, ambience):
    #     # RGBA switch for distance thresholds
    #     # Change NUM_COLORS in sort_sampled_vertices() to
    #     # match the last case number
    #     case = {
    #         1: (19, 78, 19, ambience),
    #         2: (105, 179, 76, ambience),
    #         3: (172, 179, 52, ambience),
    #         4: (250, 183, 51, ambience),
    #         5: (255, 142, 21, ambience),
    #         6: (255, 78, 17, ambience),
    #         7: (255, 13, 13, ambience),
    #     }
    #     return tuple(i/255 for i in case[index])

    def depth_color(self, index, ambience):
        case = {
            # Purple to green
            6: (57, 30, 148, ambience),
            5: (29, 39, 145, ambience),
            4: (0, 55, 165, ambience),
            3: (33, 84, 238, ambience),
            2: (55, 150, 223, ambience),
            1: (71, 210, 204, ambience),
            # Green: Highly Similar (dist ~0)
            0: (19, 78, 19, ambience),
            # Green to red (over-extruded)
            -1: (105, 179, 76, ambience),
            -2: (172, 179, 52, ambience),
            -3: (250, 183, 51, ambience),
            -4: (255, 142, 21, ambience),
            -5: (255, 78, 17, ambience),
            -6: (255, 13, 13, ambience),
        }
        return tuple(i/255 for i in case[index])