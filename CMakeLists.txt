cmake_minimum_required(VERSION 3.16)

project(LocalTranslate VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.2 COMPONENTS Quick REQUIRED)
find_package(kotki REQUIRED)
find_package(marian-lite REQUIRED)
find_package(yaml-cpp REQUIRED)
find_package(ICU COMPONENTS uc i18n REQUIRED)

qt_add_executable(appLocalTranslate
    main.cpp
)

qt_add_qml_module(appLocalTranslate
    URI LocalTranslate
    VERSION 1.0
    QML_FILES main.qml SearchableComboBox.qml
)

set_target_properties(appLocalTranslate PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appLocalTranslate
    PRIVATE Qt6::Quick kotki::kotki-lib marian-lite yaml-cpp ICU::uc ICU::i18n)

install(TARGETS appLocalTranslate
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
