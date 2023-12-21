import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "qml"
import "qml/Viewer" as Viewer
import "qml/Compare" as Compare
import "qml/Controls" as Controls
import "qml/ImageAlign" as Align

ApplicationWindow {
    id: root
    property alias index: stack.currentIndex

    // Theme and Colors
    property string theme: "dark"
    property string textColor: "white"
    property string secondaryText: "#9e9d9d"
    property string menuColor: "#303030"
    property string bgColor: "#252525"

    // Fonts
    FontLoader { id: regFont; source: "file:assets/fonts/Inter-Regular.otf" }
    FontLoader { id: titleFont; source: "file:assets/fonts/Inter-Black.otf" }

    // Icons
    QtObject {
        id: icons
            readonly property string angle_down: "file:assets/icons/angle-down-solid.svg"
            readonly property string angle_right: "file:assets/icons/angle-right-solid.svg"
            readonly property string bars: "file:assets/icons/bars.svg"
            readonly property string border_all: "file:assets/icons/border-all-solid.svg"
            readonly property string border_none: "file:assets/icons/border-none-solid.svg"     
            readonly property string chart_line: "file:assets/icons/chart-line-solid.svg"
            readonly property string cube: "file:assets/icons/cube-solid.svg"
            readonly property string cubes: "file:assets/icons/cubes-solid.svg"
            readonly property string diagram_project: "file:assets/icons/diagram-project-solid.svg"
            readonly property string eraser: "file:assets/icons/eraser-solid.svg"
            readonly property string eye_slash: "file:assets/icons/eye-slash-solid.svg"
            readonly property string eye: "file:assets/icons/eye-solid.svg"
            readonly property string fill: "file:assets/icons/fill-solid.svg"
            readonly property string gear: "file:assets/icons/gear-solid.svg"
            readonly property string house: "file:assets/icons/house.svg"
            readonly property string maximize: "file:assets/icons/maximize-solid.svg"
            readonly property string rotate: "file:assets/icons/rotate-solid.svg"
            readonly property string upload: "file:assets/icons/upload-solid.svg"
    }

    // Takes a filepath from FileDialog as input; returns just the file name and ext
    function getFilename(filepath) {
        var dirs = filepath.split("/")
        return dirs[dirs.length-1]
    }

    // Rounds input value to the specified number of digits (dec_digits)
    function roundDecimal(value, dec_digits) {
        var multiplier = 10 ** dec_digits
        var result = (Math.round(value * multiplier) / multiplier).toFixed(dec_digits)
        var result_string = result.toString()
        while (result_string.slice(-1) == '0') {
            result_string = result_string.slice(0, result_string.length - 1)
        }
        if (result_string.slice(-1) == '.') {
            result_string = result_string.slice(0, result_string.length - 1)
        }
        return result_string
    }

    // Default window properties
    width: 1280
    height: 720
    visible: true
    color: root.bgColor
    title: "LIMDA GUI 1.0.0"

    // Page Layout
    StackLayout {
        id: stack
        anchors { fill: parent; leftMargin: 48 }

        // QML pages (index=0,1,2...)
        HomePage {}
        Viewer.Model3D {}
        Compare.Align {}
        Align.AlignControls {}
        Settings {}
    }

    // Quick access sidebar menu for popular page's icons
    Rectangle {
        anchors { top: parent.top; left: parent.left; bottom: parent.bottom }
        implicitWidth: 48
        color: root.menuColor

        ColumnLayout {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
            spacing: 0

            // Navigation menu button
            Controls.MenuButton { iconURL: icons.bars; icon.height: 32; 
                                icon.width: 32; pageIndex: -1; onClicked: menuNav.open() }
            // Customized menu icons: assign text, page index (0,1,2...), and icon source below
            Controls.MenuButton { tipText: "Homepage"; pageIndex: 0;
                            iconURL: icons.house }
            Controls.MenuButton { tipText: "3D Viewer"; pageIndex: 1; 
                            iconURL: icons.cube }
            Controls.MenuButton { tipText: "3D Comparison"; pageIndex: 2;
                            iconURL: icons.cubes }
        }
        // Settings button placed at bottom
        Controls.MenuButton {
            anchors.bottom: parent.bottom
            tipText: "Settings"
            pageIndex: stack.count - 1
            iconURL: icons.gear
        }
    }

    // Expandable and scrollable navigation menu
    Drawer {
        id: menuNav
        clip: true
        modal: true
        width: navColumn.width + navColumn.anchors.leftMargin
        height: parent.height
        background: Rectangle { color: root.menuColor }

        Flickable {
            id: flickable
            anchors.fill: parent
            clip: true
            contentHeight: navColumn.height
            contentWidth: navColumn.width
            flickableDirection: Flickable.VerticalFlick

            ScrollIndicator.vertical: ScrollIndicator {
                parent: flickable.parent
                anchors { top: flickable.top; right: flickable.right;
                            bottom: flickable.bottom }
                active: true
            }

            ColumnLayout {
                id: navColumn
                anchors { top: parent.top; left: parent.left; leftMargin: 2 }
                spacing: 0

                // Navigation menu button
                Controls.MenuButton { 
                    text: root.title
                    font.family: titleFont.font.family
                    icon { height: 32; width: 32; source: "file:assets/icons/bars.svg" }
                    pageIndex: -1; 
                    onClicked: menuNav.close() 
                }
                // Customized button defined in Controls.MenuButton.qml: assign text, page index (0,1,2...), and icon source below
                Controls.MenuButton { text: "Homepage"; pageIndex: 0; iconURL: icons.house}
                Controls.MenuButton { text: "3D Viewer"; pageIndex: 1; iconURL: icons.cube }
                Controls.MenuButton { text: "3D Comparison"; pageIndex: 2; iconURL: icons.cubes }
                Controls.MenuButton { text: "Image Align"; pageIndex: 3; iconURL: icons.cubes }
                // For demo-ing scrollable menu
                Repeater {
                    model: 14
                    Controls.MenuButton { text: "Coming Soon"; pageIndex: 0; iconURL: icons.diagram_project }
                }
            }
        }
    }

    // Status bar
    function showStatus(message) {
        status.text = message
        status.running = true
    }

    Connections {
        target: backend
        function onThreadComplete() {
            status.running = false
        }
    }

    RowLayout {
        id: status
        property bool running: false
        property alias text: statusLabel.text
        anchors { bottom: parent.bottom; right: parent.right; margins: 8 }
        spacing: 0

        // Loading progress wheel
        BusyIndicator {
            id: busy
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.preferredHeight: 60
            Layout.preferredWidth: 80
            running: status.running
            Material.accent: root.textColor
        }

        // Descriptive text
        Label {
            id: statusLabel
            Layout.alignment: Qt.AlignCenter
            text: "Loading..."
            color: root.textColor
            font.family: titleFont.font.family
            font.pointSize: 12
            visible: status.running
        }

        // // Cancel button
        // Button {
        //     Layout.alignment: Qt.AlignCenter
        //     Layout.fillWidth: true
        //     text: "Cancel"
        //     palette.buttonText: root.textColor
        //     font.family: titleFont.font.family
        //     font.pointSize: 10
        //     visible: on
        //     onClicked: {
        //         // FIXME: add cancel function to abort current task
        //     }
        // }
    }
}
