cmake_minimum_required(VERSION 2.8.12)

# Add path for custom CMake modules.
list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

include(SwiftBuildType)

#
# User-configurable options.
#
# Instead of invoking CMake directly and configuring these options manually,
# consider using build-script instead.
#

set(SWIFT_STDLIB_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
    "Build type for the Swift standard library and SDK overlays [Debug, RelWithDebInfo, Release, MinSizeRel]")
set_property(CACHE SWIFT_STDLIB_BUILD_TYPE PROPERTY
    STRINGS "Debug" "RelWithDebInfo" "Release" "MinSizeRel")

is_build_type_optimized("${SWIFT_STDLIB_BUILD_TYPE}" swift_optimized)
if(swift_optimized)
  set(SWIFT_STDLIB_ASSERTIONS_default FALSE)
else()
  set(SWIFT_STDLIB_ASSERTIONS_default TRUE)
endif()
option(SWIFT_STDLIB_ASSERTIONS
    "Enable internal checks for the Swift standard library (useful for debugging the library itself, does not affect checks required for safety)"
    "${SWIFT_STDLIB_ASSERTIONS_default}")

option(SWIFT_SERIALIZE_STDLIB_UNITTEST
    "Compile the StdlibUnittest module with -sil-serialize-all to increase the test coverage for the optimizer"
    FALSE)

option(SWIFT_STDLIB_SIL_DEBUGGING
    "Compile the Swift standard library with -gsil to enable debugging and profiling on SIL level"
    FALSE)

option(SWIFT_CHECK_INCREMENTAL_COMPILATION
    "Check if incremental compilation works when compiling the Swift libraries"
    FALSE)

option(SWIFT_BUILD_TOOLS
    "Build the Swift compiler and other tools"
    TRUE)

option(SWIFT_BUILD_STDLIB
    "Build the Swift standard library (independent of the SDK headers)"
    TRUE)

option(SWIFT_BUILD_SDK_OVERLAY
    "Build Swift SDK overlay"
    TRUE)

option(SWIFT_BUILD_STATIC_STDLIB
    "Build static variants of the Swift standard library and SDK overlay"
    FALSE)

option(SWIFT_BUILD_PERF_TESTSUITE
    "Create targets for swift performance benchmarks."
    FALSE)

option(SWIFT_INCLUDE_TESTS "Create targets for building/running tests." TRUE)

option(SWIFT_INCLUDE_DOCS
    "Create targets for building docs."
    TRUE)

option(SWIFT_BUILD_RUNTIME_WITH_HOST_COMPILER
       "Use the host compiler and not the internal clang to build the swift runtime"
       FALSE)

set(SWIFT_ANALYZE_CODE_COVERAGE FALSE CACHE STRING
    "Build Swift with code coverage instrumenting enabled [FALSE, NOT-MERGED, MERGED]")
set_property(CACHE SWIFT_ANALYZE_CODE_COVERAGE PROPERTY
    STRINGS FALSE "NOT-MERGED" "MERGED")

set(SWIFT_VERSION "3.0" CACHE STRING
    "The user-visible version of the Swift compiler")
set(SWIFT_VENDOR "" CACHE STRING
    "The vendor name of the Swift compiler")
set(SWIFT_COMPILER_VERSION "" CACHE STRING
    "The internal version of the Swift compiler")
set(CLANG_COMPILER_VERSION "" CACHE STRING
    "The internal version of the Clang compiler")

# Indicate whether Swift should attempt to use the gold linker.
# This is not used on Darwin.
set(SWIFT_ENABLE_GOLD_LINKER FALSE CACHE BOOL
    "Enable using the gold linker when available")

set(_SWIFT_KNOWN_INSTALL_COMPONENTS
    "autolink-driver;compiler;clang-builtin-headers;clang-resource-dir-symlink;clang-builtin-headers-in-clang-resource-dir;stdlib;stdlib-experimental;sdk-overlay;editor-integration;tools;testsuite-tools;toolchain-dev-tools;dev;license;sourcekit-xpc-service;sourcekit-inproc;swift-remote-mirror-headers")

# Set the SWIFT_INSTALL_COMPONENTS variable to the default value if it is not passed in via -D
set(SWIFT_INSTALL_COMPONENTS "${_SWIFT_KNOWN_INSTALL_COMPONENTS}" CACHE STRING
    "A semicolon-separated list of components to install ${_SWIFT_KNOWN_INSTALL_COMPONENTS}")
# Components are disjoint set of files that can be installed by Swift.  The
# components would approximately correspond to packages in a Debian-style Linux
# packaging.  The following components are defined:
#
# * autolink-driver -- the Swift driver support tools
# * compiler -- the Swift compiler and (on supported platforms) the REPL.
# * clang-builtin-headers -- install a copy of Clang builtin headers under
#   'lib/swift/clang'.  This is useful when Swift compiler is installed in
#   isolation.
# * clang-resource-dir-symlink -- install a symlink to the Clang resource
#   directory (which contains builtin headers) under 'lib/swift/clang'.  This is
#   useful when Clang and Swift are installed side-by-side.
# * stdlib -- the Swift standard library.
# * stdlib-experimental -- the Swift standard library module for experimental
#   APIs.
# * sdk-overlay -- the Swift SDK overlay.
# * editor-integration -- scripts for Swift integration in IDEs other than
#   Xcode;
# * tools -- tools (other than the compiler) useful for developers writing
#   Swift code.
# * testsuite-tools -- extra tools required to run the Swift testsuite.
# * toolchain-dev-tools -- install development tools useful in a shared toolchain
# * dev -- headers and libraries required to use Swift compiler as a library.

