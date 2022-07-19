import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Item {
    id: compare2D
    signal captureRotations(bool cad, bool scan)
    property var d: "backend_resources/cropped/"
    property var cad_imgs: [d+"cad_front.png", d+"cad_top.png", d+"cad_left.png", 
                            d+"cad_rear.png", d+"cad_bottom.png", d+"cad_right.png"]
                            
    property var scan_imgs: [d+"scan_front.png", d+"scan_top.png", d+"scan_left.png", 
                            d+"scan_rear.png", d+"scan_bottom.png", d+"scan_right.png"]

    Connections {
        target: backend
        // Display results of perspective images to user
        function onDisplayCrop() {
            root.index = 2
            cadFrame.urls = cad_imgs
            scanFrame.urls = scan_imgs
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

            RowLayout {
                id: frameRow
                anchors.centerIn: parent
                spacing: bg.width / 9

                Frame2D {
                    id: cadFrame
                    Layout.alignment: Qt.AlignBottom
                    Layout.preferredHeight: bg.height * (3/4)
                    Layout.preferredWidth: bg.width/3
                }

                Frame2D {
                    id: scanFrame
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: bg.height * (3/4)
                    Layout.preferredWidth: bg.width/3
                }
            }
        }

        Rectangle {
            id: menu
            anchors.bottom: parent.bottom
            width: parent.width
            implicitHeight: 100
            color: root.bgColor
            clip:true

            ColumnLayout {
                id: buttons
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.top: parent.top; anchors.topMargin: 16
                spacing: 16
                Button {
                    //anchors.centerIn: parent
                    text: "GET IMAGES FROM 3D VIEWER"
                    palette.buttonText: root.menuColor
                    font.family: titleFont.font.family
                    font.pointSize: 10.5
                    background: Rectangle { color: root.textColor; radius: height/6 }
                    onClicked: {
                        root.index = 1
                        compare2D.captureRotations(true, true)
                    }
                }

                Button {
                    //anchors.centerIn: parent
                    text: "COMPARE CONTOURS"
                    palette.buttonText: root.menuColor
                    font.family: titleFont.font.family
                    font.pointSize: 10.5
                    background: Rectangle { color: root.textColor; radius: height/6 }
                    onClicked: {
                        backend.compareContours()
                    }
                }
            }

            ResultWidget {
                id: results
                anchors { top: parent.top; topMargin: 16;
                            right: parent.right; rightMargin: 16 }
                distText: "Absolute Difference \n Between Contours"
                percentText: "Similarity Percentage"
            }
        }
    }