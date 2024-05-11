//===--- StringNormalization.swift ----------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension Unicode {

  /// A representation of a Unicode string
  /// which preserves canonical equivalence.
  ///
  /// Unicode Normalization Forms are formally defined normalizations
  /// of Unicode strings which make it possible to determine
  /// whether any two Unicode strings are equivalent to each other.
  /// If two strings are equivalent, they will contain exactly the same
  /// sequence of Unicode scalars when normalized to the same form.
  ///
  /// Canonical normalization preserves abstract meaning,
  /// and applications can normalize to one of these forms
  /// or convert between them without fear of altering
  /// the interpretation of the source text.
  ///
  /// Some characters are equivalent to sequences of characters
  /// and combining marks. The two forms of canonical normalization
  /// allow one to choose whether the result contains the composed (NFC)
  /// or decomposed (NFD) representations of these characters.
  ///
  @available(SwiftStdlib 9999, *)
  @frozen
  public enum CanonicalNormalizationForm {

    /// Normalization Form D.
    ///
    case nfd

    /// Normalization Form C.
    ///
    case nfc
  }
}

@available(SwiftStdlib 9999, *)
extension Unicode.CanonicalNormalizationForm {

  /// The normalization form preferred by the Swift Standard Library.
  ///
  /// Normalizing a String to this form may allow for more efficient comparison,
  /// hashing, or other operations.
  ///
  @inlinable
  public static var preferredForm: Self {
    .nfc
  }
}

extension StringProtocol {

  /// Returns a copy of this string in the given normal form.
  /// The result is canonically equivalent to this string.
  ///
  /// If two strings are normalized to the same form,
  /// and they are equivalent, they will contain
  /// the same Unicode scalars.
  ///
  /// ```swift
  /// let a = "cafe\u{0301}"
  /// let b = "caf\u{00E9}"
  ///
  /// a.unicodeScalars
  /// b.unicodeScalars
  /// // ["c", "a", "f", "e", "\u{0301}"]
  /// // ["c", "a", "f", "\u{00E9}"]
  ///
  /// a.normalized(.nfc).unicodeScalars
  /// b.normalized(.nfc).unicodeScalars
  /// // ["c", "a", "f", "\u{00E9}"]
  /// // ["c", "a", "f", "\u{00E9}"]
  ///
  /// a.normalized(.nfd).unicodeScalars
  /// b.normalized(.nfd).unicodeScalars
  /// // ["c", "a", "f", "e", "\u{0301}"]
  /// // ["c", "a", "f", "e", "\u{0301}"]
  /// ```
  ///
  /// Note that String's built-in equality and comparison operators
  /// already test canonical equivalence and do not require strings
  /// to be manually normalized.
  ///
  /// If persisting normalized strings, be aware that a string
  /// containing characters unassigned in the standard library's
  /// version of Unicode has an unstable normalization.
  /// The `stabilized()` function should be used
  /// if a stable normalization is required.
  ///
  /// - parameters:
  ///   - form: The canonical normalization form.
  ///
  @_specialize(where Self == String)
  @_specialize(where Self == Substring)
  @available(SwiftStdlib 9999, *)
  public func normalized(
    _ form: Unicode.CanonicalNormalizationForm
  ) -> String {

    switch form {
    case .nfd:
      if _wholeGuts.isASCII {
        return String(self)
      }
      return String(unicodeScalars.normalized.nfd)

    case .nfc:
      // FIXME: There should be a test that String.init definitely keeps the isNFC bit here.
      if _wholeGuts.isNFC {
        return String(self)
      }

      // UAX#15 (Unicode 15.1.0), Section 9:
      //
      // > There is also a Unicode Consortium stability policy
      // > that canonical mappings are always limited
      // > in all versions of Unicode, so that no string
      // > when decomposed with NFC expands to more than 3x in length
      // > (measured in code units).
      // > This is true whether the text is in UTF-8, UTF-16, or UTF-32
      //
      // This is not true of NFD.

      return _withUnprotectedUnsafeTemporaryAllocation(
        of: UInt8.self, capacity: _gutsSlice.utf8Count * 3
      ) { buffer in
        var i = 0
        for scalar in self.unicodeScalars.normalized.nfc {
          scalar.withUTF8CodeUnits {
            _precondition(
              i < buffer.endIndex, "We should not run out of capacity"
            )
            let remaining = buffer[Range(uncheckedBounds: (i, buffer.endIndex))]
            i = buffer.initialize(fromContentsOf: $0)
          }
        }

        let encodedContents = UnsafeBufferPointer(
          rebasing: buffer[Range(uncheckedBounds: (buffer.startIndex, i))]
        )
        var string = String._uncheckedFromUTF8(encodedContents)
        string._guts.markIsNFC()
        return string
      }
    }
  }