set(SWIFT_DEPLOYMENT_TARGETS "" CACHE STRING
    "If non-empty, limits building target binaries only to specified SDKs (despite other SDKs being available)")

set(SWIFT_PRIMARY_VARIANT_SDK "" CACHE STRING
    "Primary SDK for target binaries")
set(SWIFT_PRIMARY_VARIANT_ARCH "" CACHE STRING
    "Primary arch for target binaries")

set(SWIFT_NATIVE_LLVM_TOOLS_PATH "" CACHE STRING
    "Path to the directory that contains LLVM tools that are executable on the build machine")

set(SWIFT_NATIVE_CLANG_TOOLS_PATH "" CACHE STRING
    "Path to the directory that contains Clang tools that are executable on the build machine")

set(SWIFT_NATIVE_SWIFT_TOOLS_PATH "" CACHE STRING
    "Path to the directory that contains Swift tools that are executable on the build machine")

option(SWIFT_ENABLE_LTO
  "If set to true, build the swift compiler with link time optimization enabled" FALSE)

# The following only works with the Ninja generator in CMake >= 3.0.
set(SWIFT_PARALLEL_LINK_JOBS "" CACHE STRING
  "Define the maximum number of linker jobs for swift.")
set(SWIFT_ANDROID_NDK_PATH "" CACHE STRING
  "Path to the directory that contains the Android NDK tools that are executable on the build machine")
set(SWIFT_ANDROID_NDK_GCC_VERSION "" CACHE STRING
  "The GCC version to use when building for Android. Currently only 4.9 is supported.")
set(SWIFT_ANDROID_SDK_PATH "" CACHE STRING
  "Path to the directory that contains the Android SDK tools that will be passed to the swiftc frontend")
set(SWIFT_ANDROID_ICU_UC "" CACHE STRING
  "Path to a directory containing libicuuc.so")
set(SWIFT_ANDROID_ICU_UC_INCLUDE "" CACHE STRING
  "Path to a directory containing headers for libicuuc")
set(SWIFT_ANDROID_ICU_I18N "" CACHE STRING
  "Path to a directory containing libicui18n.so")
set(SWIFT_ANDROID_ICU_I18N_INCLUDE "" CACHE STRING
  "Path to a directory containing headers libicui18n")

#
# User-configurable Darwin-specific options.
#

option(SWIFT_EMBED_BITCODE_SECTION
    "If non-empty, embeds LLVM bitcode binary sections in the standard library and overlay binaries for supported platforms"
    FALSE)

option(SWIFT_RUNTIME_CRASH_REPORTER_CLIENT
    "Whether to enable CrashReporter integration"
    FALSE)

set(SWIFT_DARWIN_XCRUN_TOOLCHAIN "XcodeDefault" CACHE STRING
    "The name of the toolchain to pass to 'xcrun'")

set(SWIFT_DARWIN_STDLIB_INSTALL_NAME_DIR "@rpath" CACHE STRING
    "The directory of the install_name for standard library dylibs")

set(SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX "10.9" CACHE STRING
    "Minimum deployment target version for OS X")

set(SWIFT_DARWIN_DEPLOYMENT_VERSION_IOS "7.0" CACHE STRING
    "Minimum deployment target version for iOS")

set(SWIFT_DARWIN_DEPLOYMENT_VERSION_TVOS "9.0" CACHE STRING
    "Minimum deployment target version for tvOS")

set(SWIFT_DARWIN_DEPLOYMENT_VERSION_WATCHOS "2.0" CACHE STRING
    "Minimum deployment target version for watchOS")

#
# User-configurable debugging options.
#

option(SWIFT_AST_VERIFIER
    "Enable the AST verifier in the built compiler, and run it on every compilation"
    TRUE)

option(SWIFT_SIL_VERIFY_ALL
    "Run SIL verification after each transform when building Swift files in the build process"
    FALSE)

option(SWIFT_EMIT_SORTED_SIL_OUTPUT
    "Sort SIL output by name to enable diffing of output"
    FALSE)

if(SWIFT_STDLIB_ASSERTIONS)
  set(SWIFT_RUNTIME_CLOBBER_FREED_OBJECTS_default TRUE)
else()
  set(SWIFT_RUNTIME_CLOBBER_FREED_OBJECTS_default FALSE)
endif()

option(SWIFT_RUNTIME_CLOBBER_FREED_OBJECTS
    "Overwrite memory for deallocated Swift objects"
    "${SWIFT_RUNTIME_CLOBBER_FREED_OBJECTS_default}")

#
# User-configurable experimental options.  Do not use in production builds.
#

set(SWIFT_EXPERIMENTAL_EXTRA_FLAGS "" CACHE STRING
    "Extra flags to pass when compiling swift files.  Use this option *only* for one-off experiments")

set(SWIFT_EXPERIMENTAL_EXTRA_REGEXP_FLAGS "" CACHE STRING
  "A list of [module_regexp1;flags1;module_regexp2;flags2,...] which can be used to apply specific flags to modules that match a cmake regexp. It always applies the first regexp that matches.")

set(SWIFT_EXPERIMENTAL_EXTRA_NEGATIVE_REGEXP_FLAGS "" CACHE STRING
    "A list of [module_regexp1;flags1;module_regexp2;flags2,...] which can be used to apply specific flags to modules that do not match a cmake regexp. It always applies the first regexp that does not match. The reason this is necessary is that cmake does not provide negative matches in the regex. Instead you have to use NOT in the if statement requiring a separate variable.")

