set(_proj_name mvstexturing)
set(_SB_BINARY_DIR "${SB_BINARY_DIR}/${_proj_name}")

ExternalProject_Add(${_proj_name}
  DEPENDS           
  PREFIX            ${_SB_BINARY_DIR}
  TMP_DIR           ${_SB_BINARY_DIR}/tmp
  STAMP_DIR         ${_SB_BINARY_DIR}/stamp
  #--Download step--------------
  DOWNLOAD_DIR      ${SB_DOWNLOAD_DIR}/${_proj_name}
  URL               https://github.com/npcasler/mvs-texturing/archive/Rebase_to_nmoehrle.zip
  #--Update/Patch step----------
  UPDATE_COMMAND    ""
  #--Configure step-------------
  SOURCE_DIR        ${SB_SOURCE_DIR}/${_proj_name}
  CMAKE_ARGS
    -DWITH_UTILITIES=OFF
    -DRESEARCH=OFF
    -DCMAKE_BUILD_TYPE:STRING=Release
    -DCMAKE_INSTALL_PREFIX:PATH=${SB_INSTALL_DIR}
  #--Build step-----------------
  BINARY_DIR        ${_SB_BINARY_DIR}
  #--Install step---------------
  INSTALL_DIR       ${SB_INSTALL_DIR}
  #--Output logging-------------
  LOG_DOWNLOAD      OFF
  LOG_CONFIGURE     OFF
  LOG_BUILD         OFF
)
