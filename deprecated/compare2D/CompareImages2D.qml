import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Rectangle {
    signal captureRotations(bool cad, bool scan)

    Connections {
        target: backend
        // Display cropped orthographic images to user
        function onDisplayCrop(cad, scan) {
            root.index = 2
            var d = "assets/_cropped/"
            if (cad) {
                cadFrame.urls = [d+"cad_front.png", d+"cad_top.png", d+"cad_left.png", 
                                d+"cad_rear.png", d+"cad_bottom.png", d+"cad_right.png"]
            } if (scan) {
                scanFrame.urls = [d+"scan_front.png", d+"scan_top.png", d+"scan_left.png", 
                                d+"scan_rear.png", d+"scan_bottom.png", d+"scan_right.png"]
            }
            // Reset image caches
            cadFrame.reload()
            scanFrame.reload()
        }

        // Display results from contour comparison
        function onContourResult(dist, percent) {
            results.dist = dist.toFixed(3)
            results.percent = (Math.round(percent * 10) / 10).toFixed(1) + "%"
        }
    }

    anchors.fill: parent
    color: root.bgColor

    // CAD images
    Frame2D {
        id: cadFrame
        anchors { top: parent.top; left: parent.left; bottom: parent.bottom
                right: columnMenu.left; margins: 48 }
        scan: false
    }

    // Algorithm menu
    ColumnLayout {
        id: columnMenu
        anchors { top: cadFrame.top; topMargin: 40; 
                horizontalCenter: parent.horizontalCenter }
        spacing: 16

        // Results
        ResultWidget {
            id: results
            Layout.alignment: Qt.AlignCenter
            distText: "Absolute Difference \n Between Contours"
            percentText: "Similarity Percentage"
        }

        // Compare Contours Button 
        Button {
            Layout.alignment: Qt.AlignCenter
            text: "COMPARE CONTOURS"
            palette.buttonText: root.menuColor
            font.family: titleFont.font.family
            font.pointSize: 10.5
            background: Rectangle { color: root.textColor; radius: height/6 }
            onClicked: backend.compare_contours(cadFrame.urls[cadFrame.index], 
                                                scanFrame.urls[scanFrame.index])
        }
    }

    // Scan images
    Frame2D {
        id: scanFrame
        anchors { top: parent.top; left: columnMenu.right; bottom: parent.bottom
                right: parent.right; margins: 48 }
        scan: true
    }
}