import QtQuick

Item {
    id: reloader

    Loader { id: pageLoader; anchors.fill: parent }

    Timer {
        interval: 1000; running: true; repeat: true;
        onTriggered: {
            pageLoader.source = ""
            backend.clearCache()
            // PUT PAGE TO BE RELOADED HERE
            pageLoader.source = "Align.qml"
        }
    }
}