import trimesh
import numpy as np
import os
from trimesh.util import type_named, append_faces
from _triangles_intersect import faces_intersect

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
        self.under_meshes = self.mesh_faces(under_faces)
        self.over_meshes = self.mesh_faces(over_faces)
        
    def mesh_faces(self, init_faces):
        # Recurse thru all faces connected to detected errors
        volume = ErrorSubsets()
        for f in init_faces:
            if f not in volume.faces:
                faces, cad_crossed = self.model_intersect(f)
                volume.add_subset(faces, cad_crossed)
    
        # find CAD faces that enclose the scan repair volume

        # Iterate through each volume subset
        meshes = []
        for s, c in volume:
            if not c:
                # No CAD faces, can't submesh CAD model
                out = self.submesh(self.scan, s, append=True)
            else: 
                # Concatenate both submeshes
                scan_sub = self.submesh(self.scan, s, append=True)
                cad_sub = self.submesh(self.cad, c, append=True)
                out = trimesh.util.concatenate(cad_sub, scan_sub)
            out.fix_normals()
            meshes.append(out)
        return meshes

    # New while loop method, goes past CAD boundary/too many scan faces included
    def model_intersect(self, f):
        # Initialize lists
        faces = []
        boundaries = []
        cad_crossed = []
        stack = [f]
        count = 0
        # Check connected faces until stack empty
        while stack:
            f = stack.pop(0)
            # Find nearby CAD faces to scan face
            close_faces = trimesh.proximity.nearby_faces(self.cad, 
                                             np.array([self.scan.triangles_center[f],]))[0]
            # Check if face intersects CAD model
            intersected = False
            for cad_face in close_faces:
                cad_vertices = self.cad.vertices[self.cad.faces[cad_face], :]
                scan_vertices = self.scan.vertices[self.scan.faces[f], :]
                if faces_intersect(cad_vertices, scan_vertices):
                    intersected = True
                    if f not in boundaries:
                        boundaries.append(f)
                    # Faces intersect, store intersecting CAD face
                    if cad_face not in cad_crossed:
                        cad_crossed.append(cad_face)
                
            # Add connected faces to stack if CAD not crossed
            if not intersected:
                faces.append(f)
                for connected in self.scan_connected[f]:
                    # Add face to stack if not already searched/searching
                    if connected not in faces and connected not in stack:
                        stack.append(connected)
                # ##DEBUG
                # if faces and count % 10000 == 0:
                #     test = self.submesh(self.scan, faces, append=True)
                #     # xcad = self.submesh(self.cad, cad_crossed, append=True)
                #     test.visual.vertex_colors = np.array((159, 255, 60, 255))
                #     # xcad.visual.vertex_colors = np.array((0, 0, 139, 255))
                #     trimesh.Scene([test]).show()
            count += 1
            print(count)
        # Finally, add all boundary faces that intersect CAD
        faces += boundaries       
        return faces, cad_crossed
    
    def export_volumes(self, dest_folder, combine):
        if combine:
            # Combine seperate errors
            over = trimesh.util.concatenate(self.over_meshes)
            under = trimesh.util.concatenate(self.under_meshes)
            over.visual.vertex_colors = np.array((255, 13, 13, 255))
            under.visual.vertex_colors = np.array((30, 38, 145, 255))
            # Export over-extrusion
            out = os.path.join(dest_folder, 'over' + '.glb')
            trimesh.exchange.export.export_mesh(over, out, file_type="glb")
            # Fix inverted normals and export under-extrusion
            trimesh.repair.fix_inversion(under)
            out = os.path.join(dest_folder, 'under' + '.glb')
            trimesh.exchange.export.export_mesh(under, out, file_type="glb")

            # Debugging instant display
            trimesh.Scene([over, under]).show()

        else:
            # Export seperated under-extruded volumes to dest folder
            for idx, under in enumerate(self.under_meshes):
                trimesh.repair.fix_inversion(under)
                under.visual.vertex_colors = np.array((30, 38, 145, 255))
                out = os.path.join(dest_folder, 'under' + str(idx) + '.glb')
                trimesh.exchange.export.export_mesh(under, out, file_type="glb")
            # Export over-extruded volumes to dest folder
            for idx, over in enumerate(self.over_meshes):
                over.visual.vertex_colors = np.array((255, 13, 13, 255))
                out = os.path.join(dest_folder, 'over' + str(idx) + '.glb')
                trimesh.exchange.export.export_mesh(over, out, file_type="glb")
        
            # Debugging instant display
            trimesh.Scene(self.under_meshes + self.over_meshes).show()

    # Modified from 
    # https://github.com/mikedh/trimesh/blob/b9ef0a8a2434f89f41cca714a7100e78dcf1caeb/trimesh/base.py#L2676
    def submesh(self, mesh,
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
