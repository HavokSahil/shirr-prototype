cmake_minimum_required(VERSION 3.4.1)

add_library(essentia SHARED IMPORTED)
set_target_properties(essentia PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libessentia.so)

include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/external/eigen)

add_library(essentia_jni SHARED essentia_jni.cpp)

target_link_libraries(essentia_jni
    essentia
    log
)

target_include_directories(
    essentia_jni PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/external/eigen
)