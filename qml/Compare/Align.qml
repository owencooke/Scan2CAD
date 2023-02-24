import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

import DepthMap
import Extracted
import "../3DControls" as Controls3D
import "../Controls" as Controls

// Page for running the 3D alignment/comparison algorithms
Item {
    Connections {
        target: backend
        // Display results of the alignment algorithm to user
        function onAligned(t_matrix) { 
            scan.transform(t_matrix)
            scan.resetNode()
            scan.pastSourceTransform = t_matrix
        }

        function onExtracted(over, under) {
            extracted.load_data(scan.source, over, under)
        }
    }

    // Timer {
    //     running: true; repeat: true; interval: 2000
    //     onTriggered: {
    //         console.log(scan.sceneTransform)
    //         console.log()
    //     }
    // }

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

        DirectionalLight{ scope: mainScene; eulerRotation: camera.eulerRotation }

        DirectionalLight{ brightness: 0.01; scope: ex; eulerRotation.x: 0  }
        DirectionalLight{ brightness: 0.01; scope: ex; eulerRotation.x: 90 }
        DirectionalLight{ brightness: 0.01; scope: ex; eulerRotation.x: 180 }
        DirectionalLight{ brightness: 0.01; scope: ex; eulerRotation.x: 270  }
        DirectionalLight{ brightness: 0.01; scope: ex; eulerRotation.y: 90 }
        DirectionalLight{ brightness: 0.01; scope: ex; eulerRotation.y: 270 }

        Node {
            id: mainScene
        
            // Nodes (holds loaded models)
            Controls3D.DynamicNode {
                id: cad
                color: cadControl.sliderColor
            }
            
            Controls3D.DynamicNode {
                id: scan
                color: scanControl.sliderColor
            }

            // Model for storing the calculated Depth Cloud
            Model {
                id: cloud
                geometry: PointCloud {
                    id: cloudClass
                    onCloudCalculated: function(centroid) {
                        status.running = false
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
        }

        Model {
            id: ex
            pivot: scan.pivot
            geometry: Extracted { id: extracted } 
            materials: [
                DefaultMaterial {
                    // cullMode: Material.NoCulling
                    // lighting: PrincipledMaterial.NoLighting
                    vertexColorsEnabled: true
                }
            ]
        }

        // Mouse controls for zooming/rotation
        Controls3D.MeshController {
            id: userControl
            anchors.fill: parent
            scene: view3D
            camera: camera
            target: camera
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

            Controls.IconButton {
                icon { source: icons.chart_line;
                        height: 20; width: 20 }
                onClicked: axes.enableAxisLines = !axes.enableAxisLines 
            }

            Controls.IconButton {
                icon { source: !axes.enableXZGrid ? icons.border_all 
                        : icons.border_none;
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

    Slider {
        id: testSlider
        from: 0
        to: 1
    }
}