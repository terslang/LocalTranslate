cmake_minimum_required(VERSION 3.16)

project(LocalTranslate VERSION 0.5.0 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Setup Qt Project
find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.8)

find_package(kotki REQUIRED)
find_package(marian-lite REQUIRED)
find_package(yaml-cpp REQUIRED)
find_package(ICU COMPONENTS uc i18n REQUIRED)

# Configure mecab for usage
execute_process(COMMAND mecab-config --cflags OUTPUT_VARIABLE MECAB_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND mecab-config --libs OUTPUT_VARIABLE MECAB_LIBS OUTPUT_STRIP_TRAILING_WHITESPACE)

configure_file(config.hpp.in config/config.hpp)

qt_add_executable(localtranslate
    main.cpp resources.qrc
)

qt_add_qml_module(localtranslate
    URI LocalTranslate
    VERSION 1.0
    QML_FILES Main.qml
    RESOURCES config.hpp.in
    SOURCES translation_bridge.hpp
    SOURCES translation_bridge.cpp
)

target_include_directories(localtranslate PRIVATE ${LocalTranslate_BINARY_DIR}/config)

set_target_properties(localtranslate PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_compile_options(localtranslate PRIVATE ${MECAB_CFLAGS})
# This regex checks if the processor is "aarch64" OR starts with "arm"
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm)")
    message(STATUS "ARM architecture detected (${CMAKE_SYSTEM_PROCESSOR}), adding ARM definition.")
    target_compile_definitions(localtranslate PRIVATE ARM)
endif()

target_link_libraries(localtranslate
    PRIVATE Qt6::Quick kotki marian-lite yaml-cpp ICU::uc ICU::i18n ${MECAB_LIBS})

install(TARGETS localtranslate
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

# Install Desktop Files for Linux (Unix but not Apple)
if(UNIX AND NOT APPLE)
  install(
    FILES desktop/dev.ters.LocalTranslate.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    COMPONENT Application)
  install(
    FILES desktop/16x16/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/16x16/apps)
  install(
    FILES desktop/22x22/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/22x22/apps)
  install(
    FILES desktop/24x24/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/24x24/apps)
  install(
    FILES desktop/32x32/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/32x32/apps)
  install(
    FILES desktop/36x36/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/36x36/apps)
  install(
    FILES desktop/44x44/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/44x44/apps)
  install(
    FILES desktop/48x48/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/48x48/apps)
  install(
    FILES desktop/64x64/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/64x64/apps)
  install(
    FILES desktop/72x72/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/72x72/apps)
  install(
    FILES desktop/96x96/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/96x96/apps)
  install(
    FILES desktop/128x128/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/128x128/apps)
  install(
    FILES desktop/150x150/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/150x150/apps)
  install(
    FILES desktop/192x192/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/192x192/apps)
  install(
    FILES desktop/256x256/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/256x256/apps)
  install(
    FILES desktop/310x310/localtranslate.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/310x310/apps)
  install(
    FILES desktop/dev.ters.LocalTranslate.metainfo.xml
    DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
endif()

# Install Completion Files for Linux (Unix but not Apple)
if(UNIX AND NOT APPLE)
  # For bash
  install(
    FILES completions/localtranslate.bash
    DESTINATION ${CMAKE_INSTALL_DATADIR}/bash-completion/completions)

  # For zsh
  install(
    FILES completions/_localtranslate
    DESTINATION ${CMAKE_INSTALL_DATADIR}/zsh/site-functions)

  #For fish
  install(
    FILES completions/localtranslate.fish
    DESTINATION ${CMAKE_INSTALL_DATADIR}/fish/vendor_completions.d)
endif()
