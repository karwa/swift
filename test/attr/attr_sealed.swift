// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -swift-version 5 %S/Inputs/attr_sealed_helpers.swift -o %t -module-name Helpers
// RUN: %target-typecheck-verify-swift -swift-version 5 -I %t

import Helpers

struct MyType {}

extension MyType: SealedExternalProtocol {} // expected-error{{cannot conform to 'sealed' protocol}}
protocol RefinementOfSealedExternalProtocol: SealedExternalProtocol {} // expected-error{{cannot inherit from 'sealed' protocol}}
sealed protocol SealedRefinementOfSealedExternalProtocol: SealedExternalProtocol {} // expected-error{{cannot inherit from 'sealed' protocol}}

public protocol OpenRootProtocol {}
sealed public protocol SealedRefinement: OpenRootProtocol {}
internal protocol NonPublicRefinement: SealedRefinement {}
public protocol PublicOpenRefinement: SealedRefinement {} // expected-error{{public refinements of 'sealed' protocols must also be declared 'sealed'}}
sealed public protocol PublicSealedRefinement: SealedRefinement {}

public protocol AnotherOpenRootProtocol {}
public protocol PublicOpenRefinement2: AnotherOpenRootProtocol, SealedRefinement {} // expected-error{{public refinements of 'sealed' protocols must also be declared 'sealed'}}

sealed class SealedClass {} // expected-error {{'sealed' may only be used on 'protocol' declarations}}
sealed struct SealedStruct {} // expected-error {{'sealed' may only be used on 'protocol' declarations}}
sealed enum SealedEnum {} // expected-error {{'sealed' may only be used on 'protocol' declarations}}