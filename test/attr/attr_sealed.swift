// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -swift-version 5 %S/Inputs/attr_sealed_helpers.swift -o %t -module-name Helpers
// RUN: %target-typecheck-verify-swift -swift-version 5 -I %t

import Helpers

// Only allowed on protocols.
sealed class SealedClass {} // expected-error {{'sealed' may only be used on 'protocol' declarations}}
sealed struct SealedStruct {} // expected-error {{'sealed' may only be used on 'protocol' declarations}}
sealed enum SealedEnum {} // expected-error {{'sealed' may only be used on 'protocol' declarations}}

// Extensions are allowed.
extension SealedExternalProtocol {
    func myHelperFunction() {}
}

// Cannot introduce new conformances outside of the declaring module.
struct MyType_0 {}
extension MyType_0: Helpers.SealedExternalProtocol {} // expected-error{{cannot conform to 'sealed' protocol 'SealedExternalProtocol'}}
extension Helpers.DoesNotConformToSealedExternal_0: Helpers.SealedExternalProtocol {} // expected-error {{cannot conform to 'sealed' protocol 'SealedExternalProtocol'}}

// Refinements may be less sealed than parents, as long as above is respected.
extension Helpers.ConformsToSealedExternal: Helpers.OpenExternalRefinement {}
extension Helpers.DoesNotConformToSealedExternal_1: Helpers.OpenExternalRefinement {} // expected-error {{type 'DoesNotConformToSealedExternal_1' cannot conform to protocol 'OpenExternalRefinement'. Only types which conform to 'sealed' protocol 'SealedExternalProtocol' are eligible}}


// Cross-module refinements are allowed.
protocol RefinementOfSealedExternalProtocol: Helpers.SealedExternalProtocol {}
protocol AnotherRefinement: RefinementOfSealedExternalProtocol {}
extension Helpers.ConformsToSealedExternal: AnotherRefinement {}
struct MyType_1 {}
extension MyType_1: AnotherRefinement {} // expected-error {{type 'MyType_1' cannot conform to protocol 'AnotherRefinement'. Only types which conform to 'sealed' protocol 'SealedExternalProtocol' are eligible}}
