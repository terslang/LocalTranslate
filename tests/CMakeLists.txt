# QML tests, run with ctest after configuring with -DBUILD_TESTING=ON.
find_package(Qt6 REQUIRED COMPONENTS QuickTest)

qt_add_executable(qml_tests tst_qml.cpp)

target_link_libraries(qml_tests PRIVATE Qt6::QuickTest)

# The application compiles its QML into its own resources, so the generated
# qmldir points at a resource path that only exists inside the localtranslate
# executable. The test binary needs the components on disk instead, so mirror
# them into a plain QML module next to the tests.
set(test_qml_module ${CMAKE_CURRENT_BINARY_DIR}/qml/LocalTranslate)

file(MAKE_DIRECTORY ${test_qml_module})
file(WRITE ${test_qml_module}/qmldir
     "module LocalTranslate\nLanguageSelector 1.0 LanguageSelector.qml\n")

add_custom_command(TARGET qml_tests POST_BUILD
                   COMMAND ${CMAKE_COMMAND} -E copy_if_different
                           ${CMAKE_SOURCE_DIR}/LanguageSelector.qml
                           ${test_qml_module}/LanguageSelector.qml
                   COMMENT "Staging QML components for the tests")

add_test(NAME qml_tests
         COMMAND qml_tests -input ${CMAKE_CURRENT_SOURCE_DIR}
                           -import ${CMAKE_CURRENT_BINARY_DIR}/qml)

set_tests_properties(qml_tests PROPERTIES
                     ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
