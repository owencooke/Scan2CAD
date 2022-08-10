import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

import DepthMap

Item {
    id: align

    Connections {
        target: backend
        // Load converted 3D model and set its calculated centroids, dimensions
        function onConvertedMesh(pageName, scanFlag, centroid, dim) {
            if (pageName == "Align") {
                if (scanFlag) {
                    scan.source = "backend_resources/converted_mesh/scan_align.glb"
                    scan.pivot = centroid
                    scan.dimensions = dim
                    scan.scale = Qt.vector3d(5,5,5) // default
                } else {
                    cad.source = "backend_resources/converted_mesh/cad_align.glb"
                    cad.pivot = centroid
                    cad.dimensions = dim
                    cad.scale = Qt.vector3d(5,5,5) // default
                }
                loadingScreen.on = false
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
            // Display results
            results.dist = dist.toFixed(3)
            results.percent = (Math.round(percent * 10) / 10).toFixed(1) + "%"
            // Reset all Node properties to default
            cad.scale = scan.scale = Qt.vector3d(5, 5, 5)
            cad.eulerRotation = scan.eulerRotation = Qt.vector3d(0, 0, 0)
            cad.position = scan.position = Qt.vector3d(0, 0, 0)
            cad.pivot = scan.pivot = camera.pivot = centroid
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
            property double zoomX: 1
            property double zoomY: 1
            clipNear: -9999
            pivot: cad.pivot
            horizontalMagnification: zoomX
            verticalMagnification: zoomY
            eulerRotation: Qt.vector3d(-20.4556, 52.6713, 0)
        }

        // CAD model's node
        RuntimeLoader {
            id: cad
            property vector3d dimensions: Qt.vector3d(0,0,0)
            scale:  Qt.vector3d(5,5,5)
        }

        // for OPEN-GL graphics use
        DirectionalLight{
            scope: cad
            color: cadControl.sliderColor
            brightness: 4
            eulerRotation: camera.eulerRotation
        }

        // MeshLighting {
        //     target: cad
        //     targetColor: cadControl.sliderColor
        //     camera: camera
        // }

        // 3D Scan's node
        RuntimeLoader {
            id: scan
            property vector3d dimensions: Qt.vector3d(0,0,0)
            scale:  Qt.vector3d(5,5,5)
        }

        // for OPEN-GL graphics use
        DirectionalLight{
            scope: scan
            color: scanControl.sliderColor
            brightness: 4
            eulerRotation: camera.eulerRotation
        }

        // MeshLighting {
        //     target: scan
        //     targetColor: scanControl.sliderColor
        //     camera: camera
        // }

        // Timer { 
        //     interval: 1000; repeat: true; running: true
        //     onTriggered: {
        //         console.log(cloudClass.thresh_model[0])
        //     }
        // }

        Model {
            id: cloud
            scale: Qt.vector3d(5, 5, 5)
            pivot: cad.pivot
            geometry: PointCloud {
                id: cloudClass
            } 
            materials: [
                DefaultMaterial {
                    lighting: DefaultMaterial.NoLighting
                    vertexColorsEnabled: true
                    pointSize: pointSlider.value
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

    // Running Indicator
    BusyText {
        id: loadingScreen
        anchors.centerIn: view3D
        width: 200
        height: 150
        on: false
    }

    // Toggle menu for user's mouse control
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

            Button {
                id: mouseButton
                Layout.alignment: Qt.AlignCenter
                text: "CAMERA"
                palette.buttonText: root.selectedColor
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

    // Dropdown menu for CAD model controls
    AlignControls {
        id: cadControl
        anchors { right: mouseMenu.left; rightMargin: 32; 
                    verticalCenter: mouseMenu.verticalCenter }
        target: cad
        scanFlag: false
    }

    // Dropdown menu for 3D scan controls
    AlignControls {
        id: scanControl
        anchors { left: mouseMenu.right; leftMargin: 32
                    verticalCenter: mouseMenu.verticalCenter }
        target: scan
        scanFlag: true
    }

    Rectangle {
        id: algoBorder
        anchors.left: parent.left
        width: 2
        color: root.secondaryText
        height: parent.height
    }

    Rectangle {
        id: algoMenu
        anchors { left: algoBorder.right; top: parent.top }
        opacity: 0.9
        color: root.menuColor
        width: 200
        height: 600
        
        ColumnLayout {
            anchors { left: parent.left; right: parent.right
                        top: parent.top; margins: 16 }
            spacing: 8

            Label {
                Layout.alignment: Qt.AlignCenter
                text: "Alignment"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 12
            }

            GridLayout {
                columns: 2
                columnSpacing: 16
                rowSpacing: 10
                width: parent.width

                Label {
                    text: "Sampled Points"
                    color: root.textColor
                    font.family: regFont.font.family
                    font.pointSize: 9
                }

                TextBox {
                    Layout.alignment: Qt.AlignRight
                    tipText: "Number of points randomly sampled from the\nsurface/vertices of the loaded meshes."
                    text: "2000"
                    fontSize: 10 
                    validator: IntValidator {
                        bottom: 1
                        top: 1000000
                    }
                }

                Label {
                    text: "Number of Iterations"
                    color: root.textColor
                    font.family: regFont.font.family
                    font.pointSize: 9
                }
                
                TextBox {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    text: "50"
                    fontSize: 10 
                    validator: IntValidator {
                        bottom: 1
                        top: 999
                    }
                }

                Label {
                    text: "Corrective Scaling"
                    color: root.textColor
                    font.family: regFont.font.family
                    font.pointSize: 9
                }
                
                CheckBox {
                    id: toggleScale
                    Layout.alignment: Qt.AlignRight
                }
            }

            Button {
                id: alignButton
                Layout.alignment: Qt.AlignCenter
                text: "Align Meshes"
                font.family: titleFont.font.family
                font.pointSize: 10
                palette.buttonText: root.bgColor
                background: Rectangle { color: root.textColor; radius: height/6 }
                onClicked: {
                    var error = false
                    // Turn labels red to indicate error if no file selected
                    if (cad.status != RuntimeLoader.Success) {
                        scanControl.fileColor = "red"
                        error = true
                    } if (scan.status != RuntimeLoader.Success) {
                        cadControl.fileColor = "red"
                        error = true
                    // Reset loader sources and run alignment from backend
                    } if (!error) {
                        cad.scale = scan.scale = Qt.vector3d(1, 1, 1)
                        loadingScreen.busyText = "Calculating alignment..."
                        loadingScreen.on = true
                        backend.align_meshes(cad.source, scan.source, cad.sceneTransform,
                                                    scan.sceneTransform, toggleScale.checked)
                        cad.source = scan.source = " "
                    }
                }
            }

            Label {
                Layout.alignment: Qt.AlignCenter
                text: "Depth Map"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 12
            }

            GridLayout {
                columns: 2
                columnSpacing: 16
                rowSpacing: 10
                width: parent.width
            
                Label {
                    Layout.fillWidth: true
                    text: "Sampled Points"
                    color: root.textColor
                    font.family: regFont.font.family
                    font.pointSize: 9
                }

                TextBox {
                    Layout.alignment: Qt.AlignRight
                    tipText: "Number of points randomly sampled from the\nsurface/vertices of the loaded meshes."
                    text: "2000"
                    fontSize: 10 
                    validator: IntValidator {
                        bottom: 1
                        top: 1000000
                    }
                }

                Label {
                    text: "Point Size"
                    color: root.textColor
                    font.family: regFont.font.family
                    font.pointSize: 9
                }

                Slider {
                    id: pointSlider
                    from: 1
                    value: 1
                    to: 50
                }
            }

            Button {
                Layout.alignment: Qt.AlignCenter
                text: "Calculate Depth Map"
                font.family: titleFont.font.family
                font.pointSize: 10
                palette.buttonText: root.bgColor
                background: Rectangle { color: root.textColor; radius: height/6 }
                
                onClicked: {
                    backend.depth_map(cloudClass, cad.source, scan.source, 10000)
                    cad.opacity = scan.opacity = 0
                    cloud.opacity = 1
                }
            }

            Label {
                Layout.alignment: Qt.AlignCenter
                text: "Distance Similarity"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 12
            }
        }
    }

    // Scale for depth map
    Rectangle {
        anchors { right: parent.right; rightMargin: 16
                    verticalCenter: parent.verticalCenter }
        height: parent.height * 0.75
        width: 128
        opacity: 0.9
        radius: width / 8
        color: root.menuColor

        Label {
            id: overLabel
            anchors { top: parent.top; margins: 16;
                        horizontalCenter: parent.horizontalCenter }
            text: "Over-Extrusion"
            color: root.textColor
            font.family: titleFont.font.family
            font.pointSize: 10
        }

        Label {
            id: underLabel
            anchors { bottom: parent.bottom; margins: 16;
                        horizontalCenter: parent.horizontalCenter }
            text: "Under-Extrusion"
            color: root.textColor
            font.family: titleFont.font.family
            font.pointSize: 10
        }

        Rectangle {
            id: depthGradient
            anchors { right: parent.right; margins: 8
                        top: overLabel.bottom; bottom: underLabel.top }
            width: parent.width / 4
            radius: width / 4
        
            gradient: Gradient {
                GradientStop { position: 0; color: "red" }
                GradientStop { position: 0.167; color: "orange" }
                GradientStop { position: 0.333; color: "yellow" }
                GradientStop { position: 0.5; color: "green" }
                GradientStop { position: 0.667; color: "cyan" }
                GradientStop { position: 0.833; color: "blue" }
                GradientStop { position: 1; color: "indigo" }
            }

            // Middle line indicator
            Rectangle {
                height: 3
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        ColumnLayout {
            anchors {right: depthGradient.left; left: parent.left; rightMargin: 8
                        top: depthGradient.top; bottom: depthGradient.bottom; leftMargin: 8 }

            Repeater {
                model: cloudClass.thresh_model
                Label {
                    Layout.alignment: Qt.AlignRight
                    text: cloudClass.thresh_model[index].toPrecision(3)
                    color: root.textColor
                    font.family: regFont.font.family
                    font.pointSize: 10
                }
            }
        }
    }

    ResultWidget {
        id: results
        anchors { bottom: algoMenu.top; bottomMargin: 16; left: algoMenu.left}
        distText: "Average Squared Distance \n Between Meshes"
        percentText: "Similarity Percentage"
    }
}