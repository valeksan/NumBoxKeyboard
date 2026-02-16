// example/main.qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls

import "."

Window {
    visible: true
    width: 640
    height: 480
    title: qsTr("Example of NumBoxKeyboard Usage")

    // Window background
    Rectangle {
        anchors.fill: parent
        color: "#f0f0f0"
    }

    // Application title
    Text {
        id: title
        text: qsTr("NumBoxKeyboard Example")
        font.pointSize: 18
        font.bold: true
        color: "#333"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        verticalAlignment: Text.AlignVCenter
    }

    // User instructions
    Text {
        id: instruction
        text: qsTr("Click on the field below to open the numeric keyboard.")
        font.pointSize: 12
        color: "#555"
        anchors.top: title.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        wrapMode: Text.Wrap
        width: parent.width * 0.8
        horizontalAlignment: Text.AlignHCenter
    }

    // Field for displaying and entering a number
    TextEdit {
        id: textEdit
        text: "0.000"  // initial value
        font.pointSize: 16
        selectByMouse: true
        readOnly: true  // read-only, click opens the keyboard
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        anchors.top: instruction.bottom
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: 120
        height: 40

        // Field border
        Rectangle {
            anchors.fill: parent
            anchors.margins: -10
            color: "transparent"
            border.color: "#ccc"
            border.width: 1
            radius: 4

            // Clickable area to open the keyboard
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!numKeyboard.isVisible()) {
                        // Open the keyboard with the current value
                        numKeyboard.show(textEdit.text);
                    }
                }
            }
        }
    }

    // Button to force-open the keyboard
    Button {
        id: openKeyboardButton
        text: qsTr("Open Keyboard")
        anchors.top: textEdit.bottom
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            numKeyboard.show(textEdit.text);
        }
    }

    // Numeric keyboard widget
    NumBoxKeyboard {
        id: numKeyboard
        // Keyboard settings
        minimumValue: -100.0
        maximumValue: 100.0
        precision: 3  // number of decimal places
        decimals: 3   // number of allowed decimal digits
        antialiasing: true
        anchors.fill: parent
    }

    // Handle signals from the keyboard
    Connections {
        target: numKeyboard
        function onOk(number, is_equal) {
            console.log("User selected:", number);
            textEdit.text = number;
        }
        function onCancel() {
            console.log("User canceled input.");
        }
    }
}
