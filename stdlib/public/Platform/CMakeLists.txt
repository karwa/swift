set(swift_platform_name)
set(swift_platform_flags)
set(swift_platform_sources
    Platform.swift
    Misc.c
    tgmath.swift.gyb)

if(SWIFT_HOST_VARIANT MATCHES "${SWIFT_DARWIN_VARIANTS}")
  set(swift_platform_name swiftDarwin)
  set(swift_platform_sources
      Darwin.swift
      ${swift_platform_sources}
      POSIXError.swift
      MachError.swift)
  set(swift_platform_flags
      SWIFT_COMPILE_FLAGS -Xfrontend -disable-objc-attr-requires-foundation-module
      API_NOTES_NON_OVERLAY)
else()
  set(swift_platform_name swiftGlibc)
  set(swift_platform_sources
      Glibc.swift
      ${swift_platform_sources})
  set(swift_platform_flags
      DEPENDS glibc_modulemap)
endif()

add_swift_library(${swift_platform_name} IS_SDK_OVERLAY
    ${swift_platform_sources}
    ${swift_platform_flags})

set(glibc_modulemap_target_list)
foreach(target ${SWIFT_CONFIGURED_SDKS})
  set(sdk_id "${SWIFT_SDK_${target}_SDK_ID}")
  if("${sdk_id}" STREQUAL "LINUX" OR
     "${sdk_id}" STREQUAL "FREEBSD" OR
     "${sdk_id}" STREQUAL "ANDROID" OR
     "${sdk_id}" STREQUAL "CYGWIN")

    set(arch_subdir "${SWIFT_SDK_${target}_LIB_SUBDIR}/${arch}")
    set(module_dir "${SWIFTLIB_DIR}/${arch_subdir}")
    
    # Determine the location of glibc headers based on the target.
    set(GLIBC_SYSROOT_RELATIVE_INCLUDE_PATH "/usr/include")
    set(GLIBC_SYSROOT_RELATIVE_ARCH_INCLUDE_PATH ${GLIBC_SYSROOT_RELATIVE_INCLUDE_PATH})
    
    # Some SDKs place their headers in architecture-specific subfolders.
    if((${sdk_id} STREQUAL "LINUX" OR ${sdk_id} STREQUAL "FREEBSD") AND CMAKE_LIBRARY_ARCHITECTURE)
      set(GLIBC_SYSROOT_RELATIVE_ARCH_INCLUDE_PATH "${GLIBC_SYSROOT_RELATIVE_ARCH_INCLUDE_PATH}/${CMAKE_LIBRARY_ARCHITECTURE}")
    endif()

    set(GLIBC_INCLUDE_PATH "${SWIFT_SDK_${target}_PATH}/${GLIBC_SYSROOT_RELATIVE_INCLUDE_PATH}")
    set(GLIBC_ARCH_INCLUDE_PATH "${SWIFT_SDK_${target}_PATH}/${GLIBC_SYSROOT_RELATIVE_ARCH_INCLUDE_PATH}")

    set(glibc_modulemap_source "glibc.modulemap.gyb")
    set(glibc_modulemap_out "${module_dir}/glibc.modulemap")

    # Configure the module map based on the target. Each platform needs to
    # reference different headers, based on what's available in their glibc.
    # This is the 'glibc.modulemap' in the 'resource-dir', so 
    # it's the one we'll look at during the build process.
    handle_gyb_source_single(glibc_modulemap_target
        SOURCE "${glibc_modulemap_source}"
        OUTPUT "${glibc_modulemap_out}"
        FLAGS
            "-DCMAKE_SDK=${sdk_id}"
            "-DGLIBC_INCLUDE_PATH=${GLIBC_INCLUDE_PATH}"
            "-DGLIBC_ARCH_INCLUDE_PATH=${GLIBC_ARCH_INCLUDE_PATH}")

    list(APPEND glibc_modulemap_target_list ${glibc_modulemap_target})

    # If this SDK is a target for a non-native host, create a native modulemap 
    # without a sysroot prefix. This is the one we'll install instead.
    if(NOT "${SWIFT_SDK_${SWIFT_HOST}_PATH}" STREQUAL "/")

      set(glibc_sysroot_relative_modulemap_out "${module_dir}/sysroot-relative-modulemaps/glibc.modulemap")
      handle_gyb_source_single(glibc_modulemap_native_target
          SOURCE "${glibc_modulemap_source}"
          OUTPUT "${glibc_sysroot_relative_modulemap_out}"
          FLAGS
              "-DCMAKE_SDK=${sdk_id}"
              "-DGLIBC_INCLUDE_PATH=${GLIBC_SYSROOT_RELATIVE_INCLUDE_PATH}"
              "-DGLIBC_ARCH_INCLUDE_PATH=${GLIBC_SYSROOT_RELATIVE_ARCH_INCLUDE_PATH}")

      list(APPEND glibc_modulemap_target_list ${glibc_modulemap_native_target})
      set(glibc_modulemap_out ${glibc_sysroot_relative_modulemap_out})
    endif()

    # FIXME: When SDK is a cross-compile target (SDK != Host), the generated
    #        modulemap will be relative to the Host, with hardcoded paths.
    #        It is not relocatable to the target platform itself.
    #        This only affects ANDROID right now, but could affect cross-compiled LINUX targets
      
    swift_install_in_component(sdk-overlay
        FILES "${glibc_modulemap_out}"
        DESTINATION "lib/swift/${arch_subdir}")

  endif()
endforeach()
add_custom_target(glibc_modulemap DEPENDS ${glibc_modulemap_target_list})
