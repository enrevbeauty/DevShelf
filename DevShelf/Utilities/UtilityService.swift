import Foundation
import CryptoKit

enum UtilityError: LocalizedError {

    case invalidBase64
    case invalidUTF8
    case invalidURL
    case invalidHex
    case invalidJWT
    case invalidTimestamp
    case inputTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidBase64:
            return "Invalid Base64 input."
        case .invalidUTF8:
            return "The decoded data is not valid UTF-8."
        case .invalidURL:
            return "Invalid percent-encoded input."
        case .invalidHex:
            return "Invalid hexadecimal input."
        case .invalidJWT:
            return "Invalid JWT structure."
        case .invalidTimestamp:
            return "Invalid timestamp or date."
        case .inputTooLarge:
            return "The input is too large."
        }
    }
}

enum HashAlgorithm: String, CaseIterable, Identifiable {

    case md5 = "MD5"
    case sha1 = "SHA-1"
    case sha256 = "SHA-256"
    case sha384 = "SHA-384"
    case sha512 = "SHA-512"

    var id: String {
        rawValue
    }
}

enum UtilityService {

    // MARK: - JSON

    static func formatJSON(
        _ input: String,
        pretty: Bool = true,
        sortedKeys: Bool = false
    ) throws -> String {

        let data = Data(input.utf8)

        let object = try JSONSerialization.jsonObject(
            with: data,
            options: [.fragmentsAllowed]
        )

        var options: JSONSerialization.WritingOptions = [
            .fragmentsAllowed,
            .withoutEscapingSlashes
        ]

        if pretty {
            options.insert(.prettyPrinted)
        }

        if sortedKeys {
            options.insert(.sortedKeys)
        }

        let result = try JSONSerialization.data(
            withJSONObject: object,
            options: options
        )

        guard let output = String(
            data: result,
            encoding: .utf8
        ) else {
            throw UtilityError.invalidUTF8
        }

        return output
    }

    // MARK: - Base64

    static func encodeBase64(
        _ input: String
    ) -> String {
        Data(input.utf8).base64EncodedString()
    }

    static func decodeBase64(
        _ input: String
    ) throws -> String {

        let cleaned = input.filter {
            !$0.isWhitespace
        }

        guard let data = Data(
            base64Encoded: cleaned
        ) else {
            throw UtilityError.invalidBase64
        }

        guard let result = String(
            data: data,
            encoding: .utf8
        ) else {
            throw UtilityError.invalidUTF8
        }

        return result
    }

    // MARK: - URL

    static func encodeURL(
        _ input: String
    ) -> String {

        let allowed = CharacterSet(
            charactersIn:
                "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
                "abcdefghijklmnopqrstuvwxyz" +
                "0123456789-._~"
        )

        return input.addingPercentEncoding(
            withAllowedCharacters: allowed
        ) ?? input
    }

    static func decodeURL(
        _ input: String
    ) throws -> String {

        guard let result =
            input.removingPercentEncoding
        else {
            throw UtilityError.invalidURL
        }

        return result
    }

    // MARK: - Hex

    static func encodeHex(
        _ input: String
    ) -> String {

        input.utf8.map {
            String(format: "%02x", $0)
        }
        .joined()
    }

    static func decodeHex(
        _ input: String
    ) throws -> String {

        var cleaned = input.filter {
            !$0.isWhitespace
        }

        if cleaned.lowercased().hasPrefix("0x") {
            cleaned = String(cleaned.dropFirst(2))
        }

        guard cleaned.count.isMultiple(of: 2) else {
            throw UtilityError.invalidHex
        }

        var data = Data()

        var index = cleaned.startIndex

        while index < cleaned.endIndex {

            let end = cleaned.index(
                index,
                offsetBy: 2
            )

            guard let byte = UInt8(
                cleaned[index..<end],
                radix: 16
            ) else {
                throw UtilityError.invalidHex
            }

            data.append(byte)

            index = end
        }

        guard let result = String(
            data: data,
            encoding: .utf8
        ) else {
            throw UtilityError.invalidUTF8
        }

        return result
    }

    // MARK: - Hash

    static func hash(
        _ input: String,
        algorithm: HashAlgorithm
    ) -> String {

        let data = Data(input.utf8)

        let bytes: [UInt8]

        switch algorithm {

        case .md5:
            bytes = Array(
                Insecure.MD5.hash(data: data)
            )

        case .sha1:
            bytes = Array(
                Insecure.SHA1.hash(data: data)
            )

        case .sha256:
            bytes = Array(
                SHA256.hash(data: data)
            )

        case .sha384:
            bytes = Array(
                SHA384.hash(data: data)
            )

        case .sha512:
            bytes = Array(
                SHA512.hash(data: data)
            )
        }

        return bytes.map {
            String(format: "%02x", $0)
        }
        .joined()
    }

    // MARK: - UUID

    static func generateUUIDs(
        count: Int,
        uppercase: Bool = false,
        hyphens: Bool = true
    ) -> String {

        let count = min(max(count, 1), 10_000)

        return (0..<count).map { _ in

            var value = UUID().uuidString

            if !uppercase {
                value = value.lowercased()
            }

            if !hyphens {
                value = value.replacingOccurrences(
                    of: "-",
                    with: ""
                )
            }

            return value

        }
        .joined(separator: "\n")
    }

    // MARK: - JWT

    static func decodeJWT(
        _ token: String
    ) throws -> (
        header: String,
        payload: String,
        signature: String
    ) {

        let parts = token
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .split(
                separator: ".",
                omittingEmptySubsequences: false
            )

        guard parts.count == 3 else {
            throw UtilityError.invalidJWT
        }

        let header = try decodeBase64URL(
            String(parts[0])
        )

        let payload = try decodeBase64URL(
            String(parts[1])
        )

        return (
            try formatJSON(header),
            try formatJSON(payload),
            String(parts[2])
        )
    }

    private static func decodeBase64URL(
        _ input: String
    ) throws -> String {

        var value = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = value.count % 4

        if remainder == 1 {
            throw UtilityError.invalidBase64
        }

        if remainder != 0 {
            value += String(
                repeating: "=",
                count: 4 - remainder
            )
        }

        return try decodeBase64(value)
    }
}
