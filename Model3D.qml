import QtQuick
import QtQuick.Controls

Item {
    property string cadFile: "No model selected."
    property string scanFile: "No model selected."

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
            backend.crop2D(cad, scan)
        }
    }

    //------------------------------------------------------//
    // 3D SCENE #1 (left)
    //------------------------------------------------------//
    SplitView {
        id: cadLayout
        orientation: Qt.Vertical
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: middleBorder.left
        anchors.bottom: parent.bottom
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

        Scene3D {
            id: cadScene
            SplitView.preferredHeight: parent.height * (3/4)
            SplitView.minimumHeight: parent.height / 2
            nodeColor: cadControls.targetColor
            activateGrid: cadControls.gridChecked
        }

        InfoControls3D {
            id: cadControls
            SplitView.fillHeight: false
            SplitView.preferredHeight: 200
            title: getFilename(root.cadFile)
            target: cadScene.target
            scan: false
        }
    }
    //------------------------------------------------------//
    // Border between the two scenes
    //------------------------------------------------------//
    Rectangle {
        id: middleBorder
        color: root.menuColor
        implicitWidth: 10
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
    //------------------------------------------------------//
    // 3D SCENE #2 (right)
    //------------------------------------------------------//
    SplitView {
        id: scanLayout
        orientation: Qt.Vertical
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.left: middleBorder.right
        anchors.bottom: parent.bottom
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

        Scene3D {
            id: scanScene
            SplitView.preferredHeight: parent.height * (3/4)
            SplitView.minimumHeight: parent.height / 2
            nodeColor: scanControls.targetColor
            activateGrid: scanControls.gridChecked
        }

        InfoControls3D {
            id: scanControls
            SplitView.fillHeight: false
            SplitView.preferredHeight: 200
            title: getFilename(root.scanFile)
            target: scanScene.target
            scan: true
        }
    }
    //----------------------------------------------------------//
    // Loading progess wheel for model
    //----------------------------------------------------------//
    BusyText {
        id: loadIndicator
        anchors.centerIn: parent
        busyText: "Loading 3D File..."
        on: cadControls.loading || scanControls.loading
    }
}