import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

View3D {
    id: view3D
    property Node target: mesh
    property string nodeColor
    property bool activateGrid
    property vector3d meshRotation

    // Rotate mesh to each orthographic view and capture image of the scene
    function capture2D(fname) {
        // Disable gridlines and adjust color for high image contrast
        axes.enableXYGrid = false
        axes.enableAxisLines = false
        light.color = root.textColor
        
        // Front
        view3D.grabToImage(function(result) {
            result.saveToFile("backend_resources/captured_imgs/" + fname + "_front.png")
            // Top
            mesh.eulerRotation.x += 90
            view3D.grabToImage(function(result) {
                result.saveToFile("backend_resources/captured_imgs/" + fname + "_top.png")
                // Bottom 
                mesh.eulerRotation.x += 180
                view3D.grabToImage(function(result) {
                    result.saveToFile("backend_resources/captured_imgs/" + fname + "_bottom.png")
                    // Left
                    mesh.eulerRotation.x -= 270
                    mesh.eulerRotation.y += 90
                    view3D.grabToImage(function(result) {
                        result.saveToFile("backend_resources/captured_imgs/" + fname + "_left.png")
                        // Rear
                        mesh.eulerRotation.y += 90
                        view3D.grabToImage(function(result) {
                            result.saveToFile("backend_resources/captured_imgs/" + fname + "_rear.png")
                            // Right
                            mesh.eulerRotation.y += 90
                            view3D.grabToImage(function(result) {
                                result.saveToFile("backend_resources/captured_imgs/" + fname + "_right.png")
                                // Give gridline/color control back to user
                                axes.enableXYGrid = Qt.binding(function() { return !activateGrid })
                                axes.enableAxisLines = Qt.binding(function() { return !activateGrid })
                                light.color = Qt.binding(function() { return nodeColor })
                                mesh.eulerRotation.y -= 270
                                // Call backend function to crop the images
                                if (fname == "cad") {
                                    backend.crop2D(root.theme, true, false)
                                } else {
                                    backend.crop2D(root.theme, false, true)
                                }
                            })
                        })
                    })
                })
            })
        })
    }

    camera: OrthographicCamera {
        id: camera
        clipNear: -9999
        pivot: target.pivot
    }

    DirectionalLight{
        id: light
        color: nodeColor
        brightness: 4
    }

    // Node storing model loaded by user
    RuntimeLoader {
        id: mesh
        property vector3d dimensions: Qt.vector3d(0,0,0)
        property vector3d init_dims: Qt.vector3d(0,0,0)
        eulerRotation: meshRotation
        scale:  Qt.vector3d(5,5,5)
    }

    // Scene rendering options
    environment: SceneEnvironment {
        id: env
        antialiasingMode: SceneEnvironment.MSAA
        antialiasingQuality: SceneEnvironment.VeryHigh
        backgroundMode: SceneEnvironment.Color
        clearColor: root.bgColor 
    }

    // Mouse control tool
    MeshController {
        id: mouse
        scene: view3D
        camera: camera
        target: mesh
        anchors.fill: parent
        keysEnabled: false
    }

    // Gridlines
    AxisHelper {
        id: axes
        enableXZGrid: false // Model kept in XY plane
        enableXYGrid: !activateGrid
        enableAxisLines: !activateGrid
        gridColor: root.secondaryText
    }
}