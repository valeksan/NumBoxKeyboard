# Требуем минимальную версию CMake
cmake_minimum_required(VERSION 3.16)

# Указываем проект
project(example VERSION 1.0.0 LANGUAGES CXX)

# Указываем стандарт C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Ищем Qt6 с нужными компонентами
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 QuickLayouts)

# Включаем автогенерацию MOC, RCC, UIC (только для Qt6)
qt_standard_project_setup()

# Определяем исполняемый файл
qt_add_executable(example
    main.cpp
)

# Подключаем QML-файлы как ресурсы
qt_add_resources(example "qml"
    PREFIX "/"
    FILES
        main.qml
        NumBoxKeyboard.qml
        ButtonDlg.qml
        ButtonKey.qml
)

# Связываем с нужными Qt-модулями
target_link_libraries(example
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickLayouts
)

# Устанавливаем приложение (опционально)
install(TARGETS example
    RUNTIME DESTINATION bin
)
