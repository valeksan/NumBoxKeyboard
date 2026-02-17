# Require minimum CMake version
cmake_minimum_required(VERSION 3.16)

# Specify the project
# The project is located in the example/ folder, and CMakeLists.txt is there too
project(example VERSION 1.0.0 LANGUAGES CXX)

# Find Qt6 with required components
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 QuickLayouts)

# Enable auto-generation of MOC, RCC, UIC (Qt6 only)
qt_standard_project_setup()

# Define the executable
qt_add_executable(example
    main.cpp
)

# Add QML files as resources
# Paths are relative to the folder containing CMakeLists.txt (example/)
qt_add_resources(example "qml"
    PREFIX "/"
    FILES
        main.qml
        ../NumBoxKeyboard.qml
        ../qtquickcontrols2.conf
)

# Link against required Qt modules
target_link_libraries(example
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickLayouts
)

# Install the application (optional)
install(TARGETS example
    RUNTIME DESTINATION bin
)
