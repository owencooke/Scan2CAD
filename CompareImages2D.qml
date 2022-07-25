import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Item {
    id: compare2D
    signal captureRotations(bool cad, bool scan)

    Connections {
        target: backend
        // Display results of perspective images to user
        function onDisplayCrop() {
            root.index = 2
            var d = "backend_resources/cropped/"
            cadFrame.urls = [d+"cad_front.png", d+"cad_top.png", d+"cad_left.png", 
                            d+"cad_rear.png", d+"cad_bottom.png", d+"cad_right.png"]
            scanFrame.urls = [d+"scan_front.png", d+"scan_top.png", d+"scan_left.png", 
                            d+"scan_rear.png", d+"scan_bottom.png", d+"scan_right.png"]
            // Reset image cache
            cadFrame.reload()
            scanFrame.reload()
        }

        function onContourResult(dist, percent) {
            results.dist = dist.toFixed(3)
            results.percent = (Math.round(percent * 10) / 10).toFixed(1) + "%"
        }
    }

        Rectangle {
            id: bg
            anchors.fill: parent
            color: root.bgColor

            Frame2D {
                id: cadFrame
                anchors { top: parent.top; left: parent.left; bottom: parent.bottom
                        right: columnMenu.left; margins: 48 }
            }

            ColumnLayout {
                id: columnMenu
                anchors { top: cadFrame.top; topMargin: 40; 
                        horizontalCenter: parent.horizontalCenter }
                spacing: 16

                ResultWidget {
                    id: results
                    Layout.alignment: Qt.AlignCenter
                    distText: "Absolute Difference \n Between Contours"
                    percentText: "Similarity Percentage"
                }

                Button {
                    Layout.alignment: Qt.AlignCenter
                    text: "COMPARE CONTOURS"
                    palette.buttonText: root.menuColor
                    font.family: titleFont.font.family
                    font.pointSize: 10.5
                    background: Rectangle { color: root.textColor; radius: height/6 }
                    onClicked: backend.compareContours(cadFrame.urls[cadFrame.index], 
                                                        scanFrame.urls[scanFrame.index])
                }
            }

            Frame2D {
                id: scanFrame
                anchors { top: parent.top; left: columnMenu.right; bottom: parent.bottom
                        right: parent.right; margins: 48 }
            }
        }
    }