option(SWIFT_RUNTIME_ENABLE_LEAK_CHECKER
  "Should the runtime be built with support for non-thread-safe leak detecting entrypoints"
  FALSE)

option(SWIFT_STDLIB_ENABLE_RESILIENCE
    "Build the standard libraries and overlays with resilience enabled; see docs/LibraryEvolution.rst"
    FALSE)

option(SWIFT_STDLIB_SIL_SERIALIZE_ALL
    "Build the standard libraries and overlays serializing all method bodies"
    TRUE)

if(SWIFT_SERIALIZE_STDLIB_UNITTEST AND SWIFT_STDLIB_ENABLE_RESILIENCE)
  message(WARNING "Ignoring SWIFT_SERIALIZE_STDLIB_UNITTEST because SWIFT_STDLIB_ENABLE_RESILIENCE is set")
  set(SWIFT_SERIALIZE_STDLIB_UNITTEST FALSE)
endif()

if(SWIFT_STDLIB_SIL_SERIALIZE_ALL AND SWIFT_STDLIB_ENABLE_RESILIENCE)
  message(WARNING "Ignoring SWIFT_STDLIB_SIL_SERIALIZE_ALL because SWIFT_STDLIB_ENABLE_RESILIENCE is set")
  set(SWIFT_STDLIB_SIL_SERIALIZE_ALL FALSE)
endif()

#
# End of user-configurable options.
#

set(SWIFT_BUILT_STANDALONE FALSE)
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  set(SWIFT_BUILT_STANDALONE TRUE)
endif()

if(SWIFT_BUILT_STANDALONE)
  project(Swift C CXX ASM)
endif()

if("${CMAKE_SYSTEM_NAME}" STREQUAL "")
  message(FATAL_ERROR "CMAKE_SYSTEM_NAME is empty!")
endif()
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
  set(SWIFT_BUILD_SOURCEKIT_default TRUE)
else()
  set(SWIFT_BUILD_SOURCEKIT_default FALSE)
endif()
option(SWIFT_BUILD_SOURCEKIT
    "Build SourceKit"
    ${SWIFT_BUILD_SOURCEKIT_default})

#
# Include CMake modules
#

include(CheckCXXSourceRuns)
include(CMakeParseArguments)
include(SwiftTranslateFlag)
include(SwiftHandleGybSources)
include(SwiftSetIfArchBitness)
include(SwiftSource)
include(AddSwift)
include(SwiftConfigureSDK)
include(SwiftInstallComponents)
include(SwiftGetConfigurationTypes)
include(SwiftApplyXcodeSubstitutions)
include(SwiftList)

swift_configure_install_components("${SWIFT_INSTALL_COMPONENTS}")

if("${CMAKE_VERSION}" VERSION_LESS "3.0")
  set(SWIFT_CMAKE_HAS_GENERATOR_EXPRESSIONS FALSE)
else()
  set(SWIFT_CMAKE_HAS_GENERATOR_EXPRESSIONS TRUE)
endif()

# lipo is used to create universal binaries.
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
  include(SwiftDarwin)
  find_toolchain_tool(LIPO "${SWIFT_DARWIN_XCRUN_TOOLCHAIN}" lipo)
endif()

if("${SWIFT_NATIVE_LLVM_TOOLS_PATH}" STREQUAL "")
  set(SWIFT_CROSS_COMPILING FALSE)
else()
  set(SWIFT_CROSS_COMPILING TRUE)
endif()

