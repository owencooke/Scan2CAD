import os
import time
import trimesh
import numpy as np
from PySide6.QtGui import QVector3D, QQuaternion
from backend_utils import check_url, qmatrix4x4_to_np, split_t_matrix

_AXES2TUPLE = {
    'sxyz': (0, 0, 0, 0), 'sxyx': (0, 0, 1, 0), 'sxzy': (0, 1, 0, 0),
    'sxzx': (0, 1, 1, 0), 'syzx': (1, 0, 0, 0), 'syzy': (1, 0, 1, 0),
    'syxz': (1, 1, 0, 0), 'syxy': (1, 1, 1, 0), 'szxy': (2, 0, 0, 0),
    'szxz': (2, 0, 1, 0), 'szyx': (2, 1, 0, 0), 'szyz': (2, 1, 1, 0),
    'rzyx': (0, 0, 0, 1), 'rxyx': (0, 0, 1, 1), 'ryzx': (0, 1, 0, 1),
    'rxzx': (0, 1, 1, 1), 'rxzy': (1, 0, 0, 1), 'ryzy': (1, 0, 1, 1),
    'rzxy': (1, 1, 0, 1), 'ryxy': (1, 1, 1, 1), 'ryxz': (2, 0, 0, 1),
    'rzxz': (2, 0, 1, 1), 'rxyz': (2, 1, 0, 1), 'rzyz': (2, 1, 1, 1)}
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
    loaded = tidyUpMesh(trimesh.load(check_url(selectedFile), force='mesh'))

    # Export model for loading in QML (only .glb or .gltf)
    out = os.path.join(self.basedir, "backend_resources/_converted_mesh/" 
                        + outFilename(QMLpage, scanFlag) + ".glb")
    trimesh.exchange.export.export_mesh(loaded, out, file_type="glb")

    # Obtain dimensional parameters and centroid
    l = abs(loaded.bounds[0][0] - loaded.bounds[1][0])
    w = abs(loaded.bounds[0][1] - loaded.bounds[1][1])
    h = abs(loaded.bounds[0][2] - loaded.bounds[1][2])
    dim = QVector3D(l, w, h)
    centroid = QVector3D(*loaded.centroid)

    # Output results to QML
    time.sleep(0.01)
    self.convertedMesh.emit(QMLpage, scanFlag, centroid, dim)

# Run ICP alignment algorithm between two meshes, output to GUI
def align_scan(self, cad, scan, cad_mat, scan_mat, scale, samples, iters):
    # Load each file into trimesh
    model = trimesh.load(check_url(cad), force='mesh')
    scanned = trimesh.load(check_url(scan), force='mesh')

    # Apply intial transformation matrices from GUI
    cad_mat = qmatrix4x4_to_np(cad_mat)
    scan_mat = qmatrix4x4_to_np(scan_mat)
    model.apply_transform(cad_mat)
    scanned.apply_transform(scan_mat)
    scanned.visual.vertex_colors = trimesh.visual.random_color()
    trimesh.Scene([model, scanned]).show()

    # Check inputs for errors, assign default if error
    if samples <= 0:
        samples = 500
    if iters <= 0:
        iters = 50
        
    # Align scan mesh relative to the model mesh, save result to disk
    t_matrix, cost = trimesh.registration.mesh_other(scanned, model, samples, scale, icp_final=iters)

    # DEBUG: show result in Trimesh viewer to verify with GUI result
    scanned.apply_transform(t_matrix)
    scanned.visual.vertex_colors = trimesh.visual.random_color()
    trimesh.Scene([model, scanned]).show()

    # Decompose matrix into singular transforms for GUI
    #for combo in _AXES2TUPLE:
    scale, rotation, translation = split_t_matrix(t_matrix, combo=None)

    # Convert to Qt data types and output to GUI via signal
    scale = QVector3D(*scale)
    translation = QVector3D(*translation)
    rotation = QQuaternion(*rotation)
    #rotation = QVector3D(*(np.array(rotation) * 180 / np.pi))
    self.displayAligned.emit(translation, scale, rotation, cost)

    # time.sleep(3)
    # self.fixRot.emit(translation, rotation)
    # time.sleep(1)
