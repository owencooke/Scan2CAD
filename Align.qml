import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

import DepthMap

// Page for running the 3D alignment/comparison algorithms
Item {
    // Reset all Node properties to their "default", NOT including source
    function resetNode(mesh) {
        mesh.scale = Qt.vector3d(5, 5, 5)
        mesh.eulerRotation = Qt.vector3d(0, 0, 0)
        mesh.position = Qt.vector3d(0, 0, 0)
        mesh.opacity = 1
        mesh.dimensions = mesh.init_dims
    }

    // Initialize Node properties upon loading from external file
    function setNodeProperties(mesh, fname, centroid, dim) {
        mesh.source = "backend_resources/_converted_mesh/" + fname + ".glb"
        mesh.pivot = centroid
        mesh.dimensions = mesh.init_dims = dim
        // Get initial global translation
        mesh.t_pivot = mesh.sceneTransform.column(3).toVector3d()
    }

    // Returns the 4x4 transformation matrix representing the input Node
    function getSpatialMatrix(mesh) {
        // Init transform matrix
        var mat = Qt.matrix4x4()
        // Calculate total translation vector (pivot moved to origin)
        var move = mesh.position.minus(mesh.pivot)
        // Apply scale, rotation, translation to matrix
        mat.rotate(mesh.rotation)
        mat.translate(move)
        mat.scale(mesh.scale.times(1/5))
        return mat
    }

    Connections {
        target: backend
        // Load converted 3D model and set its calculated centroids, dimensions
        function onConvertedMesh(pageName, scanFlag, centroid, dim) {
            if (pageName == "Align") {
                if (scanFlag) {
                    resetNode(scan)
                    setNodeProperties(scan, "scan_align", centroid, dim)
                } else {
                    resetNode(cad)
                    setNodeProperties(cad, "cad_align", centroid, dim)
                }
                loadingScreen.on = false
                cloud.opacity = 0
            }
        }

        // Display results of the alignment algorithm to user
        function onDisplayAligned(translation, scale, rotation, cost) {
            loadingScreen.on = false
            cad.opacity = scan.opacity = 1
            // Set scan's aligned transformation
            scan.position = scan.position.plus(translation)
            scan.scale = scan.scale.times(scale)
            scan.rotation = rotation
            // Hide depth cloud
            cloud.opacity = 0
            // Set user controls back to camera
            mouseButton.text = "CAMERA"
            userControl.target = camera
            userControl.keysEnabled = false
        }
    }

    // 3D scene for rendering the models
    View3D {
        id: view3D
        anchors.fill: parent

        camera: OrthographicCamera {
            id: camera
            clipNear: -9999
            pivot: cad.pivot
            eulerRotation: Qt.vector3d(-20.4556, 52.6713, 0)
        }

        // CAD model's node
        RuntimeLoader {
            id: cad
            property vector3d dimensions: Qt.vector3d(0,0,0)
            property vector3d init_dims: Qt.vector3d(0,0,0)
            property vector3d t_pivot
        }

        // CAD's lighting (color)
        DirectionalLight{
            scope: cad
            color: cadControl.sliderColor
            brightness: 4
            eulerRotation: camera.eulerRotation
        }

        // 3D Scan's node
        RuntimeLoader {
            id: scan
            property vector3d dimensions: Qt.vector3d(0,0,0)
            property vector3d init_dims: Qt.vector3d(0,0,0)
            property vector3d t_pivot
        }

        // Scan's lighting (color)
        DirectionalLight{
            scope: scan
            color: scanControl.sliderColor
            brightness: 4
            eulerRotation: camera.eulerRotation
        }

        // Model for storing the calculated Depth Cloud
        Model {
            id: cloud
            scale: Qt.vector3d(5, 5, 5)
            // Custom geometry from _depth_map.py
            geometry: PointCloud {
                id: cloudClass
                onCloudCalculated: loadingScreen.on = false
            } 
            materials: [
                DefaultMaterial {
                    lighting: DefaultMaterial.NoLighting
                    vertexColorsEnabled: true
                    // Controlled by slider
                    pointSize: depthMenu.pointSize
                }
            ]
        }

        // Mouse controls for zooming/rotation
        MeshController {
            id: userControl
            anchors.fill: parent
            scene: view3D
            camera: camera
            target: camera
            keysEnabled: false
        }

        // Gridlines
        AxisHelper {
            id: axes
            enableAxisLines: true
            gridColor: root.secondaryText
        }

        environment: SceneEnvironment {
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.VeryHigh
            backgroundMode: SceneEnvironment.Color
            clearColor: root.bgColor 
        }
    }

    // Algorithm sidebar menu
    Rectangle {
        anchors { left: parent.left; top: cadControl.bottom; margins: 16 }
        color: root.menuColor
        width: algoMenu.width + 36
        height: algoMenu.height + 36
        radius: width / 8
        visible: (algoMenu.width == 0) ? false : true
        
        ColumnLayout {
            id: algoMenu
            anchors.centerIn: parent
            spacing: 8

            // Pairs of dropdown titles and menu modules
            DropDownLabel { id: alignment; text: "Alignment"; open: true}
            AlignMenu { id: alignMenu; visible: alignment.open }

            DropDownLabel { id: depth; text: "Depth Map"; open: false}
            DepthMenu { id: depthMenu;  visible: depth.open}
        }
    }

    // Scale for depth map
    DepthScale {
        id: depthScale
        anchors { right: parent.right; top: scanControl.bottom;
                    bottom: parent.bottom; margins: 16 }
        height: parent.height * 0.75
        implicitWidth: 128
        radius: width / 8
        color: root.menuColor
        // Visible after running depth map calculation
        visible: false 
    }

    // Toggle menu for switching user mouse control
    Rectangle {
        id: mouseMenu
        anchors { horizontalCenter: parent.horizontalCenter
            top: parent.top; topMargin: 16 }
        color: root.menuColor
        implicitHeight: 56
        implicitWidth: 150
        radius: height/5

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -8

            Label {
                Layout.alignment: Qt.AlignCenter
                text: "Mouse controls:"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 8
            }

            // Button toggles mouse controls between camera, CAD or scan
            Button {
                id: mouseButton
                Layout.alignment: Qt.AlignCenter
                text: "CAMERA"
                palette.buttonText: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 18
                background: Rectangle { opacity: 0 }

                onClicked: {
                    switch(mouseButton.text) {
                        case "CAMERA":
                            mouseButton.text = "CAD"
                            userControl.target = cad
                            userControl.keysEnabled = true
                            break

                        case "CAD":
                            mouseButton.text = "SCAN"
                            userControl.target = scan
                            userControl.keysEnabled = true
                            break

                        case "SCAN":
                            mouseButton.text = "CAMERA"
                            userControl.target = camera
                            userControl.keysEnabled = false
                            break
                    }
                }
            }
        }
    }

    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter
            top: mouseMenu.bottom }
        height: pageControls.height
        width: pageControls.width + 8
        color: root.menuColor

        RowLayout {
            id: pageControls
            anchors.centerIn: parent
            spacing: 0

            IconButton {
                icon { source: "backend_resources/icons/chart-line-solid.svg";
                        height: 20; width: 20 }
                onClicked: axes.enableAxisLines = !axes.enableAxisLines 
            }

            IconButton {
                icon { source: !axes.enableXZGrid ? "backend_resources/icons/border-all-solid.svg" 
                        : "backend_resources/icons/border-none-solid.svg";
                        height: 20; width: 20 }
                onClicked: axes.enableXZGrid = !axes.enableXZGrid 
            }
        }
    }

    // Dropdown menu for CAD model's controls
    AlignControls {
        id: cadControl
        anchors { right: mouseMenu.left; rightMargin: 32; 
                    verticalCenter: mouseMenu.verticalCenter }
        target: cad
        scanFlag: false
    }

    // Dropdown menu for 3D scan's controls
    AlignControls {
        id: scanControl
        anchors { left: mouseMenu.right; leftMargin: 32
                    verticalCenter: mouseMenu.verticalCenter }
        target: scan
        scanFlag: true
    }

    // Loading indicator
    BusyText {
        id: loadingScreen
        anchors.centerIn: view3D
        width: 200
        height: 150
    }
}