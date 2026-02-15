---
# NumBoxKeyboard

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Qt](https://img.shields.io/badge/Qt-6.x-blue.svg)
![C++](https://img.shields.io/badge/Language-C%2B%2B-blue.svg)
![QML](https://img.shields.io/badge/Language-QML-red.svg)

A customizable numeric keyboard component for Qt Quick applications.

## Features

- **Numeric Input**: Designed specifically for entering numerical values.
- **Range Configuration**: Supports setting minimum and maximum allowed values.
- **Precision Control**: Allows defining the number of decimal places (`decimals`) and overall precision.
- **Placeholder Value**: Can display an initial value or placeholder.
- **Customizable Styling**: Inherits from Qt Quick Controls, allowing styling via themes or custom backgrounds/content items (when using compatible styles like `Basic`).
- **Qt6 Compatible**: Works with Qt 6.x (requires `QQuickStyle::setStyle("Basic")`).

## Prerequisites

- Qt 6.2+
- Qt Quick Controls 2 (ensure `QtQuick.Controls`, `QtQuick.Layouts`, and `QtQuick.Templates` are available)
- CMake 3.16+ (if building with CMake)

### 1. Clone the Repository

```bash
git clone https://github.com/valeksan/numboxkeyboard.git
cd numboxkeyboard
```

### 2. Integrate Components

Copy the following QML files into your project's QML resource directory (or source tree):

- `NumBoxKeyboard.qml`
- `ButtonDlg.qml`
- `ButtonKey.qml`

### 3. Configure Your Application

#### CMake (Recommended)

1.  Create a `CMakeLists.txt` file in your application's source directory (e.g., `example/`) or adapt the provided one.
2.  Ensure your `CMakeLists.txt` finds Qt6 components and links against `Qt6::QuickControls2`:

    ```cmake
    # In your application's CMakeLists.txt
    find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 QuickLayouts)

    qt_add_executable(your_app_name
        main.cpp # Your application's main file
    )

    qt_add_resources(your_app_name "qml_resources" # Or whatever name you choose
        PREFIX "/"
        FILES
            # ... other QML files ...
            path/to/NumBoxKeyboard.qml # Adjust path as needed
            path/to/ButtonDlg.qml
            path/to/ButtonKey.qml
            # ... potentially qtquickcontrols2.conf if included ...
    )

    target_link_libraries(your_app_name
        PRIVATE
            Qt6::Core
            Qt6::Gui
            Qt6::Qml
            Qt6::Quick
            Qt6::QuickControls2 # Essential for QQuickStyle and compatibility
            Qt6::QuickLayouts
    )
    ```
    
#### qmake

1.  Update your `.pro` file to include the necessary modules and resource files:

    ```pro
    QT += core gui qml quick quickcontrols2 # 'quickcontrols2' is crucial

    SOURCES += main.cpp # Your application's main file

    RESOURCES += qml.qrc # Include your .qrc file containing the QML files
    ```

2.  In your `qml.qrc`, add the paths to the copied QML files:

    ```xml
    <RCC>
        <qresource prefix="/">
            <file>path/to/main.qml</file> <!-- Your main QML file -->
            <file>path/to/NumBoxKeyboard.qml</file> <!-- Adjust path -->
            <file>path/to/ButtonDlg.qml</file>
            <file>path/to/ButtonKey.qml</file>
            <!-- Optional: <file>qtquickcontrols2.conf</file> -->
        </qresource>
    </RCC>
    ```

### 4. Set Style

To ensure correct rendering and allow customization of `background` and `contentItem` in `ButtonDlg.qml`, it's required to set the Qt Quick Controls style to `Basic` in your application's main C++ file (e.g., `main.cpp`):

```cpp
// main.cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle> // Add this include

int main(int argc, char *argv[])
{
    // Set the style BEFORE creating QGuiApplication
    QQuickStyle::setStyle("Basic");

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);

    // ... rest of your application setup ...
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml"))); // Or your main QML file path
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
```

### 5. Use in QML

Import the directory containing `NumBoxKeyboard.qml` (assuming it's in the same resource directory as your main QML file, or adjust the import path accordingly) and use it:

```qml
// main.qml
import QtQuick
import QtQuick.Window
// Import the directory containing NumBoxKeyboard.qml
import "." // If NumBoxKeyboard.qml is in the same resource directory

Window {
    visible: true
    width: 640
    height: 480

    TextEdit { // Example field to display/input the number
        id: textEdit
        text: "0.000"
        anchors.centerIn: parent
        readOnly: true
        Rectangle { // Border rectangle
            anchors.fill: parent
            anchors.margins: -10
            color: "white"
            border.color: "#ccc"
            MouseArea { // Clickable area to open the keyboard
                anchors.fill: parent
                onClicked: numKeyboard.show(textEdit.text)
            }
        }
    }

    NumBoxKeyboard {
        id: numKeyboard
        anchors.fill: parent
        visible: false // Typically hidden initially

        minimumValue: -100.0
        maximumValue: 100.0
        decimals: 2
        precision: 4
        placeholderValue: textEdit.text

        // Handle the result
        Connections {
            target: numKeyboard
            function onOk(number, isEqualToPlaceholder) {
                textEdit.text = number;
                numKeyboard.visible = false; // Hide after input
            }
            function onCancel() {
                console.log("Input cancelled.");
                numKeyboard.visible = false; // Hide after cancellation
            }
        }
    }
}
```

## Properties

| Name                 | Type    | Description                                                                 |
| -------------------- | ------- | --------------------------------------------------------------------------- |
| `minimumValue`       | `real`  | Minimum allowed value. Defaults to `-999999`.                               |
| `maximumValue`       | `real`  | Maximum allowed value. Defaults to `999999`.                                |
| `precision`          | `int`   | Total number of significant digits allowed. Defaults to `6`.                |
| `decimals`           | `int`   | Number of digits allowed after the decimal point. Defaults to `2`.          |
| `placeholderValue`   | `string`| Initial value displayed when the keyboard opens. Defaults to `"0"`.         |
| `enableSequenceGrid` | `bool`  | Enables/disables the sequence grid feature (if implemented). Defaults to `false`. |
| `sequenceStep`       | `real`  | Step size for the sequence grid (if enabled). Defaults to `1`.              |

## Signals

| Name   | Parameters              | Description                                            |
| ------ | ----------------------- | ------------------------------------------------------ |
| `ok`   | `var number, var equal` | Emitted when the 'OK' button is pressed.               |
| `cancel` | (none)                | Emitted when the 'Cancel' button is pressed.           |

## Contributing

Contributions are welcome! Feel free to fork the repository and submit pull requests for bug fixes or enhancements.

## Acknowledgments

- Inspired by common needs for numeric input in Qt applications.
- Thanks to the Qt community for resources and documentation.
