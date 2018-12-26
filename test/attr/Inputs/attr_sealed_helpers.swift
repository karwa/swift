sealed public protocol SealedExternalProtocol {}
public protocol OpenExternalRefinement: SealedExternalProtocol {}

public struct ConformsToSealedExternal: SealedExternalProtocol {}
public struct DoesNotConformToSealedExternal_0 {}
public struct DoesNotConformToSealedExternal_1 {}
