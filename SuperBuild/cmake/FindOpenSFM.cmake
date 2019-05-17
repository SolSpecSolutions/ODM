# Find OpenSFM Library
# Find the OpenSFM includes and library
# This Module defines
#  OpenSFM_INCLUDE_DIRS, where to find the header files
#
#  OpenSFM_LIBRARIES, libraries to link against to use OpenSFM
#  OpenSFM_ROOT_DIR, the base directory to search for Ceres
#  OpenSFM_FOUND, If false, do not try to use OpenSFM
#
# If OpenSFM_ROOT_DIR was defined in the environment, use it.

IF(NOT OpenSFM_ROOT_DIR AND NOT $ENV{OpenSFM_ROOT_DIR} STREQUAL "")
    SET(OpenSFM_ROOT_DIR $ENV{OpenSFM_ROOT_DIR})
ENDIF()

SET(_opensfm_SEARCH_DIRS
    ${OpenSFM_ROOT_DIR}
    /usr/local
    /sw 
    /opt/local
    /opt/csw
    /opt/lib/ceres
)

FIND_PATH(OpenSFM_INCLUDE_DIR
    NAME
        hahog.h
    HINTS
        ${_opensfm_SEARCH_DIRS}
    PATH_SUFFIXES
        include
)

INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(OpenSFM DEFAULT_MSG
    OpenSFM_INCLUDE_DIR)

IF(OpenSFM_FOUND)
    SET(OpenSFM_INCLUDE_DIRS ${OpenSFM_INCLUDE_DIR})
ENDIF(OpenSFM_FOUND)

MARK_AS_ADVANCED(
    OpenSFM_INCLUDE_DIR
)

