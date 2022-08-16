import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

import DepthMap

Item {
    Connections {
        target: backend
        // Load converted 3D model and set its calculated centroids, dimensions
        function onConvertedMesh(pageName, scanFlag, centroid, dim) {
            if (pageName == "Align") {
                if (scanFlag) {
                    scan.source = "backend_resources/converted_mesh/scan_align.glb"
                    scan.pivot = centroid
                    scan.dimensions = scan.init_dims = dim
                    scan.scale = Qt.vector3d(5,5,5)
                } else {
                    cad.source = "backend_resources/converted_mesh/cad_align.glb"
                    cad.pivot = centroid
                    cad.dimensions = cad.init_dims = dim
                    cad.scale = Qt.vector3d(5,5,5)
                }
                loadingScreen.on = false
                // Show meshes and hide depth cloud
                cad.opacity = scan.opacity = 1
                cloud.opacity = 0
            }
        }

        // Display results of the ICP algorithm to user
        function onDisplayAligned(centroid, dist, percent) {
            loadingScreen.on = false
            // Set source URLs of aligned output
            cad.source = "backend_resources/converted_mesh/cad_align.glb"
            scan.source = "backend_resources/converted_mesh/scan_align.glb"
            // Reset all Node properties to default
            cad.scale = scan.scale = Qt.vector3d(5, 5, 5)
            cad.eulerRotation = scan.eulerRotation = Qt.vector3d(0, 0, 0)
            cad.position = scan.position = Qt.vector3d(0, 0, 0)
            cad.pivot = scan.pivot = camera.pivot = centroid
            // Show meshes and hide depth cloud
            cad.opacity = scan.opacity = 1
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
            scale:  Qt.vector3d(5,5,5)
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
            scale:  Qt.vector3d(5,5,5)
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
            pivot: cad.pivot
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
        width: algoMenu.width + 48
        height: algoMenu.height + 48
        radius: width / 8
        
        ColumnLayout {
            id: algoMenu
            anchors.centerIn: parent
            spacing: 32
            // Seperate menu modules in column
            AlignMenu { id: alignMenu }
            DepthMenu { id: depthMenu }
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
        opacity: 0.9
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