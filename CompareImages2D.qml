import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Item {
    id: compare2D
    signal captureRotations(bool cad, bool scan)
    function resetSources() {
        cadFront.source = ""
        cadTop.source = ""
        cadLeft.source = ""
        scanFront.source = ""
        scanTop.source = ""
        scanLeft.source = ""
    }

    Connections {
        target: backend
        // Display results of perspective images to user
        function onDisplayCrop() {
            root.index = 2
            compare2D.resetSources()
            cadFront.source = "backend_resources/cropped/cad_front.png"
            cadTop.source = "backend_resources/cropped/cad_top.png"
            cadLeft.source = "backend_resources/cropped/cad_left.png"
            scanFront.source = "backend_resources/cropped/scan_front.png"
            scanTop.source = "backend_resources/cropped/scan_top.png"
            scanLeft.source = "backend_resources/cropped/scan_left.png"
        }

        function onContourResult(dist, percent) {
            distLabel.text = dist.toFixed(3)
            percentLabel.text = (Math.round(percent * 10) / 10).toFixed(1) + "%"
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: root.bgColor

        GridLayout {
            id: grid
            property int max: 300
            anchors.centerIn: parent
            columns: 3
            rowSpacing: 25
            columnSpacing: 75
            
            Image { id: cadFront; source: "backend_resources/icons/limda_icon.png"; fillMode: Image.PreserveAspectFit;
                    cache: false; Layout.maximumWidth: grid.max; Layout.maximumHeight: grid.max; Layout.alignment: Qt.AlignCenter }
            Image { id: cadTop; source: "backend_resources/icons/limda_icon.png"; fillMode: Image.PreserveAspectFit;
                    cache: false; Layout.maximumWidth: grid.max; Layout.maximumHeight: grid.max; Layout.alignment: Qt.AlignCenter }
            Image { id: cadLeft; source: "backend_resources/icons/limda_icon.png"; fillMode: Image.PreserveAspectFit;
                    cache: false; Layout.maximumWidth: grid.max; Layout.maximumHeight: grid.max; Layout.alignment: Qt.AlignCenter }
            Image { id: scanFront; source: "backend_resources/icons/limda_icon.png"; fillMode: Image.PreserveAspectFit;
                    cache: false; Layout.maximumWidth: grid.max; Layout.maximumHeight: grid.max; Layout.alignment: Qt.AlignCenter }
            Image { id: scanTop; source: "backend_resources/icons/limda_icon.png"; fillMode: Image.PreserveAspectFit;
                    cache: false; Layout.maximumWidth: grid.max; Layout.maximumHeight: grid.max; Layout.alignment: Qt.AlignCenter }
            Image { id: scanLeft; source: "backend_resources/icons/limda_icon.png"; fillMode: Image.PreserveAspectFit;
                    cache: false; Layout.maximumWidth: grid.max; Layout.maximumHeight: grid.max; Layout.alignment: Qt.AlignCenter }
        }
    }

    Rectangle {
        id: menu
        opacity: 0.9
        color: root.menuColor
        anchors.top: parent.top; anchors.topMargin: 16
        anchors.left: parent.left; anchors.leftMargin: 16
        implicitHeight: 100
        implicitWidth: 500
        radius: height/6

        ColumnLayout {
            anchors.centerIn: parent
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
                    //backend.get2DImages()
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
    }

    Rectangle {
        id: results
        color: root.menuColor
        opacity: 0.8
        anchors.top: parent.top; anchors.topMargin: 16
        anchors.right: parent.right; anchors.rightMargin: 16
        implicitHeight: 200
        implicitWidth: 200
        radius: height/6

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            Label {
                id: distLabel
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                text: "-"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 30
                font.weight: Font.DemiBold
            }
            Label {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                text: "Absolute Difference"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 10
                font.weight: Font.DemiBold
            }
            Label {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                text: "Between Contours"
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 10
                font.weight: Font.DemiBold
            }
            Rectangle {
                Layout.alignment: Qt.AlignCenter
                color: root.menuColor
                opacity: 0
                implicitHeight: 10
                implicitWidth: 10
            }
            Label {
                id: percentLabel
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                text: "-"
                color: root.textColor
                font.family: titleFont.font.family
                font.pointSize: 30
                font.weight: Font.DemiBold
            }
            Label {
                text: "Similarity Percentage"
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                color: root.secondaryText
                font.family: regFont.font.family
                font.pointSize: 10
                font.weight: Font.DemiBold
            }
        }
    }
}