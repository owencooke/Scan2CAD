import os
import time
import trimesh
import numpy as np
from PySide6.QtGui import QVector3D, QMatrix4x4 #, QQuaternion
from backend_utils import scale_from_matrix, trimesh_from_url, qmatrix4x4_to_np #, split_t_matrix
from trimesh.util import type_named, append_faces
from _repair_volume import RepairExtractor


# Determine output file type/destination
def outFilename(page, scan):
    case = {
        "Model3D": ["cad_model3D", "scan_model3D"],
        "Align": ["cad_align", "scan_align"],
    }
    return case[page][scan]

# Eliminates pieces that have less than a min # of connected components
def tidyUpMesh(mesh, min_len=5000):
    try: 
        cc = trimesh.graph.connected_components(mesh.face_adjacency, min_len)
        mask = np.zeros(len(mesh.faces), dtype=bool)
        mask[np.concatenate(cc)] = True
        mesh.update_faces(mask)
    # No unconnected components found
    except (ValueError, AttributeError):
        pass
    return mesh

# Load 3D model into GUI and calculate its dimensional attributes
def load3D(self, QMLpage, selectedFile, scanFlag):
    # Load mesh
    loaded = trimesh_from_url(selectedFile)

    # Export model for loading in QML (only .glb or .gltf)
    out = os.path.join(self.basedir, "backend_resources/_converted_mesh/" 
                        + outFilename(QMLpage, scanFlag) + ".glb")
    trimesh.exchange.export.export_mesh(loaded, out, file_type="glb")

    # Obtain dimensional parameters and centroid
    dim = QVector3D(*loaded.extents)
    centroid = QVector3D(*loaded.centroid)

    # Output results to QML
    time.sleep(0.01)
    self.convertedMesh.emit(QMLpage, scanFlag, centroid, dim)

# Run ICP alignment algorithm between two meshes, output to GUI
def align_scan(self, cad_url, scan_url, cad_mat, scan_mat, scale, samples, iters):
    # Load each file into trimesh
    cad = trimesh_from_url(cad_url, cad_mat)
    scan, init_dim = trimesh_from_url(scan_url, scan_mat, True)

    # Check inputs for errors, assign default if error
    if samples <= 0:
        samples = 500
    if iters <= 0:
        iters = 50
        
    # Align scan mesh relative to the model mesh
    t_matrix, cost = trimesh.registration.mesh_other(scan, cad, samples, scale, icp_final=iters)

    # # DEBUG: show result in Trimesh viewer to verify with GUI result
    # scanned.apply_transform(t_matrix)
    # scanned.visual.vertex_colors = trimesh.visual.random_color()
    # trimesh.Scene([model, scanned]).show()

    # FIXME: remove this block when t_matrix can be applied to GUI properly
    scan.apply_transform(t_matrix)
    scan_url = os.path.join(self.basedir,"backend_resources/_converted_mesh/scan_align.glb")
    trimesh.exchange.export.export_mesh(scan, scan_url, file_type="glb")
    # Scale to get new dimensions for text output
    dim = init_dim * scale_from_matrix(qmatrix4x4_to_np(scan_mat)) * scale_from_matrix(t_matrix)
    centroid = QVector3D(*scan.centroid)
    self.displayAligned.emit(centroid, QVector3D(*dim), cost)
    ####

    # # Decompose matrix into singular transforms for GUI
    # scale, rotation, translation = split_t_matrix(t_matrix)
   
    # # Convert to Qt data types and output to GUI via signal
    # scale = QVector3D(*scale)
    # translation = QVector3D(*translation)
    # rotation = QQuaternion(*rotation)
    # #rotation = QVector3D(*rotation) # for Euler angles
    # self.displayAligned.emit(translation, scale, rotation, cost)

def repair_mesh(cad_file, scan_file, cad_mat=QMatrix4x4(), scan_mat=QMatrix4x4(), samples=100000, thresh=0.5):
    cad = trimesh_from_url(cad_file, cad_mat)
    scan = trimesh_from_url(scan_file, scan_mat)

    # result = trimesh.boolean.difference([cad, scan], engine='scad')
    # trimesh.Scene([result]).show()
    # result = trimesh.boolean.difference([scan, cad], engine='scad')
    # trimesh.Scene([result]).show()

    driver = RepairExtractor(cad, scan, samples, thresh)
    driver.extract_repairs()
    driver.export_volumes("test")

if __name__ == "__main__":
    # cad = QMatrix4x4(1, 0, 0, -12.5, 0, 1, 0, -12.710657119750977, 0, 0, 1, 12.730606079101562, 0, 0, 0, 1)
    # scan = QMatrix4x4(1, 0, 0, 0.20166169106960297, 0, 1, 0, 0.19201700389385223, 0, 0, 1, -12.594476699829102, 0, 0, 0, 1)
    # repair_mesh("C:/Users/owenc/Documents/LIMDA/models/cube.stl",
    #                 "C:/Users/owenc/Documents/LIMDA/models/cube-modified.stl", cad, scan)#, thresh=0.5, samples=100000)
    # repair_mesh("C:/Users/owenc/Documents/LIMDA/models/bunny_CADalign.stl",
                    #    "C:/Users/owenc/Documents/LIMDA/models/bunny_scan_decimated.stl")#, thresh=0.5, samples=100000)
    cad = QMatrix4x4(1, 0, 0, -75, 0, 1, 0, -24, 0, 0, 1, -25, 0, 0, 0, 1)
    scan = QMatrix4x4(1, 0, 0, -74.86064147949219, 0, 1, 0, -23.787559509277344, 0, 0, 1, -24.99203872680664, 0, 0, 0, 1)
    repair_mesh("C:/Users/owenc/Documents/LIMDA/models/lego_smooth.stl",
                    "C:/Users/owenc/Documents/LIMDA/models/lego.stl", cad, scan)