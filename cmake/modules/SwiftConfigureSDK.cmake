# Variable that tracks the set of configured SDKs.
#
# Each element in this list is an SDK for which the various
# SWIFT_SDK_${name}_* variables are defined. Swift libraries will be
# built for each variant.
set(SWIFT_CONFIGURED_SDKS "") # TODO: Rename to SWIFT_CONFIGURED_TARGETS
set(SWIFT_CONFIGURED_SDK_NAMES "")

# Report the given SDK to the user.
function(_report_sdk prefix)
  message(STATUS "${SWIFT_SDK_${prefix}_NAME} SDK:")
  message(STATUS "  Path: ${SWIFT_SDK_${prefix}_PATH}")
  message(STATUS "  Version: ${SWIFT_SDK_${prefix}_VERSION}")
  message(STATUS "  Build number: ${SWIFT_SDK_${prefix}_BUILD_NUMBER}")
  message(STATUS "  Deployment version: ${SWIFT_SDK_${prefix}_DEPLOYMENT_VERSION}")
  message(STATUS "  Library subdir: ${SWIFT_SDK_${prefix}_LIB_SUBDIR}")
  message(STATUS "  Version min name: ${SWIFT_SDK_${prefix}_VERSION_MIN_NAME}")
  message(STATUS "  Triple: ${SWIFT_SDK_${prefix}_ARCH_${arch}_TRIPLE}")
  message(STATUS "  Architectures: ${SWIFT_SDK_${prefix}_ARCHITECTURE}")
  message(STATUS "")
endfunction()

