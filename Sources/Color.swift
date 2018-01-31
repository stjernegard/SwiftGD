import Foundation

// TODO: "Unify" color, or make it more protocol based
// TODO: Support none alpha color

public struct Color {

    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - red: <#red description#>
    ///   - green: <#green description#>
    ///   - blue: <#blue description#>
    ///   - alpha: <#alpha description#>
    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

// MARK: Constants

extension Color {

    public static let red = Color(red: 1, green: 0, blue: 0, alpha: 1)

    public static let green = Color(red: 0, green: 1, blue: 0, alpha: 1)

    public static let blue = Color(red: 0, green: 0, blue: 1, alpha: 1)

    public static let black = Color(red: 0, green: 0, blue: 0, alpha: 1)

    public static let white = Color(red: 1, green: 1, blue: 1, alpha: 1)
}

// MARK: LibGD

extension Color {

    internal var gdRed: Int32 {
        return Int32(red * 255)
    }
    internal var gdGreen: Int32 {
        return Int32(green * 255)
    }
    internal var gdBlue: Int32 {
        return Int32(blue * 255)
    }
    internal var gdAlpha: Int32 {
        // gd uses an inverted (0=opaque, 1=transparent) 7-bit alpha
        // channel (2^7=128), as opposed by the 8-bit r/g/b channels.
        // https://github.com/libgd/libgd/issues/132
        return 127 - Int32(alpha * 127)
    }

    /// <#Description#>
    ///
    /// - Parameter libgd: <#libgd description#>
    internal init(libgd color: Int32) {
        self.init(
            red: Double((color >> 16) & 0xff) / 255,
            green: Double((color >> 8) & 0xff) / 255,
            blue: Double((color >> 0) & 0xff) / 255,
            // gd uses an inverted (0=opaque, 1=transparent) 7-bit alpha
            // channel (2^7=128), as opposed by the 8-bit r/g/b channels.
            // // https://github.com/libgd/libgd/issues/132
            alpha: 1 - (Double((color >> 24) & 0xff) / 127)
        )
    }
}

// MARK: Hexadecimal

extension Color {

    /// Initializes a new `Color` instance of given hexadecimal color string.
    ///
    /// Given string will be stripped from a single leading "#", if applicable.
    /// Resulting string must met any of the following criteria:
    ///
    /// - Is a string with 8-characters and therefore a fully fledged hexadecimal
    ///   color representation **including** an alpha component. Given value will remain
    ///   untouched before conversion. Example: `ffeebbaa`
    /// - Is a string with 6-characters and therefore a fully fledged hexadecimal color
    ///   representation **excluding** an alpha component. Given RGB color components will
    ///   remain untouched and an alpha component of `0xff` (opaque) will be extended before
    ///   conversion. Example: `ffeebb` -> `ffeebbff`
    /// - Is a string with 4-characters and therefore a shortened hexadecimal color
    ///   representation **including** an alpha component. Each single character will be
    ///   doubled before conversion. Example: `feba` -> `ffeebbaa`
    /// - Is a string with 3-characters and therefore a shortened hexadecimal color
    ///   representation **excluding** an alpha component. Given RGB color character will
    ///   be doubled and an alpha of component of `0xff` (opaque) will be extended before
    ///   conversion. Example: `feb` -> `ffeebbff`
    ///
    /// - Parameters:
    ///   - string: The hexadecimal color string.
    ///   - leadingAlpha: Indicate whether given string should be treated as ARGB (`true`) or RGBA (`false`)
    /// - Throws: `.invalidColor` if given string does not match any of the above mentioned criteria or is not a valid hex color.
    public init(hex string: String, leadingAlpha: Bool = false) throws {
        let string = try Color.sanitize(hex: string, leadingAlpha: leadingAlpha)
        guard let code = Int(string, radix: 16) else {
            throw Error.invalidColor(reason: "0x\(string) is not a valid hex color code")
        }
        self.init(hex: code, leadingAlpha: leadingAlpha)
    }

    /// Initializes a new `Color` instance of given hexadecimal color values.
    ///
    /// - Parameters:
    ///   - color: The hexadecimal color value, incl. red, green, blue and alpha
    ///   - space: The color space of given `color`
    ///   - leadingAlpha: Indicates whether given code should be treated as ARGB (`true`) or RGBA (`false`)
    public init(hex color: Int, leadingAlpha: Bool = false) {

        let first = Double((color >> 24) & 0xff) / 255
        let second = Double((color >> 16) & 0xff) / 255
        let third = Double((color >>  8) & 0xff) / 255
        let fourth = Double((color >>  0) & 0xff) / 255

        if leadingAlpha {
            self.init(red: second, green: third, blue: fourth, alpha: first) // ARGB
        } else {
            self.init(red: first, green: second, blue: third, alpha: fourth) // RGBA
        }
    }

    // MARK: Private helper

    /// Sanitizes given hexadecimal color string (strips # and forms proper length).
    ///
    /// - Parameters:
    ///   - string: The hexadecimal color string to sanitize
    ///   - leadingAlpha: Indicate whether given and returning string should be treated as ARGB (`true`) or RGBA (`false`)
    /// - Returns: The sanitized hexadecimal color string
    /// - Throws: `.invalidColor` if given string is not of proper length
    private static func sanitize(hex string: String, leadingAlpha: Bool) throws -> String {

        // Drop leading "#" if applicable
        var string = string.hasPrefix("#") ? String(string.dropFirst(1)) : string

        // Evaluate if short code w/wo alpha (e.g. `feb` or `feb4`). Double up the characters if so.
        if string.count == 3 || string.count == 4 {
            string = string.map({ "\($0)\($0)" }).joined()
        }

        // Evaluate if fully fledged code w/wo alpha (e.g. `ffaabb` or `ffaabb44`), otherwise throw error
        switch string.count {
        case 6: // Hex color code without alpha (e.g. ffeeaa)
            let alpha = String(0xff, radix: 16) // 0xff (opaque)
            return leadingAlpha ? alpha + string : string + alpha
        case 8: // Fully fledged hex color including alpha (e.g. eebbaa44)
            return string
        default:
            throw Error.invalidColor(reason: "0x\(string) has invalid hex color string length")
        }
    }
}
