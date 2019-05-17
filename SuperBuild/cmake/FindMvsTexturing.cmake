# - Find MvsTexturing Library
# Find the native MvsTexturing include and library
# This module defines
# MvsTexturing_INCLUDE_DIRS, where to find the headers.
#
# MvsTexturing_LIBRARIES, libraries to link against to use MvsTexturing
# MvsTexturing_ROOT_DIR, The base directory to search for MvsTexturing,
#                        This can also be an environment variable
# MvsTexturing_FOUND, If false, do not try to use MvsTexturing

IF(NOT MvsTexturing_ROOT_DIR AND NOT $ENV{MvsTexturing_ROOT_DIR} STREQUAL "")
    SET(MvsTexturing_ROOT_DIR $ENV{MvsTexturing_ROOT_DIR})
ENDIF()

SET(_mvstexturing_SEARCH_DIRS
    ${MvsTexturing_ROOT_DIR}
    /usr/local
    /sw
    /opt/local
    /opt/csw
    /opt/lib/tex
)

FIND_PATH(MvsTexturing_INCLUDE_DIR
    NAMES
        tex/texturing.h
    HINTS
        ${_mvstexturing_SEARCH_DIRS}
    PATH_SUFFIXES
        include
)

FIND_LIBRARY(MvsTexturing_LIBRARY
    NAMES
        tex
    HINTS
        ${_mvstexturing_SEARCH_DIRS}
    PATH_SUFFIXES
        lib64 lib
)

#Handle the QUIETLY and REQUIRED arguments and set MvsTexturing_FOUND to TRUE if
# all listed variables are TRUE
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(tex DEFAULT_MSG
    MvsTexturing_LIBRARY MvsTexturing_INCLUDE_DIR)

IF(MvsTexturing_FOUND)
    SET(MvsTexturing_LIBRARIES ${MvsTexturing_LIBRARY})
    SET(MvsTexturing_INCLUDE_DIRS ${MvsTexturing_INCLUDE_DIR})
ENDIF(MvsTexturing_FOUND)

MARK_AS_ADVANCED(
    MvsTexturing_INCLUDE_DIR
    MvsTexturing_LIBRARY
)
