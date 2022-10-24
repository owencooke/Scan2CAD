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

def repair_mesh(self, cad_file, scan_file, cad_mat=QMatrix4x4(), 
                    scan_mat=QMatrix4x4(), samples=100000, thresh=0.5, combine=True):
    # Load files into Trimesh objects
    start_time = time.time()
    cad = trimesh_from_url(cad_file, cad_mat)
    scan = trimesh_from_url(scan_file, scan_mat)
    # Extract repair volumes to folder
    driver = RepairExtractor(cad, scan, samples, thresh)
    driver.extract_repairs()
    driver.export_volumes("test", combine, "stl")
    if self != None:
        self.volumes.emit()
    print("--- %s seconds ---" % (time.time() - start_time))

if __name__ == "__main__":
    # cad = QMatrix4x4(1, 0, 0, -12.5, 0, 1, 0, -12.710657119750977, 0, 0, 1, 12.730606079101562, 0, 0, 0, 1)
    # scan = QMatrix4x4(1, 0, 0, 0.20166169106960297, 0, 1, 0, 0.19201700389385223, 0, 0, 1, -12.594476699829102, 0, 0, 0, 1)
    # repair_mesh("C:/Users/owenc/Documents/LIMDA/models/cube.stl",
                    # "C:/Users/owenc/Documents/LIMDA/models/cube-modified.stl", cad, scan)
    # repair_mesh("C:/Users/owenc/Documents/LIMDA/models/bunny_CADalign.stl",
                    #    "C:/Users/owenc/Documents/LIMDA/models/bunny_scan_decimated.stl")

    # Lego brick CAD-CAD
    # cad = QMatrix4x4(1, 0, 0, 58.42201232910156, 0, 5.960464477539063e-08, -0.9999999403953552, 13.124993324279785, 0, 0.9999999403953552, 5.960464477539063e-08, -97.63247680664062, 0, 0, 0, 1)
    # scan = QMatrix4x4(1, 0, 0, 7.769808121338428e-07, 0, 5.960464477539063e-08, 0.9999999403953552, -13.564067840576172, 0, -0.9999999403953552, 5.960464477539063e-08, 4.024147983727744e-06, 0, 0, 0, 1)
    # repair_mesh(None, "C:/Users/owenc/Documents/LIMDA/models/brickv3.stl",
    #                  "C:/Users/owenc/Documents/LIMDA/models/extruded_brickv3.stl", cad, scan)

    # # Lego brick CAD-decimated scan (10000 faces)
    # cad = QMatrix4x4(0.9998477101325989, 0.017452405765652657, 0, 56.70919418334961, 0, 5.960464477539063e-08, -0.9999999403953552, 13.124993324279785, -0.017452405765652657, 0.9998475909233093, 5.960464477539063e-08, -98.63721466064453, 0, 0, 0, 1)
    # scan = QMatrix4x4(0.9999904632568359, 0.004363348241895437, 0, 0.2697169780731201, 0.004363348241895437, -0.9999904632568359, 8.742278367890322e-08, 4.106494426727295, 3.8145600567141e-10, -8.742194523847502e-08, -1, -0.19077567756175995, 0, 0, 0, 1)
    # repair_mesh(None, "C:/Users/owenc/Documents/LIMDA/models/brickv3.stl",
    #                  "C:/Users/owenc/Documents/LIMDA/models/brick_scan_dec.stl", cad, scan, samples=300)

    # New scans as of Oct. 14 (better holes)
    # cad = QMatrix4x4(1, 0, 0, 58.42201232910156, 0, 5.960464477539063e-08, 0.9999999403953552, -13.125004768371582, 0, -0.9999999403953552, 5.960464477539063e-08, 97.63247680664062, 0, 0, 0, 1)
    # scan = QMatrix4x4(-0.9998476505279541, 0, 0.017452457919716835, -0.4733637273311615, 0, 1, 0, 3.65578031539917, -0.017452457919716835, 0, -0.9998476505279541, 0.9392068386077881, 0, 0, 0, 1)
    # repair_mesh(None, "C:/Users/owenc/Documents/LIMDA/models/brickv3.stl",
    #                  "C:/Users/owenc/Documents/LIMDA/bricks/test1.stl", cad, scan, samples=300)

    # Tried to fix ideal CAD dimensions to printed part (PAPER)
    cad = QMatrix4x4(1, 0, 0, -1.9073486328125e-06, 0, 5.960464477539063e-08, 0.9999999403953552, -13.12500286102295, 0, -0.9999999403953552, 5.960464477539063e-08, -7.823111900506774e-07, 0, 0, 0, 1) 
    scan = QMatrix4x4(-0.9998733997344971, -0.00261781201697886, 0.015707235783338547, -0.4721300005912781, -0.0026181351859122515, 0.999996542930603, 0, 3.654583692550659, -0.01570718362927437, -4.112366514164023e-05, -0.999876856803894, 0.9400255084037781, 0, 0, 0, 1)
    repair_mesh(None, "C:/Users/owenc/Documents/LIMDA/ICRAI_results/ideal.stl",
                     "C:/Users/owenc/Documents/LIMDA/ICRAI_results/scan.stl", cad, scan, samples=300)