# Reset CMAKE_SYSTEM_PROCESSOR if not cross-compiling.
# CMake refuses to use `uname -m` on OS X
# http://public.kitware.com/Bug/view.php?id=10326
if(NOT CMAKE_CROSSCOMPILING AND CMAKE_SYSTEM_PROCESSOR STREQUAL "i386")
  execute_process(
      COMMAND "uname" "-m"
      OUTPUT_VARIABLE CMAKE_SYSTEM_PROCESSOR
      OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

include(SwiftSharedCMakeConfig)

# Support building Swift as a standalone project, using LLVM as an
# external library.
if(SWIFT_BUILT_STANDALONE)
  swift_common_standalone_build_config(SWIFT SWIFT_CROSS_COMPILING)
else()
  swift_common_unified_build_config(SWIFT)
endif()

if(NOT EXISTS "${CLANG_MAIN_INCLUDE_DIR}/clang/AST/Decl.h")
  message(FATAL_ERROR "Clang is missing from llvm/tools subdirectory.")
endif()

# This could be computed using ${CMAKE_CFG_INTDIR} if we want to link Swift
# against a matching LLVM build configuration.  However, we usually want to be
# flexible and allow linking a debug Swift against optimized LLVM.
set(LLVM_RUNTIME_OUTPUT_INTDIR "${LLVM_BINARY_DIR}")
set(LLVM_LIBRARY_OUTPUT_INTDIR "${LLVM_LIBRARY_DIR}")

set(SWIFT_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(SWIFT_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")

set(SWIFT_RUNTIME_OUTPUT_INTDIR "${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/bin")
set(SWIFT_LIBRARY_OUTPUT_INTDIR "${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/lib")
if("${SWIFT_NATIVE_SWIFT_TOOLS_PATH}" STREQUAL "")
  set(SWIFT_NATIVE_SWIFT_TOOLS_PATH "${SWIFT_RUNTIME_OUTPUT_INTDIR}")
endif()

# We'll need this once we have generated headers
include_directories(BEFORE
  ${CMAKE_CURRENT_BINARY_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  )

# A convenience pattern to match Darwin platforms. Example:
#  if(SWIFT_HOST_VARIANT MATCHES "${SWIFT_DARWIN_VARIANTS}")
#     ...
#  endif()
set(SWIFT_DARWIN_VARIANTS "^(macosx|iphoneos|iphonesimulator|appletvos|appletvsimulator|watchos|watchsimulator)")

# Configuration flags passed to all of our invocations of gyb.  Try to
# avoid making up new variable names here if you can find a CMake
# variable that will do the job.
set(SWIFT_GYB_FLAGS
    "-DunicodeGraphemeBreakPropertyFile=${SWIFT_SOURCE_DIR}/utils/UnicodeData/GraphemeBreakProperty.txt"
    "-DunicodeGraphemeBreakTestFile=${SWIFT_SOURCE_DIR}/utils/UnicodeData/GraphemeBreakTest.txt")

# Directory to use as the Clang module cache when building Swift source files.
set(SWIFT_MODULE_CACHE_PATH
    "${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/module-cache")

# Xcode: use libc++ and c++11 using proper build settings.
if(XCODE)
  swift_common_xcode_cxx_config()
endif()

function(check_working_std_regex result_var_name)
  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    # Apple operating systems use libc++, which has a working std::regex.
    set("${result_var_name}" TRUE PARENT_SCOPE)
  else()
    if(CMAKE_CROSSCOMPILING)
      # Can't run C source when cross-compiling; assume false until we have a static check.
      set("${result_var_name}" FALSE PARENT_SCOPE)
    else()
      # libstdc++ 4.8 has an incomplete std::regex implementation, and crashes
      # on many regexes.
      # libstdc++ 4.9 works.
      set(std_regex_test_source
  "
  #include <regex>
  const std::regex broken_regex{
    \"([a]+)\",
    std::regex::ECMAScript | std::regex::nosubs};

  int main() {}
  ")

      check_cxx_source_runs("${std_regex_test_source}" "${result_var_name}_TEST")
      if ("${${result_var_name}_TEST}")
        set("${result_var_name}" TRUE PARENT_SCOPE)
      else()
        set("${result_var_name}" FALSE PARENT_SCOPE)
      endif()
    endif()
  endif()
endfunction()
check_working_std_regex(SWIFT_HAVE_WORKING_STD_REGEX)

# Returns all deployment target triples whose 'platform' (3rd) component matches
# the given prefix
function(get_platform_deployment_targets platform result_var_name)
  
  string(REGEX MATCHALL "([a-zA-Z0-9]+)-([a-zA-Z0-9]+)-(${platform}[0-9_\.]*)([-a-zA-Z0-9]+)" _matchedVars "${SWIFT_DEPLOYMENT_TARGETS}")
  set("${result_var_name}" "${_matchedVars}" PARENT_SCOPE)
  
endfunction()

function(does_triple_match_platform triple platform result_var_name)
    if( "${triple}" MATCHES "([a-zA-Z0-9]+)-([a-zA-Z0-9]+)-(${platform}[0-9_\.]*)([-a-zA-Z0-9]+)" )
        set("${result_var_name}" 1 PARENT_SCOPE)
    else()
        unset("${result_var_name}" PARENT_SCOPE)
    endif()
endfunction()

# Extracts the system architecture component from a triple
function(get_arch_from_triple triple result_var_name)

  string(REPLACE "-" ";" triple_list "${triple}")
  list(GET triple_list 0 arch)
  set("${result_var_name}" "${arch}" PARENT_SCOPE)

endfunction()

# Parses an SDK name from a triple
function(get_sdk_for_triple triple result_var_name)

    unset("${result_var_name}" PARENT_SCOPE)

    does_triple_match_platform(triple "linux-gnu" is_linux)
    if( is_linux )
      set("${result_var_name" "LINUX" PARENT_SCOPE)
    endif()
    does_triple_match_platform(triple "linux-android" is_android)
    if( is_android )
      set("${result_var_name" "ANDROID" PARENT_SCOPE)
    endif()

    does_triple_match_platform(triple "freebsd" is_freebsd)
    if( is_freebsd )
      set("${result_var_name" "FREEBSD" PARENT_SCOPE)
    endif()
    does_triple_match_platform(triple "windows-cygnu" is_cygwin)
    if( is_cygwin )
      set("${result_var_name" "CYGWIN" PARENT_SCOPE)
    endif()

    does_triple_match_platform(triple "macosx" is_osx)
    if( is_osx )
      set("${result_var_name" "OSX" PARENT_SCOPE)
    endif()
    does_triple_match_platform(triple "ios" is_ios)
    if( is_ios )
      get_arch_from_triple(triple triple_arch)
      if( "${triple_arch}" MATCHES "(i386|x86_64)" )
        set("${result_var_name" "IOS_SIMULATOR" PARENT_SCOPE)
      else()
        set("${result_var_name" "IOS" PARENT_SCOPE)
      endif()
    endif()
    does_triple_match_platform(triple "tvos" is_tvos)
    if( is_tvos )
      get_arch_from_triple(triple triple_arch)
      if( "${triple_arch}" STREQUAL "x86_64" )
        set("${result_var_name" "TVOS_SIMULATOR" PARENT_SCOPE)
      else()
        set("${result_var_name" "TVOS" PARENT_SCOPE)
      endif()
    endif()
    does_triple_match_platform(triple "watchos" is_watchos)
    if( is_watchos )
      get_arch_from_triple(triple triple_arch)
      if( "${triple_arch}" STREQUAL "i386" )
        set("${result_var_name" "WATCHOS_SIMULATOR" PARENT_SCOPE)
      else()
        set("${result_var_name" "WATCHOS" PARENT_SCOPE)
      endif()
    endif()

endfunction()

# Gets the value of the sysroot paramter for a triple
function(get_sysroot_for_triple triple result_var_name)
    
    string(REPLACE "-" "_" triple_arg_part "${triple}")
    string(TOUPPER triple_arg_part triple_arg_part)
    set("${result_var_name}" "${SWIFT_${triple_arg_part}_SYSROOT}" PARENT_SCOPE)

endfunction()

#
# Enable additional warnings.
#
swift_common_cxx_warnings()

#
# Configure SDKs.
#

# SWIFT_HOST_TRIPLE is required.
if(SWIFT_HOST_TRIPLE STREQUAL "")
  message(FATAL_ERROR "SWIFT_HOST_TRIPLE is required")
endif()

get_arch_from_triple(SWIFT_HOST_TRIPLE SWIFT_HOST_VARIANT_ARCH_default)
get_sdk_for_triple(SWIFT_HOST_TRIPLE SWIFT_HOST_VARIANT_SDK_default)

if("${SWIFT_HOST_VARIANT_SDK_default}" STREQUAL "")
  message(FATAL_ERROR "Unable to parse SDK name from host triple: ${SWIFT_HOST_TRIPLE}")
endif()

set(SWIFT_HOST_VARIANT_SDK "${SWIFT_HOST_VARIANT_SDK_default}" CACHE STRING
    "Deployment sdk for Swift host tools (the compiler).")
set(SWIFT_HOST_VARIANT_ARCH "${SWIFT_HOST_VARIANT_ARCH_default}" CACHE STRING
    "Deployment arch for Swift host tools (the compiler).")

if("${SWIFT_HOST_VARIANT_SDK}" STREQUAL "LINUX")
  
  set(CMAKE_EXECUTABLE_FORMAT "ELF")
  set(SWIFT_HOST_VARIANT "linux" CACHE STRING
      "Deployment OS for Swift host tools (the compiler) [linux].")

  # Configure the host
  configure_sdk_unix(LINUX "Linux_${SWIFT_HOST_VARIANT_ARCH}" "linux" "linux" "${SWIFT_HOST_TRIPLE}" "${CMAKE_SYSROOT}")
  set(SWIFT_PRIMARY_VARIANT_SDK_default  "${SWIFT_HOST_VARIANT_SDK}")
  set(SWIFT_PRIMARY_VARIANT_ARCH_default "${SWIFT_HOST_VARIANT_ARCH}")

  # Compatible cross-compile SDKS for LINUX: LINUX (triple: x-x-linux-gnu*), ANDROID (triple: x-x-linux-android*)

  # LINUX
  get_platform_deployment_targets("linux-gnu" linux_deployment_targets)
  foreach(target_triple IN linux_deployment_targets)
    if("${target_triple}" STREQUAL "${SWIFT_HOST_TRIPLE}")
      continue()
    endif()

    # Look for a sysroot variable
    get_sysroot_for_triple(target_triple target_sysroot)
    if("${target_sysroot}" STREQUAL "")
      message(FATAL_ERROR "No sysroot for target: ${triple}")
    endif()
    get_arch_from_triple(target_triple target_arch)
    configure_sdk_unix(LINUX "Linux_${target_arch}" "linux" "linux" "${target_triple}" "${target_sysroot}")
  endforeach()

  # ANDROID
  get_platform_deployment_targets("linux-android" android_deployment_targets)
  foreach(target_triple IN android_deployment_targets)

    # FIXME: Do Android archs other than armv7 work?
    get_arch_from_triple(target_triple target_arch)
    if(NOT "${target_arch}" STREQUAL "armv7")
      message(FATAL_ERROR "armv7 is only supported Android arch. Unsupported target: ${triple}")
    endif()

    # Check that the Android NDK is given
    if("${SWIFT_ANDROID_NDK_PATH}" STREQUAL "")
      message(FATAL_ERROR "Android NDK is required to build for ${target_triple}")
    endif()

    # Look for a sysroot
    get_sysroot_for_triple(target_triple target_sysroot)
    if("${target_sysroot}" STREQUAL "")
      message(FATAL_ERROR "No sysroot for target: ${triple}")
    endif()

    configure_sdk_unix(ANDROID "Android_${target_arch}" "android" "android" "${target_triple}" "${target_triple}")
    # If we're not building for the host, the cross-compiled target should be the 'primary variant'.
    if("${swift_build_linux}" STREQUAL "FALSE")
      set(SWIFT_PRIMARY_VARIANT_SDK_default "ANDROID")
      set(SWIFT_PRIMARY_VARIANT_ARCH_default "${target_arch}")
    endif()

  endforeach()

elseif("${SWIFT_HOST_VARIANT_SDK}" STREQUAL "FREEBSD")
  
  set(CMAKE_EXECUTABLE_FORMAT "ELF")
  set(SWIFT_HOST_VARIANT "freebsd" CACHE STRING
      "Deployment OS for Swift host tools (the compiler) [freebsd].")

  # FIXME: Using the host OS version won't produce correct results for
  # cross-compilation.
  string(REPLACE "[-].*" "" FREEBSD_SYSTEM_VERSION ${CMAKE_SYSTEM_VERSION})
  message(STATUS "FreeBSD Version: ${FREEBSD_SYSTEM_VERSION}")
  configure_sdk_unix(FREEBSD "FreeBSD_x86_64" "freebsd" "freebsd"
    "x86_64-unknown-freebsd${FREEBSD_SYSTEM_VERSION}" "/")
  set(SWIFT_PRIMARY_VARIANT_SDK_default  "${SWIFT_HOST_VARIANT_SDK}")
  set(SWIFT_PRIMARY_VARIANT_ARCH_default "x86_64")
  
elseif("${SWIFT_HOST_VARIANT_SDK}" STREQUAL "CYGWIN")
  
  # set(CMAKE_EXECUTABLE_FORMAT "ELF")
  set(SWIFT_HOST_VARIANT "windows" CACHE STRING
      "Deployment OS for Swift host tools (the compiler) [windows].")
  
  configure_sdk_unix(CYGWIN "Cygwin_x86_64" "windows" "cygwin" "x86_64-unknown-windows-cygnus" "/")
  set(SWIFT_PRIMARY_VARIANT_SDK_default  "${SWIFT_HOST_VARIANT_SDK}")
  set(SWIFT_PRIMARY_VARIANT_ARCH_default "x86_64")

elseif("${SWIFT_HOST_VARIANT_SDK}" MATCHES "(OSX|IOS*|TVOS*|WATCHOS*)")

  set(SWIFT_HOST_VARIANT "macosx" CACHE STRING
      "Deployment OS for Swift host tools (the compiler) [macosx, iphoneos].")

  # Display Xcode toolchain version. 
  # The SDK configuration below prints each SDK version.
  execute_process(
    COMMAND "xcodebuild" "-version"
    OUTPUT_VARIABLE xcode_version
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  string(REPLACE "\n" ", " xcode_version ${xcode_version})
  message(STATUS "${xcode_version}")
  message(STATUS "")

  # OSX is only ever a host. Never cross-compile the stdlib for OSX, even if requested.
  if("${SWIFT_HOST_VARIANT_SDK}" STREQUAL "OSX")
    configure_sdk_darwin(
        "OSX_X86_64" "OS X" "${SWIFT_DARWIN_DEPLOYMENT_VERSION_OSX}"
        macosx macosx macosx "x86_64")
    configure_target_variant(OSX-DA "OS X x86_64 Debug+Asserts"   OSX DA "Debug+Asserts")
    configure_target_variant(OSX-RA "OS X x86_64 Release+Asserts" OSX RA "Release+Asserts")
    configure_target_variant(OSX-R  "OS X x86_64 Release"         OSX R  "Release")
  endif()
  # Primary variant is always OSX; even on iOS hosts.
  set(SWIFT_PRIMARY_VARIANT_SDK_default "OSX")
  set(SWIFT_PRIMARY_VARIANT_ARCH_default "x86_64")


  # Compatible cross-compile SDKS for Darwin OSes: IOS, IOS_SIMULATOR, TVOS,
  #   TVOS_SIMULATOR, WATCHOS, WATCHOS_SIMULATOR (archs hardcoded below).

  if(XCODE)
    # FIXME: Cannot cross-compile stdlib using Xcode.  Xcode insists on
    # passing -mmacosx-version-min to the compiler, and we want to pass
    # -mios-version-min.  Clang sees both options and complains.
    set(swift_can_crosscompile_stdlib FALSE)
  else()
    set(swift_can_crosscompile_stdlib TRUE)
  endif()

  # IOS/IOS_SIMULATOR
  get_platform_deployment_targets("ios" ios_deployment_targets)
  foreach(target_triple IN ios_deployment_targets)
    if(NOT "${SWIFT_HOST_TRIPLE}" STREQUAL "${target_triple}" AND NOT ${swift_can_crosscompile_stdlib})
      message(FATAL_ERROR "Cannot cross-compile the swift stdlib")
    endif()

    # iOS triples with i386/x86_64 architecture assumed to be iOS Simulator
    get_arch_from_triple(target_triple target_arch)
    get_sdk_for_triple(target_triple target_sdk)

    if("${target_sdk}" STREQUAL "IOS_SIMULATOR")
      set(target_prefix "IOS_SIMULATOR")
      set(target_name "iOS Simulator")
      set(target_xcrun_name "iphonesimulator")
      set(target_versionmin_name "ios-simulator")
    else()
      set(target_prefix "IOS")
      set(target_name "iOS")
      set(target_xcrun_name "iphoneos")
      set(target_versionmin_name "ios")
    endif()
    configure_sdk_darwin(
          "${target_prefix}_${target_arch}" "${target_name}" "${SWIFT_DARWIN_DEPLOYMENT_VERSION_IOS}"
          "${target_xcrun_name}" "${target_versionmin_name}" "${target_triple}")
    configure_target_variant(
      "${target_prefix}_${target_arch}-DA" "iOS ${target_arch} Debug+Asserts"   "${target_prefix}_${target_arch}" DA "Debug+Asserts")
    configure_target_variant(
      "${target_prefix}_${target_arch}-RA" "iOS ${target_arch} Release+Asserts" "${target_prefix}_${target_arch}" RA "Release+Asserts")
    configure_target_variant(
      "${target_prefix}_${target_arch}-R"  "iOS ${target_arch} Release"         "${target_prefix}_${target_arch}" R  "Release")
  endforeach()

  # TVOS/TVOS_SIMULATOR
  get_platform_deployment_targets("tvos" tvos_deployment_targets)
  foreach(target_triple IN tvos_deployment_targets)
    if(NOT "${SWIFT_HOST_TRIPLE}" STREQUAL "${target_triple}" AND NOT ${swift_can_crosscompile_stdlib})
      message(FATAL_ERROR "Cannot cross-compile the swift stdlib")
    endif()

    get_arch_from_triple(target_triple target_arch)
    get_sdk_for_triple(target_triple target_sdk)

    if("${target_sdk}" STREQUAL "TVOS_SIMULATOR")
      set(target_prefix "TVOS_SIMULATOR")
      set(target_name "tvOS Simulator")
      set(target_xcrun_name "appletvsimulator")
      set(target_versionmin_name "tvos-simulator")
    else()
      set(target_prefix "TVOS")
      set(target_name "tvOS")
      set(target_xcrun_name "appletvos")
      set(target_versionmin_name "tvos")
    endif()
    configure_sdk_darwin(
          "${target_prefix}_${target_arch}" "${target_name}" "${SWIFT_DARWIN_DEPLOYMENT_VERSION_TVOS}"
          "${target_xcrun_name}" "${target_versionmin_name}" "${target_triple}")
    configure_target_variant(
      "${target_prefix}_${target_arch}-DA" "tvOS ${target_arch} Debug+Asserts"   "${target_prefix}_${target_arch}" DA "Debug+Asserts")
    configure_target_variant(
      "${target_prefix}_${target_arch}-RA" "tvOS ${target_arch} Release+Asserts" "${target_prefix}_${target_arch}" RA "Release+Asserts")
    configure_target_variant(
      "${target_prefix}_${target_arch}-R"  "tvOS ${target_arch} Release"         "${target_prefix}_${target_arch}" R  "Release")
  endforeach()

  # WATCHOS/WATCHOS_SIMULATOR
  get_platform_deployment_targets("watchos" watchos_deployment_targets)
  foreach(target_triple IN watchos_deployment_targets)
    if(NOT "${SWIFT_HOST_TRIPLE}" STREQUAL "${target_triple}" AND NOT ${swift_can_crosscompile_stdlib})
      message(FATAL_ERROR "Cannot cross-compile the swift stdlib")
    endif()

    get_arch_from_triple(target_triple target_arch)
    get_sdk_for_triple(target_triple target_sdk)

    if("${target_sdk}" STREQUAL "WATCHOS_SIMULATOR")
      set(target_prefix "WATCHOS_SIMULATOR")
      set(target_name "watchOS Simulator")
      set(target_xcrun_name "watchsimulator")
      set(target_versionmin_name "watchos-simulator")
    else()
      set(target_prefix "WATCHOS")
      set(target_name "watchOS")
      set(target_xcrun_name "watchos")
      set(target_versionmin_name "watchos")
    endif()
    configure_sdk_darwin(
          "${target_prefix}_${target_arch}" "${target_name}" "${SWIFT_DARWIN_DEPLOYMENT_VERSION_WATCHOS}"
          "${target_xcrun_name}" "${target_versionmin_name}" "${target_triple}")
    configure_target_variant(
      "${target_prefix}_${target_arch}-DA" "tvOS ${target_arch} Debug+Asserts"   "${target_prefix}_${target_arch}" DA "Debug+Asserts")
    configure_target_variant(
      "${target_prefix}_${target_arch}-RA" "tvOS ${target_arch} Release+Asserts" "${target_prefix}_${target_arch}" RA "Release+Asserts")
    configure_target_variant(
      "${target_prefix}_${target_arch}-R"  "tvOS ${target_arch} Release"         "${target_prefix}_${target_arch}" R  "Release")
  endforeach()

  # FIXME: guess target variant based on the host.
  # if(SWIFT_HOST_VARIANT MATCHES "^macosx")
  #   set(SWIFT_PRIMARY_VARIANT_GUESS "OSX-R")
  # elseif(SWIFT_HOST_VARIANT MATCHES "^iphoneos")
  #   set(SWIFT_PRIMARY_VARIANT_GUESS "IOS-R")
  # else()
  #   message(FATAL_ERROR "Unknown SWIFT_HOST_VARIANT '${SWIFT_HOST_VARIANT}'")
  # endif()
  #
  # set(SWIFT_PRIMARY_VARIANT ${SWIFT_PRIMARY_VARIANT_GUESS} CACHE STRING
  #    "[OSX-DA, OSX-RA, OSX-R, IOS-DA, IOS-RA, IOS-R, IOS_SIMULATOR-DA, IOS_SIMULATOR-RA, IOS_SIMULATOR-R]")
  #

endif()

if("${SWIFT_PRIMARY_VARIANT_SDK}" STREQUAL "")
  set(SWIFT_PRIMARY_VARIANT_SDK "${SWIFT_PRIMARY_VARIANT_SDK_default}")
endif()
if("${SWIFT_PRIMARY_VARIANT_ARCH}" STREQUAL "")
  set(SWIFT_PRIMARY_VARIANT_ARCH "${SWIFT_PRIMARY_VARIANT_ARCH_default}")
endif()

if("${SWIFT_CONFIGURED_SDKS}" STREQUAL "")
  message(FATAL_ERROR "No SDKs selected.")
endif()

if("${SWIFT_HOST_VARIANT_SDK}" STREQUAL "")
  message(FATAL_ERROR "No SDK for host tools.")
endif()

if("${SWIFT_HOST_VARIANT_ARCH}" STREQUAL "")
  message(FATAL_ERROR "No arch for host tools.")
endif()

set(SWIFT_PRIMARY_VARIANT_SUFFIX
    "-${SWIFT_SDK_${SWIFT_PRIMARY_VARIANT_SDK}_LIB_SUBDIR}-${SWIFT_PRIMARY_VARIANT_ARCH}")

# Clear universal library names to prevent adding duplicates
foreach(sdk ${SWIFT_SDKS})
  unset(UNIVERSAL_LIBRARY_NAMES_${SWIFT_SDK_${sdk}_LIB_SUBDIR} CACHE)
endforeach()

if(SWIFT_PARALLEL_LINK_JOBS)
  if(CMAKE_VERSION VERSION_LESS 3.0 OR NOT CMAKE_MAKE_PROGRAM MATCHES "ninja")
    message(WARNING "Job pooling is only available with Ninja generators and CMake 3.0 and later.")
  else()
    set_property(GLOBAL APPEND PROPERTY JOB_POOLS swift_link_job_pool=${SWIFT_PARALLEL_LINK_JOBS})
    set(CMAKE_JOB_POOL_LINK swift_link_job_pool)
  endif()
endif()

# Set the CMAKE_OSX_* variables in a way that minimizes conflicts.
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
  set(CMAKE_OSX_SYSROOT "${SWIFT_SDK_${SWIFT_HOST_VARIANT_SDK}_PATH}")
  set(CMAKE_OSX_ARCHITECTURES "")
  set(CMAKE_OSX_DEPLOYMENT_TARGET "")
endif()

message(STATUS "Building host Swift tools for ${SWIFT_HOST_VARIANT_SDK} ${SWIFT_HOST_VARIANT_ARCH}")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Assertions: ${LLVM_ENABLE_ASSERTIONS}")
message(STATUS "  LTO:        ${SWIFT_ENABLE_LTO}")
message(STATUS "")

message(STATUS "Building Swift standard library and SDK overlays for SDKs: ${SWIFT_SDKS}")
message(STATUS "  Build type: ${SWIFT_STDLIB_BUILD_TYPE}")
message(STATUS "  Assertions: ${SWIFT_STDLIB_ASSERTIONS}")
message(STATUS "")

message(STATUS "Building Swift runtime with:")
message(STATUS "  Leak Detection Checker Entrypoints: ${SWIFT_RUNTIME_ENABLE_LEAK_CHECKER}")
message(STATUS "")

#
# Find optional dependencies.
#

# Find libxml.
# FIXME: unify with CLANG_HAVE_LIBXML, which is set in LLVM anyway.
find_package(LibXml2)
if(LIBXML2_FOUND)
  set(SWIFT_HAVE_LIBXML 1)
endif()

if (LLVM_ENABLE_DOXYGEN)
  message(STATUS "Doxygen: enabled")
endif()

#
# Set up global CMake variables for API notes.
#
# API notes version 1.0.0
#
# Change the above comment to 'touch' this file and keep incremental builds
# working when adding a new apinotes file.
#
set(SWIFT_API_NOTES_PATH "${SWIFT_SOURCE_DIR}/apinotes")
if(NOT EXISTS "${SWIFT_API_NOTES_PATH}/Foundation.apinotes")
  message(FATAL_ERROR "API notes are not available in ${SWIFT_API_NOTES_PATH}")
endif()

file(GLOB SWIFT_API_NOTES_INPUT_FILES "${SWIFT_API_NOTES_PATH}/*.apinotes")
foreach(file ${SWIFT_API_NOTES_INPUT_FILES})
  get_filename_component(name "${file}" NAME_WE)
  list(APPEND SWIFT_API_NOTES_INPUTS ${name})
endforeach()

# Add all of the subdirectories, where we actually do work.
if(SWIFT_BUILD_TOOLS)
  add_subdirectory(include)
  add_subdirectory(lib)
  add_subdirectory(tools)
endif()

is_sdk_requested("${SWIFT_HOST_VARIANT_SDK}" SWIFT_HOST_SDK_REQUESTED)
if(SWIFT_BUILD_TOOLS AND SWIFT_BUILD_STDLIB AND SWIFT_HOST_SDK_REQUESTED)
  add_subdirectory(tools/swift-reflection-dump)
endif()

add_subdirectory(utils)
add_subdirectory(stdlib)

if(SWIFT_BUILD_STDLIB AND SWIFT_INCLUDE_TESTS)
  add_subdirectory(tools/swift-reflection-test)
endif()

if(SWIFT_BUILD_PERF_TESTSUITE AND "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
  add_subdirectory(benchmark)
endif()
if(SWIFT_INCLUDE_TESTS)
  add_subdirectory(test)
  add_subdirectory(unittests)
endif()
if(SWIFT_INCLUDE_DOCS)
  add_subdirectory(docs)
endif()

swift_install_in_component(license
  FILES "LICENSE.txt"
  DESTINATION "share/swift")

# Add a documentation target so that documentation shows up in the
# Xcode project.
if(XCODE)
  add_custom_target(Documentation
      SOURCES
        README.md
        docs)

  file(GLOB SWIFT_TOPLEVEL_HEADERS
      ${CMAKE_CURRENT_SOURCE_DIR}/include/swift${dir}/*.h
      ${CMAKE_CURRENT_SOURCE_DIR}/include/swift${dir}/*.td
      ${CMAKE_CURRENT_SOURCE_DIR}/include/swift${dir}/*.def)
  add_custom_target(Miscellaneous
      SOURCES ${SWIFT_TOPLEVEL_HEADERS})
endif()
