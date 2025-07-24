# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause the
# plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# set(CMAKE_CXX_VISIBILITY_PRESET hidden)
project(
  Maths
  VERSION 0.0.1
  LANGUAGES CXX)
set(PROJECT_NAME maths)

add_library(
  ${PROJECT_NAME} SHARED
  src/Double.cpp
  src/Equations.cpp
  src/Line.cpp
  src/maths.cpp
  src/Matrix3.cpp
  src/Plane.cpp
  src/Shape.cpp
  src/Vector3.cpp
  src/Tests.cpp
  src/Constants.cpp
  src/Expose.cpp)
# find_library(mpfr REQUIRED)
if(CMAKE_BUILD_TYPE MATCHES "Debug")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
  # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer
  # -fsanitize=address") target_link_options(${PROJECT_NAME} PRIVATE
  # -fno-omit-frame-pointer -fsanitize=address)
endif()
add_executable(Test src/main.cpp)
target_link_options(Test PUBLIC -lmpfr)
target_link_libraries(Test PUBLIC ${PROJECT_NAME})

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER src/Expose.h
                                                 OUTPUT_NAME "maths")

target_compile_definitions(${PROJECT_NAME} PUBLIC DART_SHARED_LIB)
# target_link_libraries(${PROJECT_NAME} PUBLIC ${MPFR_LIB})
target_link_options(${PROJECT_NAME} PUBLIC -lmpfr)

if(ANDROID)
  # Support Android 15 16k page size
  target_link_options(${PROJECT_NAME} PRIVATE "-Wl,-z,max-page-size=16384")
endif()
