#if os(Linux)
    import Glibc
    import Cgdlinux
#else
    import Darwin
    import Cgdmac
#endif

import Foundation

/// Defines a type that can encode any `gdImage` into a native format for external representation.
internal protocol Encoder {

    /// The native format for external representation
    associatedtype Encodable

    /// Creates an `Encodable` instance from given `gdImagePtr`.
    ///
    /// - Parameter image: The `gdImagePtr` to encode
    /// - Returns: The native format for external representation
    /// - Throws: `Error` if encoding failed
    func encode(image: gdImagePtr) throws -> Encodable
}

/// Defines a type that can decode any `Decodable` from a native format (e.g. file, data, ...) into `gdImage` representations.
internal protocol Decoder {

    /// The object necessary to decode an image
    associatedtype Decodable

    /// Creates a `gdImagePtr` from given `Decodable`.
    ///
    /// - Parameter decodable: The object necessary to decode an image
    /// - Returns: The `gdImagePtr` of the instantiated image
    /// - Throws: `Error` if decoding failed
    func decode(decodable: Decodable) throws -> gdImagePtr
}

/// Defines a type that can be used for both, encoding & decoding.
internal typealias Coder = Encoder & Decoder
