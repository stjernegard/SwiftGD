import Foundation

extension Data {

    /// Returns a reference of the raw pointer to the data array and the array size
    internal func memory() throws -> (pointer: UnsafeMutableRawPointer, size: Int32) {
        guard count < Int32.max else { // Bytes must not exceed int32 as limit by `gdImageCreate..Ptr()`
            throw Error.invalidImage(reason: "Given image data exceeds maximum allowed bytes (must be in int32 range)")
        }
        return (pointer: withUnsafeBytes({ UnsafeMutableRawPointer(mutating: $0) }), size: Int32(count))
    }
}

extension Collection {

    /// Returns the result of the first element of the sequence that evaluates the given predicate positively (not nil).
    ///
    /// - Parameter predicate:
    ///             A closure that takes an element of the sequence and returns an optional `Result`
    ///             indicating whether the element is a match.
    /// - Returns: Returns the first element of the sequence that satisfies the given predicate.
    /// - Throws: Rethrows errors occuring within any of the predicate evaluations.
    internal func first<Result>(where predicate: (Element) throws -> Result?) rethrows -> Result? {
        for element in self {
            if let result = try predicate(element) {
                return result
            }
        }
        return nil
    }
}
