import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

import DepthMap

// Page for running the 3D alignment/comparison algorithms
Item {
    // Toggle mouse controls between camera, CAD or scan 
    function switchControls(node, label) {
        mouseButton.text = label
        userControl.target = Qt.binding(function() { return (node.visible) ? node : null })
        if (label == "CAMERA") {
            userControl.keysEnabled = false
        } else {
            userControl.keysEnabled = true
        }
    }

    // Timer {
    //     running: true; repeat: true; interval: 1000
    //     onTriggered: console.log(cad.sceneTransform, scan.sceneTransform)
    // }

    Connections {
        target: backend
        // Load converted 3D model and set its calculated centroids, dimensions
        function onConvertedMesh(pageName, scanFlag, centroid, dim) {
            if (pageName == "Align") {
                if (scanFlag) {
                    scan.resetNode()
                    scan.setNodeProperties("scan_align", centroid, dim)
                } else {
                    cad.resetNode()
                    cad.setNodeProperties("cad_align", centroid, dim)
                }
                loadingScreen.on = false
                cloud.visible = false
            }
        }

        // Display results of the alignment algorithm to user
        function onDisplayAligned(centroid, dim, cost) {
            /* FIXME:
             // function onDisplayAligned(translation, scale, rotation, cost) {
                https://bugreports.qt.io/browse/QTBUG-105961
                - Alignment outputs a 4x4 transformation matrix.
                - No proper method to write a transform matrix to Node
                    at time of development.
                - Replace temp file code w/ output matrix applied to scan's Node

                Failed attempt to decompose the transforms (sometimes works)
                scan.scale = scan.scale.times(scale)
                scan.rotation = scan.rotation.times(rotation)
                scan.position = scan.position.plus(translation)
            */

            // Load aligned file after resetting node properties
            scan.resetNode()
            scan.source = "backend_resources/_converted_mesh/scan_align.glb"
            // Scan moved to origin, so reset cad's translation
            scan.pivot = centroid
            scan.dimensions = dim
            cad.position = Qt.vector3d(0, 0, 0)

            // Modify display
            loadingScreen.on = false
            cloud.visible = false
            cad.visible = scan.visible = true
        }

        function onVolumes() {
            loadingScreen.on = false
        }
    }

    // 3D scene for rendering the models
    View3D {
        id: view3D
        anchors.fill: parent

        camera: OrthographicCamera {
            id: camera
            clipNear: -9999
            eulerRotation: Qt.vector3d(-20.4556, 52.6713, 0)
            horizontalMagnification: 5
            verticalMagnification: 5
        }

        // Nodes (holds loaded models)
        DynamicNode { id: cad }
        DynamicNode { id: scan }

        // CAD's lighting (color)
        DirectionalLight{
            scope: cad
            color: cadControl.sliderColor
            brightness: 4
            eulerRotation: camera.eulerRotation
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
            // Custom geometry from _depth_map.py
            geometry: PointCloud {
                id: cloudClass
                onCloudCalculated: function(centroid) {
                    loadingScreen.on = false
                    cloud.pivot = centroid
                }
            } 
            materials: [
                DefaultMaterial {
                    lighting: DefaultMaterial.NoLighting
                    vertexColorsEnabled: true
                    // Point size controlled by slider
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
            scale: Qt.vector3d(1/5, 1/5, 1/5)
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
            DepthMenu { id: depthMenu; visible: depth.open}

            DropDownLabel { id: extract; text: "Extract Volumes"; open: false}
            ExtractMenu { id: extractMenu; visible: extract.open}
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

            // Toggle mouse control
            Button {
                id: mouseButton
                Layout.alignment: Qt.AlignCenter
                text: "CAMERA"
                palette.buttonText: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 18
                background: Rectangle { opacity: 0 }

                // Cycle through different options
                onClicked: {
                    switch(mouseButton.text) {
                        case "CAMERA":
                            switchControls(cad, "CAD")
                            break

                        case "CAD":
                            switchControls(scan, "SCAN")
                            break

                        case "SCAN":
                            switchControls(camera, "CAMERA")
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