  /// Returns a copy of this string in the given normal form,
  /// if the normalization is stable.
  ///
  /// The result, if not `nil`, is a stabilized string
  /// that is canonically equivalent to this string.
  ///
  /// If two strings are normalized to the same form,
  /// and they are equivalent, they will contain
  /// the same Unicode scalars.
  ///
  /// ```swift
  /// let a = "cafe\u{0301}"
  /// let b = "caf\u{00E9}"
  ///
  /// a.unicodeScalars
  /// b.unicodeScalars
  /// // ["c", "a", "f", "e", "\u{0301}"]
  /// // ["c", "a", "f", "\u{00E9}"]
  ///
  /// a.normalized(.nfc).unicodeScalars
  /// b.normalized(.nfc).unicodeScalars
  /// // ["c", "a", "f", "\u{00E9}"]
  /// // ["c", "a", "f", "\u{00E9}"]
  ///
  /// a.normalized(.nfd).unicodeScalars
  /// b.normalized(.nfd).unicodeScalars
  /// // ["c", "a", "f", "e", "\u{0301}"]
  /// // ["c", "a", "f", "e", "\u{0301}"]
  /// ```
  ///
  /// If a string does not contain any unassigned characters
  /// and is normalized, it is said to be a 'Stabilized String'
  /// and will never change if renormalized for that same form
  /// in any past or future version of Unicode.
  ///
  /// This can be important if a normalized string is to be persisted.
  /// For instance, if keys in a database are normalized strings,
  /// the additional guarantee of stability ensures all versions
  /// of Unicode will agree that each key is distinct.
  ///
  /// - parameters:
  ///   - form: The canonical normalization form.
  ///
  @_specialize(where Self == String)
  @_specialize(where Self == Substring)
  @available(SwiftStdlib 9999, *)
  public func stabilized(
    _ form: Unicode.CanonicalNormalizationForm
  ) -> String? {

    guard !unicodeScalars.contains(where: \.isUnassigned) else {
      return nil
    }
    return normalized(form)
  }
}

extension Unicode.Scalar {
  // Normalization boundary - a place in a string where everything left of the
  // boundary can be normalized independently from everything right of the
  // boundary. The concatenation of each result is the same as if the entire
  // string had been normalized as a whole.
  //
  // Normalization segment - a sequence of code units between two normalization
  // boundaries (without any boundaries in the middle). Note that normalization
  // segments can, as a process of normalization, expand, contract, and even
  // produce new sub-segments.

  // Quick check if a scalar is an NFC segment starter.
  internal var _isNFCStarter: Bool {
    // Fast path: All scalars up to U+300 are NFC_QC and have boundaries
    // before them.
    let normData = Unicode._NormData(self, fastUpperbound: 0x300)
    return normData.ccc == 0 && normData.isNFCQC
  }
}

extension UnsafeBufferPointer where Element == UInt8 {
  internal func hasNormalizationBoundary(before offset: Int) -> Bool {
    if offset == 0 || offset == count {
      return true
    }
    _internalInvariant(!UTF8.isContinuation(self[_unchecked: offset]))

    // Sub-300 latiny fast-path
    if self[_unchecked: offset] < 0xCC { return true }

    let cu = _decodeScalar(self, startingAt: offset).0
    return cu._isNFCStarter
  }

  internal func isOnUnicodeScalarBoundary(_ offset: Int) -> Bool {
    guard offset < count else {
      _internalInvariant(offset == count)
      return true
    }
    return !UTF8.isContinuation(self[offset])
  }
}
