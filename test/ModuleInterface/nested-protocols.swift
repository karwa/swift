// RUN: %empty-directory(%t)
// RUN: %target-swift-emit-module-interface(%t/NestedProtocols.swiftinterface) %s -module-name NestedProtocols -enable-experimental-feature NestedProtocols
// RUN: %FileCheck %s < %t/NestedProtocols.swiftinterface

public struct Outer {
  // CHECK: #if compiler(>=5.3) && $NestedProtocols
  // CHECK-NEXT: protocol Nested {
  public protocol Nested {
    // CHECK-NEXT: func someRequirement()
    func someRequirement()
  // CHECK-NEXT: }
  }
  // CHECK-NEXT: #endif
}
