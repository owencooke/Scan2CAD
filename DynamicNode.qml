import QtQuick3D
import Mesh

Model {
    id: mesh
    property vector3d init_dims: Qt.vector3d(0,0,0)
    property vector3d dimensions: Qt.vector3d(0,0,0)
    property color color: "red"
    property string source

    // Bind backend load function for easy use outside module
    property var load: try {geometry.load_file} catch(TypeError) {null}
    property var transform: try {geometry.transform} catch(TypeError) {null}

    // Custom geometry from _depth_map.py
    geometry: Mesh {
        id: meshClass
        onLoaded: function(centroid, dims) {
            mesh.pivot = centroid
            mesh.dimensions = mesh.init_dims = dims
        }
    } 
    materials: [
        DefaultMaterial {
            diffuseColor: color
        }
    ]


    // Reset all Node properties to their "default", NOT including source
    function resetNode() {
        mesh.scale = Qt.vector3d(1, 1, 1)
        mesh.eulerRotation = Qt.vector3d(0, 0, 0)
        mesh.position = Qt.vector3d(0, 0, 0)
        mesh.visible = true
        mesh.dimensions = mesh.init_dims
    }

    // Initialize Node properties upon loading from external file
    function setNodeProperties(fname, centroid, dim) {
        mesh.source = "backend_resources/_converted_mesh/" + fname + ".glb"
        mesh.pivot = centroid
        mesh.dimensions = mesh.init_dims = dim
    }
}