import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: root
    width: 900
    height: 650
    visible: true
    title: "Zenith Installation Protocol"
    color: "#0a0a0a"

    property string theme: "dark"
    property color accentColor: "#6200ee"
    property color bgColor: "#111111"
    property color cardColor: "#1a1a1a"
    property color fgColor: "#ffffff"
    property color secondaryTextColor: "#888888"
    
    property string currentTask: "Initializing Zenith Perfection..."
    property real progressValue: 0.0
    property bool isFinished: false

    // Log model to store incoming logs
    ListModel {
        id: logModel
    }

    // Main Container
    Rectangle {
        anchors.fill: parent
        color: bgColor
        
        // Background Gradient
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1a1a1a" }
                GradientStop { position: 1.0; color: "#0a0a0a" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 25

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                Image {
                    id: logo
                    source: "images/logo/dark.jpg"
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 40
                    fillMode: Image.PreserveAspectFit
                }

                ColumnLayout {
                    spacing: 2
                    Label {
                        text: "Zenith OS"
                        font.pixelSize: 18
                        font.bold: true
                        color: fgColor
                    }
                    Label {
                        text: "Installation Protocol v2.0"
                        font.pixelSize: 12
                        color: secondaryTextColor
                    }
                }

                Item { Layout.fillWidth: true } // Spacer

                Rectangle {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 32
                    radius: 16
                    color: isFinished ? "#15ff0022" : "#6200ee22"
                    border.color: isFinished ? "#15ff00" : accentColor
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: isFinished ? "COMPLETED" : "RUNNING"
                        font.pixelSize: 10
                        font.bold: true
                        color: isFinished ? "#15ff00" : accentColor
                    }
                }
            }

            // Progress Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: currentTask
                        font.pixelSize: 16
                        font.bold: false
                        color: fgColor
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Label {
                        text: Math.round(progressValue * 100) + "%"
                        font.pixelSize: 16
                        font.bold: true
                        color: accentColor
                    }
                }

                // Custom Progress Bar
                Rectangle {
                    id: progressTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    color: "#222222"
                    radius: 4

                    Rectangle {
                        id: progressFill
                        height: parent.height
                        width: parent.width * progressValue
                        radius: 4
                        color: accentColor
                        
                        Behavior on width {
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            // Log View
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: cardColor
                radius: 12
                border.color: "#333333"
                border.width: 1
                clip: true

                ListView {
                    id: logListView
                    anchors.fill: parent
                    anchors.margins: 15
                    model: logModel
                    delegate: RowLayout {
                        width: logListView.width - 30
                        spacing: 10
                        
                        Label {
                            text: "[" + time + "]"
                            font.family: "monospace"
                            font.pixelSize: 11
                            color: "#555555"
                        }
                        
                        Label {
                            text: message
                            font.family: "monospace"
                            font.pixelSize: 12
                            color: level === "error" ? "#ff5555" : 
                                   level === "success" ? "#50fa7b" : 
                                   level === "warn" ? "#f1fa8c" : "#cccccc"
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                        }
                    }
                    
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                    
                    onCountChanged: {
                        Qt.callLater(scrollToBottom)
                    }

                    function scrollToBottom() {
                        positionViewAtEnd()
                    }
                }
            }

            // Footer / Action Bar
            RowLayout {
                Layout.fillWidth: true
                visible: isFinished
                
                Item { Layout.fillWidth: true }

                Button {
                    text: "Reboot System"
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: 14
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 150
                        implicitHeight: 45
                        radius: 8
                        color: parent.pressed ? "#4d00b8" : accentColor
                    }
                    onClicked: {
                        logModel.append({
                            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
                            level: "info",
                            message: "Triggering system reboot..."
                        })
                        // In a real scenario, this would trigger a reboot
                        // For now we just close the window after a short delay
                        Qt.quit()
                    }
                }
            }
        }
    }

    // Stdin handling
    Connections {
        target: stdin
        function onReadyRead() {
            let chunk = stdin.read(1024)
            if (chunk) {
                let lines = chunk.split('\n')
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (!line) continue

                    if (line.startsWith('{')) {
                        try {
                            let json = JSON.parse(line)
                            let timeStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
                            
                            if (json.type === "task") {
                                currentTask = json.message
                            } else if (json.type === "progress") {
                                progressValue = json.value
                            } else if (json.type === "log") {
                                logModel.append({
                                    time: timeStr,
                                    level: json.level || "info",
                                    message: json.message
                                })
                            } else if (json.type === "finish") {
                                isFinished = true
                                currentTask = "Zenith Installation Complete!"
                                progressValue = 1.0
                            }
                        } catch (e) {
                            // Fallback for non-JSON or malformed JSON
                            logModel.append({
                                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
                                level: "info",
                                message: line
                            })
                        }
                    } else {
                        logModel.append({
                            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
                            level: "info",
                            message: line
                        })
                    }
                }
            }
        }
    }
}
