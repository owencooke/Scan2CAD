import os
import time
import trimesh
import numpy as np
from PySide6.QtGui import QVector3D

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
    loaded = tidyUpMesh(trimesh.load(self.check_url(selectedFile), force='mesh'))

    # Export model for loading in QML (only .glb or .gltf)
    out = os.path.join(self.basedir, "backend_resources/converted_mesh/" 
                        + outFilename(QMLpage, scanFlag) + ".glb")
    trimesh.exchange.export.export_mesh(loaded, out, file_type="glb")

    # Obtain dimensional parameters and centroid
    l = abs(loaded.bounds[0][0] - loaded.bounds[1][0])
    w = abs(loaded.bounds[0][1] - loaded.bounds[1][1])
    h = abs(loaded.bounds[0][2] - loaded.bounds[1][2])
    dim = QVector3D(l, w, h)
    centroid = QVector3D(loaded.centroid[0], loaded.centroid[1], loaded.centroid[2])

    # Output results to QML
    time.sleep(0.01)
    self.convertedMesh.emit(QMLpage, scanFlag, centroid, dim)

# Run ICP alignment algorithm between two meshes, output to GUI
def align_scan(self, cad, scan, cadMatrix, scanMatrix, scale):
    # Load each file into trimesh
    model = trimesh.load(self.check_url(cad), force='mesh')
    scanned = trimesh.load(self.check_url(scan), force='mesh')

    # Apply intial transformation matrices from GUI
    cadMatrix = np.array(cadMatrix.copyDataTo()).reshape(4,4)
    scanMatrix = np.array(scanMatrix.copyDataTo()).reshape(4,4)
    model.apply_transform(cadMatrix)
    scanned.apply_transform(scanMatrix)

    # Trim scan if necessary
    scanned = tidyUpMesh(scanned)

    # Align scan mesh relative to the model mesh, save result to disk
    t_matrix, cost = trimesh.registration.mesh_other(scanned, model, scale=scale) # samples=2000,icp_first=10, icp_final=500)
    scanned.apply_transform(t_matrix)

    # Convert and export files to be loaded
    cad = os.path.join(self.basedir, "backend_resources/converted_mesh/cad_align.glb")
    scan = os.path.join(self.basedir,"backend_resources/converted_mesh/scan_align.glb")
    trimesh.exchange.export.export_mesh(model, cad, file_type="glb")
    trimesh.exchange.export.export_mesh(scanned, scan, file_type="glb")

    # Calculate joint centroid
    x = (model.centroid[0] + scanned.centroid[0]) / 2
    y = (model.centroid[1] + scanned.centroid[1]) / 2
    z = (model.centroid[2] + scanned.centroid[2]) / 2
    centroid = QVector3D(x,y,z)

    # FIXME: calculate Hausdorff distance here / define similarity
    coeff = 50
    percent = 100/(1 + coeff*cost) #(0.1-cost)*1000 # Approximating percentage function
    if percent < 0: percent = 0

    # Emit signal containing data to QML 
    self.displayAligned.emit(centroid, cost, percent)