project(odm_georef)
cmake_minimum_required(VERSION 2.8)

find_package(PROJ4 REQUIRED)

# Add compiler options.
add_definitions(-Wall -Wextra -Wconversion -pedantic -std=c++11)

# Find pcl at the location specified by PCL_DIR
find_package(VTK 7.1 REQUIRED)
find_package(PCL 1.8 HINTS "${PCL_DIR}/share/pcl-1.8")
find_package(Boost 1.69)
# Find OpenCV at the default location
find_package(OpenCV HINTS "${OPENCV_DIR}" REQUIRED)

# find_package(nlohmann_json 3.7.0 REQUIRED)
# Only link with required opencv modules.
set(OpenCV_LIBS opencv_core opencv_imgproc opencv_highgui)

# Add the PCL and Eigen include dirs.
# Necessary since the PCL_INCLUDE_DIR variable set bu find_package is broken.)
include_directories(${PCL_ROOT}/include/pcl-${PCL_VERSION_MAJOR}.${PCL_VERSION_MINOR})
include_directories(${EIGEN_ROOT})

# PDAL and jsoncpp
find_package(PDAL REQUIRED CONFIG)
include_directories(${PDAL_INCLUDE_DIRS})
# include_directories("${PROJECT_SOURCE_DIR}/../../SuperBuild/src/pdal/vendor/jsoncpp/dist")
link_directories(${PDAL_LIBRARY_DIRS})
add_definitions(${PDAL_DEFINITIONS})

# Add source directory
aux_source_directory("./src" SRC_LIST)

# Add exectuteable
add_executable(${PROJECT_NAME} ${SRC_LIST})

# Link
target_link_libraries(${PROJECT_NAME} ${BOOST_LIBRARIES} ${PCL_COMMON_LIBRARIES} ${PCL_IO_LIBRARIES} ${PCL_SURFACE_LIBRARIES} ${PROJ4_LIBRARY} ${OpenCV_LIBS} ${PDAL_LIBRARIES})
