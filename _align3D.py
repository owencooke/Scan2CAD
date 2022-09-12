import os
import time
import trimesh
import csv
import numpy as np
from PySide6.QtGui import QVector3D, QMatrix4x4 #, QQuaternion
from backend_utils import check_url, qmatrix4x4_to_np, scale_from_matrix #, split_t_matrix
from trimesh.util import type_named, append_faces

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
    trimesh.exchange.export.export_mesh(model, "bunny_CADalign.stl", file_type="stl")
    trimesh.exchange.export.export_mesh(scanned, "bunny_SCANalign.stl", file_type="stl")
    # # Decompose matrix into singular transforms for GUI
    # scale, rotation, translation = split_t_matrix(t_matrix)
   
    # # Convert to Qt data types and output to GUI via signal
    # scale = QVector3D(*scale)
    # translation = QVector3D(*translation)
    # rotation = QQuaternion(*rotation)
    # #rotation = QVector3D(*rotation) # for Euler angles
    # self.displayAligned.emit(translation, scale, rotation, cost)

def submesh(mesh,
            faces_sequence,
            repair=True,
            only_watertight=False,
            min_faces=None,
            append=False):
    """
    Return a subset of a mesh.
    Parameters
    ------------
    mesh : Trimesh
        Source mesh to take geometry from
    faces_sequence : sequence (p,) int
        Indexes of mesh.faces
    repair : bool
        Try to make submeshes watertight
    only_watertight : bool
        Only return submeshes which are watertight
    append : bool
        Return a single mesh which has the faces appended,
        if this flag is set, only_watertight is ignored
    Returns
    ---------
    if append : Trimesh object
    else        list of Trimesh objects
    """
    # evaluate generators so we can escape early
    faces_sequence = list(faces_sequence)

    if len(faces_sequence) == 0:
        return []

    # avoid nuking the cache on the original mesh
    original_faces = mesh.faces.view(np.ndarray)
    original_vertices = mesh.vertices.view(np.ndarray)

    faces = []
    vertices = []
    normals = []
    visuals = []

    # for reindexing faces
    mask = np.arange(len(original_vertices))

    for index in faces_sequence:
        # sanitize indices in case they are coming in as a set or tuple
        index = np.asanyarray(index)
        # if len(index) == 0:
        #     # regardless of type empty arrays are useless
        #     continue
        if index.dtype.kind == 'b':
            # if passed a bool with no true continue
            if not index.any():
                continue
            # if fewer faces than minimum
            if min_faces is not None and index.sum() < min_faces:
                continue
        elif min_faces is not None and len(index) < min_faces:
            continue

        current = original_faces[index]
        unique = np.unique(current.reshape(-1))

        # redefine face indices from zero
        mask[unique] = np.arange(len(unique))
        normals.append(mesh.face_normals[index])
        faces.append(mask[current])
        vertices.append(original_vertices[unique])
        visuals.append(mesh.visual.face_subset(index))

    if len(vertices) == 0:
        return np.array([])

    # we use type(mesh) rather than importing Trimesh from base
    # to avoid a circular import
    trimesh_type = type_named(mesh, 'Trimesh')
    if append:
        visual = None
        try:
            visuals = np.array(visuals)
            visual = visuals[0].concatenate(visuals[1:])
        except BaseException:
            pass
        # re-index faces and stack
        vertices, faces = append_faces(vertices, faces)
        appended = trimesh_type(
            vertices=vertices,
            faces=faces,
            face_normals=np.vstack(normals),
            visual=visual,
            process=False)
        return appended

def check_connected_faces(idx, faces, cc_hash, thresh, cad, scan):
    # Base condition
    _, dist, _ = trimesh.proximity.closest_point(cad, scan.triangles_center[idx])
    if dist[0] <= thresh:
        return faces
    else: 
        # Nearest face not within threshold, add to list
        faces.append(idx)
        # Search all of its connected components not already in list
        for f in cc_hash[idx]:
            if f not in faces:
                faces = check_connected_faces(f, faces, cc_hash, thresh, cad, scan)
            return faces

def mesh_from_faces(faces, cc_hash, thresh, cad, scan):
    # Recursively find connected components out of thresh range
    for f in faces:
        if f not in faces:
            faces = check_connected_faces(f, faces, cc_hash, thresh, cad, scan)
    # Create output mesh
    out = submesh(scan, faces, append=True)
    out.fill_holes()
    out.fix_normals()
    return out

def repair_mesh(cad_file, scan_file, cad_mat=QMatrix4x4(), scan_mat=QMatrix4x4(), samples=100000, thresh=0.5):
    cad = trimesh.load(check_url(cad_file), force='mesh')
    scan = trimesh.load(check_url(scan_file), force='mesh')

    cad_mat = qmatrix4x4_to_np(cad_mat)
    scan_mat = qmatrix4x4_to_np(scan_mat)
    cad.apply_transform(cad_mat)
    scan.apply_transform(scan_mat)

    # Sample points
    sample_points, faces = scan.sample(samples, return_index=True)

    # Determine which faces on scan are "errors"
    dists = cad.nearest.signed_distance(sample_points)
    over_faces = []
    under_faces = []
    for idx, d in enumerate(dists):
        if d > thresh:
            # Under extruded
            under_faces.append(faces[idx])
        elif d < -thresh: 
            # Over extruded
            over_faces.append(faces[idx])
    
    # Create hash map for connected faces on scan
    cc_hash = {}
    for key, shared in trimesh.graph.face_adjacency(mesh=scan):
        if key in cc_hash:
            cc_hash[key].append(shared)
        else:
            cc_hash[key] = [shared]
    
    # Create additive/subtractive repair meshes
    under = mesh_from_faces(under_faces, cc_hash, thresh, cad, scan)
    over = mesh_from_faces(over_faces, cc_hash, thresh, cad, scan)

    over.visual.vertex_colors = np.array((255, 13, 13, 255))
    under.visual.vertex_colors = np.array((30, 38, 145, 255))
    
    trimesh.Scene([over, under]).show()
    print('exporting')
    trimesh.exchange.export.export_mesh(over.copy(), "test/over.glb", file_type="glb")
    trimesh.exchange.export.export_mesh(under.copy(), "test/under.glb", file_type="glb")
    print('done')

if __name__ == "__main__":
    # q = QMatrix4x4()
    # cad = QMatrix4x4(1, 0, 0, -12.5, 0, 1, 0, -12.710657119750977, 0, 0, 1, 12.730606079101562, 0, 0, 0, 1)
    # scan = QMatrix4x4(1, 0, 0, 0.20166169106960297, 0, 1, 0, 0.19201700389385223, 0, 0, 1, -12.594476699829102, 0, 0, 0, 1)
    # repair_mesh("C:/Users/owenc/Documents/LIMDA/models/cube.stl",
    #                 "C:/Users/owenc/Documents/LIMDA/models/cube-modified.stl", cad, scan)#, thresh=0.5, samples=100000)
    repair_mesh("C:/Users/owenc/Documents/LIMDA/models/bunny_CADalign.stl",
                       "C:/Users/owenc/Documents/LIMDA/models/bunny_SCANalign.stl")#, thresh=0.5, samples=100000)