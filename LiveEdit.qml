import QtQuick

Item {
    id: reloader

    Loader { id: pageLoader; anchors.fill: parent }

    Timer {
        interval: 3000; running: true; repeat: true;
        triggeredOnStart: true
        onTriggered: {
            pageLoader.source = ""
            backend.clear_cache()
            // PUT PAGE TO BE RELOADED HERE
            pageLoader.source = "Align.qml"
        }
    }
}