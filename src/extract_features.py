import trimesh
import numpy as np
import os
from src.intersect import faces_intersect
from collections import deque
from src.utils import submesh

class ErrorSubsets():
    def __init__(self):
        self.scan_set = []
        self.cad_set = []
        self.faces = []

    def __iter__(self):
        return zip(self.scan_set, self.cad_set)

    def add_subset(self, scan_faces, cad_faces):
        if len(scan_faces) > 1:
            self.scan_set.append(scan_faces)
            self.cad_set.append(cad_faces)
            self.faces += scan_faces


class RepairExtractor():
    def __init__(self, cad, scan, samples, thresh):
        self.cad = cad
        self.scan = scan
        self.samples = samples
        self.thresh = thresh
        self.scan_connected = self.hash_connected_faces(scan)
        self.cad_connected = self.hash_connected_faces(cad)

    # Create connected face hash maps
    def hash_connected_faces(self, mesh):
        cc_hash = {}
        # Iterate through (n,2) array of faces that share VERTICES
        for i, j in trimesh.graph.face_neighborhood(mesh):
            # Add both faces to the others' hash
            if i in cc_hash:
                cc_hash[i].append(j)
            else:
                cc_hash[i] = [j]
            if j in cc_hash:
                cc_hash[j].append(i)
            else:
                cc_hash[j] = [i]
        return cc_hash

    def extract_repairs(self):
        # Sample points
        sample_points, faces = self.scan.sample(self.samples, return_index=True)
        dists = self.cad.nearest.signed_distance(sample_points)
        over_faces = []
        under_faces = []
        # Classify points as errors if |d| > thresh
        for idx, d in enumerate(dists):
            if d > self.thresh:
                # Under extruded, store face index
                under_faces.append(faces[idx])
            elif d < -self.thresh: 
                # Over extruded, store face index
                over_faces.append(faces[idx])

        # Create additive/subtractive repair meshes
        self.under_meshes, self.under_volume = self.mesh_faces(under_faces)
        self.over_meshes, self.over_volume = self.mesh_faces(over_faces)
        
    def mesh_faces(self, init_faces):
        # Recurse thru all faces connected to detected errors
        volume = ErrorSubsets()
        for f in init_faces:
            if f not in volume.faces:
                faces, cad_crossed = self.model_intersect(f)
                volume.add_subset(faces, cad_crossed)
    
        # FIXME: incorporate the CAD faces for closing the volume automatically

        # Iterate through each volume subset
        meshes = []
        for s, c in volume:
            if not c:
                # No CAD faces, can't submesh CAD model
                out = submesh(self.scan, s, append=True)
            else: 
                # Concatenate both submeshes
                scan_sub = submesh(self.scan, s, append=True)
                cad_sub = submesh(self.cad, c, append=True)
                out = trimesh.util.concatenate(cad_sub, scan_sub)
            out.fix_normals()
            meshes.append(out)
        return meshes, volume

    # Feature extraction algorithm 
    def model_intersect(self, f):
        # Initialize feature set and queue
        feature = []
        cad_crossed = []
        queue = deque([f])
        # Check connected faces until queue empty
        while queue:
            f = queue.popleft()
            # Find nearby CAD faces to scan face
            close_faces = trimesh.proximity.nearby_faces(self.cad, 
                                             np.array([self.scan.triangles_center[f],]))[0]
            # Check if scan face intersects nearby CAD faces
            scan_vertices = self.scan.vertices[self.scan.faces[f], :]
            for cad_face in close_faces:
                cad_vertices = self.cad.vertices[self.cad.faces[cad_face], :]
                # Compute intersection
                intersection = faces_intersect(cad_vertices, scan_vertices)
                if intersection:
                    # FIXME: incorporate the CAD faces for closing the volume automatically
                    # Faces intersect, store intersecting CAD face
                    # if cad_face not in cad_crossed:
                    #     cad_crossed.append(cad_face)
                    break
            # Only search connected faces if CAD not intersected
            if not intersection:
                for connected in self.scan_connected[f]:
                    # Add face to queue if not already searched/searching
                    if connected not in feature and connected not in queue:
                        queue.append(connected)
            # Add face to feature
            feature.append(f)

        return feature, cad_crossed
    
    def export_volumes(self, dest_folder, combine, file_ext):
        if combine:
            # Combine seperate errors
            over = trimesh.util.concatenate(self.over_meshes)
            under = trimesh.util.concatenate(self.under_meshes)
            over.visual.vertex_colors = np.array((255, 13, 13, 255))
            under.visual.vertex_colors = np.array((30, 38, 145, 255))
            # Export over-extrusion
            out = os.path.join(dest_folder, 'over.' + file_ext)
            trimesh.exchange.export.export_mesh(over, out, file_type=file_ext)
            # Fix inverted normals and export under-extrusion
            trimesh.repair.fix_inversion(under)
            out = os.path.join(dest_folder, 'under.' + file_ext)
            trimesh.exchange.export.export_mesh(under, out, file_type=file_ext)

            # Debugging instant display
            trimesh.Scene([over, under]).show()

        else:
            # Export seperated under-extruded volumes to dest folder
            for idx, under in enumerate(self.under_meshes):
                trimesh.repair.fix_inversion(under)
                under.visual.vertex_colors = np.array((30, 38, 145, 255))
                out = os.path.join(dest_folder, 'under' + str(idx) + '.' + file_ext)
                trimesh.exchange.export.export_mesh(under, out, file_type=file_ext)
            # Export over-extruded volumes to dest folder
            for idx, over in enumerate(self.over_meshes):
                over.visual.vertex_colors = np.array((255, 13, 13, 255))
                out = os.path.join(dest_folder, 'over' + str(idx) + '.' + file_ext)
                trimesh.exchange.export.export_mesh(over, out, file_type=file_ext)
        
            # Debugging instant display
            #trimesh.Scene(self.under_meshes + self.over_meshes).show()


# Pre-aligned test (no GUI needed) using the case study from the ICRAI paper
if __name__ == "__main__":
    import time
    from PySide6.QtGui import QMatrix4x4
    from utils import trimesh_from_url
    
    # Matrixes to align the two models
    cad_mat = QMatrix4x4(1, 0, 0, -1.9073486328125e-06, 0, 5.960464477539063e-08, 0.9999999403953552, -13.12500286102295, 0, -0.9999999403953552, 5.960464477539063e-08, -7.823111900506774e-07, 0, 0, 0, 1) 
    scan_mat = QMatrix4x4(-0.9998733997344971, -0.00261781201697886, 0.015707235783338547, -0.4721300005912781, -0.0026181351859122515, 0.999996542930603, 0, 3.654583692550659, -0.01570718362927437, -4.112366514164023e-05, -0.999876856803894, 0.9400255084037781, 0, 0, 0, 1)
    cad_file = "C:/Users/owenc/Documents/LIMDA/ICRAI_results/ideal.stl"
    scan_file = "C:/Users/owenc/Documents/LIMDA/ICRAI_results/scan.stl"

    samples = 300
    thresh = 0.5
    combine = True

    # Load files into Trimesh objects
    start_time = time.time()
    cad = trimesh_from_url(cad_file, cad_mat)
    scan = trimesh_from_url(scan_file, scan_mat)
    
    # Extract repair volumes to folder
    driver = RepairExtractor(cad, scan, samples, thresh)
    driver.extract_repairs()
    print("--- %s seconds ---" % (time.time() - start_time))
    driver.export_volumes("repair_tests", combine, "stl")