import Foundation

enum DeveloperUtility: String, CaseIterable, Identifiable {

    case json
    case base64
    case url
    case hash
    case uuid
    case timestamp
    case regex
    case jwt
    case hex
    case diff

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .json:
            return "JSON Formatter"
        case .base64:
            return "Base64"
        case .url:
            return "URL Encoder"
        case .hash:
            return "Hash Generator"
        case .uuid:
            return "UUID Generator"
        case .timestamp:
            return "Timestamp Converter"
        case .regex:
            return "Regex Tester"
        case .jwt:
            return "JWT Decoder"
        case .hex:
            return "Hex Converter"
        case .diff:
            return "Text Diff"
        }
    }

    var icon: String {
        switch self {
        case .json:
            return "curlybraces"
        case .base64:
            return "textformat.abc"
        case .url:
            return "link"
        case .hash:
            return "number"
        case .uuid:
            return "number.circle"
        case .timestamp:
            return "clock"
        case .regex:
            return "asterisk"
        case .jwt:
            return "key"
        case .hex:
            return "number.square"
        case .diff:
            return "arrow.left.arrow.right"
        }
    }

    var description: String {
        switch self {
        case .json:
            return "Format, minify and validate JSON."
        case .base64:
            return "Encode and decode Base64 strings."
        case .url:
            return "Encode and decode URL components."
        case .hash:
            return "Generate cryptographic hashes."
        case .uuid:
            return "Generate unique identifiers."
        case .timestamp:
            return "Convert timestamps and dates."
        case .regex:
            return "Test regular expressions and capture groups."
        case .jwt:
            return "Inspect JWT headers and payloads."
        case .hex:
            return "Convert hexadecimal and UTF-8 text."
        case .diff:
            return "Compare two text documents."
        }
    }
}
