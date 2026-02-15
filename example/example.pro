# example/example.pro
QT += core gui qml quick quickcontrols2

DEFINES += QT_DEPRECATED_WARNINGS

SOURCES += main.cpp

RESOURCES += qml.qrc

OTHER_FILES += \
    ../NumBoxKeyboard.qml \
    ../ButtonDlg.qml \
    ../ButtonKey.qml \
    ../qtquickcontrols2.conf \
    ../qmldir \
    main.qml

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
