import QtQuick
import QtQuick.Controls

Item {
    Connections {
        target: backend
        // Load converted 3D model and set its calculated centroids, dimensions
        function onConvertedMesh(pageName, scanFlag, centroid, dim) {
            if (pageName == "Model3D") {
                if (scanFlag) {
                    scanScene.target.source = "backend_resources/converted_mesh/scan_model3D.glb"
                    scanScene.target.pivot = centroid
                    scanScene.target.dimensions = dim
                    scanControls.loading = false
                } else {
                    cadScene.target.source = "backend_resources/converted_mesh/cad_model3D.glb"
                    cadScene.target.pivot = centroid
                    cadScene.target.dimensions = dim
                    cadControls.loading = false
                }
            }
        }
    }

    Connections {
        target: compare2D
        // Rotating mesh to each side view and capturing image of the scene
        function onCaptureRotations(cad, scan) {
            if (cad) {
                cadScene.capture2D("cad")   
            }
            if (scan) {
                scanScene.capture2D("scan")
            }
        }
    }

    // Left layout for 3D scene and menu
    SplitView {
        id: cadLayout
        orientation: Qt.Vertical
        anchors { top: parent.top; left: parent.left;
                    right: middleBorder.left; bottom: parent.bottom }
        handle: Rectangle {
            id: handleDelegate
            implicitHeight: 2
            color: SplitHandle.pressed ? "#81e889"
                    : (SplitHandle.hovered ? Qt.lighter("#c2f4c6", 1.1) : "#9e9d9d")
            containmentMask: Item {
                width: cadLayout.width
                height: 10
            }
        }

        // Left 3D scene
        Scene3D {
            id: cadScene
            SplitView.preferredHeight: parent.height * (3/4)
            SplitView.minimumHeight: parent.height / 2
            nodeColor: cadControls.targetColor
            activateGrid: cadControls.gridChecked
        }

        // Left 3D menu
        InfoControls3D {
            id: cadControls
            SplitView.fillHeight: false
            SplitView.preferredHeight: 200
            target: cadScene.target
            scan: false
        }
    }

    // Border between the two scenes
    Rectangle {
        id: middleBorder
        anchors { top: parent.top; bottom: parent.bottom;
                    horizontalCenter: parent.horizontalCenter }
        implicitWidth: 10
        color: root.menuColor
    }

    // Right layout for 3D scene and menu
    SplitView {
        id: scanLayout
        orientation: Qt.Vertical
        anchors { top: parent.top; right: parent.right
                    left: middleBorder.right; bottom: parent.bottom }
        handle: Rectangle {
            id: handleDelegate
            implicitHeight: 2
            color: SplitHandle.pressed ? "#81e889"
                    : (SplitHandle.hovered ? Qt.lighter("#c2f4c6", 1.1) : "#9e9d9d")
            containmentMask: Item {
                width: scanLayout.width
                height: 10
            }
        }

        // Right 3D Scene
        Scene3D {
            id: scanScene
            SplitView.preferredHeight: parent.height * (3/4)
            SplitView.minimumHeight: parent.height / 2
            nodeColor: scanControls.targetColor
            activateGrid: scanControls.gridChecked
        }

        // Right 3D menu
        InfoControls3D {
            id: scanControls
            SplitView.fillHeight: false
            SplitView.preferredHeight: 200
            target: scanScene.target
            scan: true
        }
    }

    // Loading progess indicator
    BusyText {
        anchors.centerIn: parent
        text: "Loading 3D File..."
        on: cadControls.loading || scanControls.loading
    }
}