# Configure an SDK
#
# Usage:
#   configure_sdk_darwin(
#     prefix             # Prefix to use for SDK variables (e.g., OSX)
#     name               # Display name for this SDK
#     deployment_version # Deployment version
#     xcrun_name         # SDK name to use with xcrun
#     version_min_name   # The name used in the -mOS-version-min flag
#     triple_name        # The name used in Swift's -triple
#     architectures      # A list of architectures this SDK supports
#   )
#
# Sadly there are three OS naming conventions.
# xcrun SDK name:   macosx iphoneos iphonesimulator (+ version)
# -mOS-version-min: macosx ios      ios-simulator
# swift -triple:    macosx ios      ios
#
# This macro attempts to configure a given SDK. When successful, it
# defines a number of variables:
#
#   SWIFT_SDK_${prefix}_NAME                Display name for the SDK
#   SWIFT_SDK_${prefix}_VERSION             SDK version number (e.g., 10.9, 7.0)
#   SWIFT_SDK_${prefix}_BUILD_NUMBER        SDK build number (e.g., 14A389a)
#   SWIFT_SDK_${prefix}_DEPLOYMENT_VERSION  Deployment version (e.g., 10.9, 7.0)
#   SWIFT_SDK_${prefix}_LIB_SUBDIR          Library subdir for this SDK
#   SWIFT_SDK_${prefix}_VERSION_MIN_NAME    Version min name for this SDK
#   SWIFT_SDK_${prefix}_TRIPLE_NAME         Triple name for this SDK
#   SWIFT_SDK_${prefix}_ARCHITECTURES       Architectures (as a list)
#   SWIFT_SDK_${prefix}_ARCH_${ARCH}_TRIPLE Triple name
macro(configure_sdk_darwin
    prefix name deployment_version xcrun_name
    version_min_name triple_name architectures)
  # Note: this has to be implemented as a macro because it sets global
  # variables.

  # Because we calculate our own triple, we need to validate
  # architectures here.

  set(OSX_VALID_ARCHITECTURES "x86_64")
  set(IOS_VALID_ARCHITECTURES "armv7;armv7s;arm64")
  set(TVOS_VALID_ARCHITECTURES "arm64")
  set(WATCHOS_VALID_ARCHITECTURES "armv7k")
  set(IOS_SIMULATOR_VALID_ARCHITECTURES "i386;x86_64")
  set(TVOS_SIMULATOR_VALID_ARCHITECTURES "x86_64")
  set(WATCHOS_SIMULATOR_VALID_ARCHITECTURES "i386")

  list_subtract("${architectures}" "${${prefix}_VALID_ARCHITECTURES}" invalid_archs)
  if(invalid_archs)
    message(FATAL_ERROR "${invalid_archs} are not recognised architectures for ${name}")
  endif()

  # Find the SDK
  execute_process(
      COMMAND "xcrun" "--sdk" "${xcrun_name}" "--show-sdk-path"
      OUTPUT_VARIABLE SWIFT_SDK_${prefix}_PATH
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(NOT EXISTS "${SWIFT_SDK_${prefix}_PATH}/System/Library/Frameworks/module.map")
    message(FATAL_ERROR "${name} SDK not found at ${SWIFT_SDK_${prefix}_PATH}.")
  endif()

  if(NOT EXISTS "${SWIFT_SDK_${prefix}_PATH}/System/Library/Frameworks/module.map")
    message(FATAL_ERROR "${name} SDK not found at ${SWIFT_SDK_${prefix}_PATH}.")
  endif()

  # Determine the SDK version we found.
  execute_process(
    COMMAND "defaults" "read" "${SWIFT_SDK_${prefix}_PATH}/SDKSettings.plist" "Version"
      OUTPUT_VARIABLE SWIFT_SDK_${prefix}_VERSION
      OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND "xcodebuild" "-sdk" "${SWIFT_SDK_${prefix}_PATH}" "-version" "ProductBuildVersion"
      OUTPUT_VARIABLE SWIFT_SDK_${prefix}_BUILD_NUMBER
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  
  unset(SWIFT_SDK_TARGETS_FOR_${prefix})
  foreach(arch ${architectures})
    # Set other variables.
    set(prefix_arch "${prefix}_${arch}")
    set(SWIFT_SDK_${prefix_arch}_SDK_ID "${prefix}")
    set(SWIFT_SDK_${prefix_arch}_NAME "${name}")
    set(SWIFT_SDK_${prefix_arch}_PATH "${SWIFT_SDK_${prefix}_PATH}")
    set(SWIFT_SDK_${prefix_arch}_VERSION "${SWIFT_SDK_${prefix}_VERSION}")
    set(SWIFT_SDK_${prefix_arch}_BUILD_NUMBER "${SWIFT_SDK_${prefix}_BUILD_NUMBER}")
    set(SWIFT_SDK_${prefix_arch}_DEPLOYMENT_VERSION "${deployment_version}")
    set(SWIFT_SDK_${prefix_arch}_LIB_SUBDIR "${xcrun_name}")
    set(SWIFT_SDK_${prefix_arch}_VERSION_MIN_NAME "${version_min_name}")
    set(SWIFT_SDK_${prefix_arch}_TRIPLE_NAME "${triple_name}")
    set(SWIFT_SDK_${prefix_arch}_ARCHITECTURE "${arch}")
    set(SWIFT_SDK_${prefix_arch}_ARCH_${arch}_TRIPLE
        "${arch}-apple-${triple_name}${deployment_version}")
    
    list(APPEND SWIFT_CONFIGURED_SDKS "${prefix_arch}")
    list(APPEND SWIFT_SDK_TARGETS_FOR_${prefix} "${prefix_arch}")
    list(APPEND SWIFT_SDK_NAMES "${prefix}")

    message("Configured targets for ${prefix}: ${SWIFT_SDK_TARGETS_FOR_${prefix}}")

    _report_sdk("${prefix_arch}")
  endforeach()

  # Add this to the list of known SDKs.
  set(SWIFT_CONFIGURED_SDKS "${SWIFT_CONFIGURED_SDKS}" CACHE STRING
      "The SDKs which have been configured to build")

endmacro()

macro(configure_sdk_unix
    prefix name lib_subdir triple_name arch triple sdkpath)
  # Note: this has to be implemented as a macro because it sets global
  # variables.

  # Hack: We can clear this variable now because the host is always the
  # first to configure.
  if("${arch}" STREQUAL "${SWIFT_HOST_VARIANT_ARCH}")
    unset(SWIFT_SDK_TARGETS_FOR_${prefix})
  endif()

  set(prefix_arch "${prefix}_${arch}")
  set(SWIFT_SDK_${prefix_arch}_SDK_ID "${prefix}")
  set(SWIFT_SDK_${prefix_arch}_NAME "${name}")
  set(SWIFT_SDK_${prefix_arch}_PATH "${sdkpath}")
  set(SWIFT_SDK_${prefix_arch}_VERSION "don't use")
  set(SWIFT_SDK_${prefix_arch}_BUILD_NUMBER "don't use")
  set(SWIFT_SDK_${prefix_arch}_DEPLOYMENT_VERSION "don't use")
  set(SWIFT_SDK_${prefix_arch}_LIB_SUBDIR "${lib_subdir}")
  set(SWIFT_SDK_${prefix_arch}_VERSION_MIN_NAME "")
  set(SWIFT_SDK_${prefix_arch}_TRIPLE_NAME "${triple_name}")
  set(SWIFT_SDK_${prefix_arch}_ARCHITECTURE "${arch}")
  set(SWIFT_SDK_${prefix_arch}_ARCH_${arch}_TRIPLE "${triple}")

  # Add this to the list of known SDKs.
  list(APPEND SWIFT_CONFIGURED_SDKS "${prefix_arch}")
  set(SWIFT_CONFIGURED_SDKS "${SWIFT_CONFIGURED_SDKS}" CACHE STRING
      "The SDKs which have been configured to build")
  list(APPEND SWIFT_SDK_TARGETS_FOR_${prefix} "${prefix_arch}")
  list(APPEND SWIFT_SDK_NAMES "${prefix}")

  _report_sdk("${prefix_arch}")
endmacro()

# Configure a variant of a certain SDK
#
# In addition to the SDK and architecture, a variant determines build settings.
#
# FIXME: this is not wired up with anything yet.
function(configure_target_variant prefix name sdk build_config lib_subdir)
  set(SWIFT_VARIANT_${prefix}_NAME               ${name})
  set(SWIFT_VARIANT_${prefix}_SDK_PATH           ${SWIFT_SDK_${sdk}_PATH})
  set(SWIFT_VARIANT_${prefix}_VERSION            ${SWIFT_SDK_${sdk}_VERSION})
  set(SWIFT_VARIANT_${prefix}_BUILD_NUMBER       ${SWIFT_SDK_${sdk}_BUILD_NUMBER})
  set(SWIFT_VARIANT_${prefix}_DEPLOYMENT_VERSION ${SWIFT_SDK_${sdk}_DEPLOYMENT_VERSION})
  set(SWIFT_VARIANT_${prefix}_LIB_SUBDIR         "${lib_subdir}/${SWIFT_SDK_${sdk}_LIB_SUBDIR}")
  set(SWIFT_VARIANT_${prefix}_VERSION_MIN_NAME   ${SWIFT_SDK_${sdk}_VERSION_MIN_NAME})
  set(SWIFT_VARIANT_${prefix}_TRIPLE_NAME        ${SWIFT_SDK_${sdk}_TRIPLE_NAME})
  set(SWIFT_VARIANT_${prefix}_ARCHITECTURE      ${SWIFT_SDK_${sdk}_ARCHITECTURES})
endfunction()

