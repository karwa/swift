add_swift_library(swiftSwiftReflectionTest SHARED IS_STDLIB
  SwiftReflectionTest.swift
  SWIFT_MODULE_DEPENDS Darwin
  INSTALL_IN_COMPONENT stdlib-experimental)

foreach(deployment_target ${SWIFT_CONFIGURED_SDKS})
	set(ARCH "${SWIFT_SDK_${deployment_target}_ARCHITECTURE}")
    set(VARIANT_SUFFIX "-${SWIFT_SDK_${deployment_target}_LIB_SUBDIR}-${ARCH}")
    add_dependencies(
      "swiftSwiftReflectionTest${VARIANT_SUFFIX}"
      "swift-reflection-test${VARIANT_SUFFIX}")
endforeach()
