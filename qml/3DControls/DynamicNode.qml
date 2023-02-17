import QtQuick3D
import Mesh

Model {
    id: mesh
    property vector3d init_dims: Qt.vector3d(0,0,0)
    property vector3d dimensions: Qt.vector3d(0,0,0)
    property color color: "red"
    property string source
    property matrix4x4 pastSourceTransform: Qt.matrix4x4()

    // Bind backend load function for easy use outside module
    property var load: try {geometry.load_file} catch(TypeError) {null}
    property var transform: try {geometry.transform} catch(TypeError) {null}

    // Reset all Node properties to their "default", NOT including source
    function resetNode() {
        mesh.scale = Qt.vector3d(1, 1, 1)
        mesh.eulerRotation = Qt.vector3d(0, 0, 0)
        mesh.position = Qt.vector3d(0, 0, 0)
        mesh.visible = true
        mesh.dimensions = mesh.init_dims
    }

    function getTransform() {
        return mesh.sceneTransform.times(pastSourceTransform)
    }

    // Custom geometry from _depth_map.py
    geometry: Mesh {
        id: meshClass
        onLoaded: function(centroid, dims) {
            status.running = false
            mesh.pivot = centroid
            mesh.dimensions = mesh.init_dims = dims
        }
    } 
    materials: [
        DefaultMaterial {
            diffuseColor: color
        }
    ]
}