import os
import time
import trimesh
import numpy as np
from PySide6.QtGui import QVector3D #, QQuaternion
from backend_utils import check_url, qmatrix4x4_to_np, scale_from_matrix #, split_t_matrix

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
    loaded = trimesh.load(check_url(selectedFile), force='mesh')

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
def align_scan(self, cad, scan, cad_mat, scan_mat, scale, samples, iters):
    # Load each file into trimesh
    model = trimesh.load(check_url(cad), force='mesh')
    scanned = trimesh.load(check_url(scan), force='mesh')
    init_dim = scanned.extents

    # Apply intial transformation matrices from GUI
    cad_mat = qmatrix4x4_to_np(cad_mat)
    scan_mat = qmatrix4x4_to_np(scan_mat)
    model.apply_transform(cad_mat)
    scanned.apply_transform(scan_mat)

    # Check inputs for errors, assign default if error
    if samples <= 0:
        samples = 500
    if iters <= 0:
        iters = 50
        
    # Align scan mesh relative to the model mesh
    t_matrix, cost = trimesh.registration.mesh_other(scanned, model, samples, scale, icp_final=iters)

    # # DEBUG: show result in Trimesh viewer to verify with GUI result
    # scanned.apply_transform(t_matrix)
    # scanned.visual.vertex_colors = trimesh.visual.random_color()
    # trimesh.Scene([model, scanned]).show()

    # FIXME: remove this block when t_matrix can be applied to GUI properly
    scanned.apply_transform(t_matrix)
    scan_file = os.path.join(self.basedir,"backend_resources/_converted_mesh/scan_align.glb")
    trimesh.exchange.export.export_mesh(scanned, scan_file, file_type="glb")
    # Scale to get new dimensions for text output
    dim = init_dim * scale_from_matrix(scan_mat) * scale_from_matrix(t_matrix)
    centroid = QVector3D(*scanned.centroid)
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

def repair_mesh(self, cad_file, scan_file, cad_mat, scan_mat):
    cad = trimesh.load(check_url(cad_file), force='mesh')
    scan = trimesh.load(check_url(scan_file), force='mesh')

    cad_mat = qmatrix4x4_to_np(cad_mat)
    scan_mat = qmatrix4x4_to_np(scan_mat)
    cad.apply_transform(cad_mat)
    scan.apply_transform(scan_mat)

    # Repair algorithm
    closest_cad, unsign_dists, _ = trimesh.proximity.closest_point(cad, scan.vertices)
    repair_vertices = np.zeros(scan.vertices.shape)
    repair_normals = np.zeros(scan.vertices.shape)
    repairs = 0
    for idx, d in enumerate(unsign_dists):
        if d > 1: #1mm
            # Find unit direction vector from scan vertex to closest CAD point
            direction = closest_cad[idx] - scan.vertices[idx]
            # Double for new repair correction
            direction *= 2
            # Store new corrected vertex
            repair_vertices[repairs] = scan.vertices[idx] + direction
        else: 
            repair_vertices[repairs] = scan.vertices[idx]

        repair_normals[repairs] = scan.vertex_normals[idx]
        repairs += 1

    # Concatenate old CAD vertices with new repairs
    result = np.concatenate((cad.vertices, repair_vertices[:repairs]))
    result_normals = np.concatenate((cad.vertex_normals, repair_normals[:repairs]))
    # cloud = trimesh.points.PointCloud(result)
    cloud = trimesh.base.Trimesh(vertices=result, vertex_normals=result_normals)
    # trimesh.exchange.export.export_mesh(cloud, 'test.stl', file_type="stl", resolver=None)
    trimesh.Scene([cloud]).show()
