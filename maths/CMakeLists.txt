# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause the
# plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)
# include(ExternalProject) set(CMAKE_CXX_VISIBILITY_PRESET hidden)
project(
  Maths
  VERSION 0.0.1
  LANGUAGES CXX)
set(PROJECT_NAME Maths)

add_library(
  ${PROJECT_NAME} SHARED
  src/Double.cpp
  src/Equations.cpp
  src/Line.cpp
  src/Matrix3.cpp
  src/Plane.cpp
  src/Shape.cpp
  src/Vector3.cpp
  src/Tests.cpp
  src/Constants.cpp
  src/Expose.cpp)

# ExternalProject_Add( GMP SOURCE_DIR "${CMAKE_SOURCE_DIR}/lib/gmp-6.3.0"
# CONFIGURE_COMMAND "${CMAKE_SOURCE_DIR}/lib/gmp-6.3.0/configure")
# ExternalProject_Add( MPFR SOURCE_DIR "${CMAKE_SOURCE_DIR}/lib/mpfr-4.2.2"
# CONFIGURE_COMMAND "${CMAKE_SOURCE_DIR}/lib/mpfr-4.2.2/configure")
# ExternalProject_Add_StepDependencies(MPFR build GMP)

add_executable(Test src/main.cpp)
if(CMAKE_BUILD_TYPE MATCHES "Debug")
  message("Building for debug")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
  # set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-omit-frame-pointer
  # -fsanitize=address") target_link_options(${PROJECT_NAME} PRIVATE
  # -fno-omit-frame-pointer -fsanitize=address)
elseif(CMAKE_BUILD_TYPE MATCHES "Profile")
  message("Building with profiling enabled")
  target_compile_definitions(${PROJECT_NAME} PRIVATE TRACY_ENABLE)
  target_link_libraries(${PROJECT_NAME} PUBLIC TracyClient)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g ${CMAKE_CXX_FLAGS_RELEASE}")
  target_compile_definitions(Test PRIVATE TRACY_ENABLE)
  target_link_libraries(Test PUBLIC TracyClient)
endif()
target_link_options(Test PUBLIC -lmpfr)
target_link_libraries(Test PUBLIC ${PROJECT_NAME})
target_include_directories(
  ${PROJECT_NAME} PUBLIC $ENV{MPFR_DIR}/include $ENV{GMP_DIR}/include
                         $ENV{TRACY_DIR}/include)
if(CMAKE_SYSTEM_PROCESSOR MATCHES aarch64)
  target_link_directories(${PROJECT_NAME} PUBLIC $ENV{MPFR_LIB_DIR64}/lib)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES armv7-a)
  target_link_directories(${PROJECT_NAME} PUBLIC $ENV{MPFR_LIB_DIR}/lib)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES i686)
  # target_link_directories(${PROJECT_NAME} PUBLIC $ENV{MPFR_LIB_DIRI686}/lib)
  message(FATAL_ERROR "Cannot currently compile for x86")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES x86_64)
  target_link_directories(${PROJECT_NAME} PUBLIC $ENV{MPFR_LIB_DIRX86_64}/lib)
else()
  message(FATAL_ERROR "Cannot compile for architecture "
                      ${CMAKE_SYSTEM_PROCESSOR})
endif()
# message("architecture " ${CMAKE_SYSTEM_PROCESSOR})
# target_link_directories(${PROJECT_NAME} PUBLIC $ENV{MPFR_LIB_DIR64}/lib)
# target_include_directories(${PROJECT_NAME} PUBLIC
# "${CMAKE_SOURCE_DIR}/lib/mpfr_4.2.2/include")

# ExternalProject_Get_Property(MPFR install_dir)
# target_include_directories(${PROJECT_NAME} PUBLIC ${install_dir}/include)

# add_dependencies(${PROJECT_NAME} MPFR) target_link_libraries(${PROJECT_NAME}
# ${install_dir}/lib/libmpfr.lib)

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER src/Expose.h
                                                 OUTPUT_NAME "maths")

target_compile_definitions(${PROJECT_NAME} PUBLIC DART_SHARED_LIB)
# target_link_libraries(${PROJECT_NAME} PUBLIC ${MPFR_LIB})
target_link_options(${PROJECT_NAME} PUBLIC -lmpfr)

if(ANDROID)
  # Support Android 15 16k page size
  target_link_options(${PROJECT_NAME} PRIVATE "-Wl,-z,max-page-size=16384")
endif()
