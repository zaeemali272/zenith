import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
    id: root
    width: 800
    height: 600
    visible: true
    title: "Zenith Installer"

    property string theme: "dark"
    property color bgColor: theme === "dark" ? "#282a36" : "#f8f8f2"
    property color fgColor: theme === "dark" ? "#f8f8f2" : "#282a36"
    property color secondaryColor: theme === "dark" ? "#44475a" : "#e0e0e0"

    Rectangle {
        anchors.fill: parent
        color: bgColor
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Row {
            width: parent.width
            height: 50

            Image {
                id: logo
                width: 150
                height: 50
                source: theme === "dark" ? "images/logo/dark.jpg" : "images/logo/light.jpg"
                fillMode: Image.PreserveAspectFit
            }

            Item { width: parent.width - 250; height: 1 } // Spacer

            Button {
                id: themeButton
                text: "Switch to " + (theme === "dark" ? "Light" : "Dark") + " Mode"
                onClicked: {
                    theme = theme === "dark" ? "light" : "dark"
                }
            }
        }

        Label {
            id: taskLabel
            text: "Initializing..."
            font.pixelSize: 20
            color: fgColor
        }

        ProgressBar {
            id: progressBar
            width: parent.width
            value: 0.0
        }

        ScrollView {
            width: parent.width
            height: parent.height - 150
            clip: true

            TextArea {
                id: textArea
                readOnly: true
                wrapMode: Text.Wrap
                font.family: "monospace"
                color: fgColor
                background: Rectangle { color: secondaryColor }
            }
        }
    }

    Connections {
        target: stdin
        function onReadyRead() {
            let chunk = stdin.read(1024)
            if (chunk) {
                let lines = chunk.split('
')
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith('{')) {
                        try {
                            let json = JSON.parse(lines[i])
                            if (json.type === "task") {
                                taskLabel.text = json.message
                            } else if (json.type === "progress") {
                                progressBar.value = json.value
                            } else if (json.type === "log") {
                                textArea.append(json.message + '
')
                            }
                        } catch (e) {
                            // Not a JSON line, just log it
                            textArea.append(lines[i] + '
')
                        }
                    } else {
                        textArea.append(lines[i] + '
')
                    }
                }
            }
        }
    }
}
