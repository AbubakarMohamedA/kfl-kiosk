# Project-level configuration.
cmake_minimum_required(VERSION 3.14)

# CMP0091 MUST be set before project() so CMAKE_MSVC_RUNTIME_LIBRARY is honoured.
# Without this, MSVC ignores the variable and injects /MDd in Debug configs,
# causing LNK2001 errors when linking Firebase's Release-compiled prebuilt libs
# (__imp__CrtDbgReport, __imp__calloc_dbg, std::_Crt_new_delete).
if(POLICY CMP0091)
  cmake_policy(SET CMP0091 NEW)
endif()

# Force Release CRT (/MD = MultiThreadedDLL) for ALL configurations.
# Firebase Windows prebuilt .lib files are compiled with /MD, so this must
# match to avoid unresolved external symbol linker errors.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL" CACHE STRING "" FORCE)

project(kflkiosk LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
if(DEFINED ENV{FLAVOR})
  set(APP_FLAVOR "$ENV{FLAVOR}")
else()
  set(APP_FLAVOR "default")
endif()

if(${APP_FLAVOR} STREQUAL "superadmin")
  set(BINARY_NAME "sss_admin")
  set(APP_TITLE "SSS Admin")
elseif(${APP_FLAVOR} STREQUAL "manager")
  set(BINARY_NAME "sss_manager")
  set(APP_TITLE "SSS Manager")
elseif(${APP_FLAVOR} STREQUAL "staff")
  set(BINARY_NAME "sss_staff")
  set(APP_TITLE "SSS Staff")
elseif(${APP_FLAVOR} STREQUAL "warehouse")
  set(BINARY_NAME "sss_warehouse")
  set(APP_TITLE "SSS Warehouse")
elseif(${APP_FLAVOR} STREQUAL "dashboard")
  set(BINARY_NAME "sss_dashboard")
  set(APP_TITLE "SSS Dashboard")
elseif(${APP_FLAVOR} STREQUAL "kiosk")
  set(BINARY_NAME "sss_kiosk")
  set(APP_TITLE "SSS Kiosk")
else()
  set(BINARY_NAME "kflkiosk")
  set(APP_TITLE "kflkiosk")
endif()

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()

# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)

# Fix for Firebase Windows SDK linker errors (LNK2001/LNK2019)
# Force all configurations to use Release-flavored Firebase libraries when building
# in non-Debug modes. This is necessary because some Firebase plugins may default
# to Debug libraries, which are incompatible with the forced Release CRT.
set(FIREBASE_LIBS_TO_REMAPP 
  firebase_app 
  firebase_auth 
  firebase_storage 
  firebase_firestore 
  firebase_remote_config
)
foreach(firebase_lib IN ITEMS ${FIREBASE_LIBS_TO_REMAPP})
  if(TARGET ${firebase_lib})
    get_target_property(firebase_lib_path ${firebase_lib} IMPORTED_LOCATION)
    if(firebase_lib_path)
      string(REPLACE "Debug" "Release" firebase_lib_release_path ${firebase_lib_path})
      if(EXISTS "${firebase_lib_release_path}")
        set_target_properties(${firebase_lib} PROPERTIES
          IMPORTED_LOCATION_DEBUG "${firebase_lib_path}"
          IMPORTED_LOCATION_RELEASE "${firebase_lib_release_path}"
          IMPORTED_LOCATION_PROFILE "${firebase_lib_release_path}"
        )
        message(STATUS "Remapped ${firebase_lib} to Release: ${firebase_lib_release_path}")
      endif()
    endif()
  endif()
endforeach()

# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)