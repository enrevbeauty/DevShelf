import AppKit

enum SyntaxHighlightService {

    private static func adaptive(
        light: UInt32,
        dark: UInt32
    ) -> NSColor {
        NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(
                from: [.darkAqua, .aqua]
            ) == .darkAqua

            let hex = isDark ? dark : light

            return NSColor(
                red: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255,
                alpha: 1
            )
        }
    }

    static let keywordColor = adaptive(
        light: 0x9B2393,
        dark: 0xC792EA
    )

    static let stringColor = adaptive(
        light: 0xB4261A,
        dark: 0xA5D6A7
    )

    static let commentColor = adaptive(
        light: 0x667B41,
        dark: 0x7E8794
    )

    static let numberColor = adaptive(
        light: 0x1C00CF,
        dark: 0xF78C6C
    )

    static let functionColor = adaptive(
        light: 0x326D74,
        dark: 0x82AAFF
    )

    static let typeColor = adaptive(
        light: 0x0B4F79,
        dark: 0xFFCB6B
    )

    static let operatorColor = adaptive(
        light: 0x555555,
        dark: 0x89DDFF
    )

    static func keywords(
        for language: String
    ) -> [String] {
        let words: String

        switch language.lowercased() {

        case "swift":
            words = """
            import struct class enum protocol extension
            func let var if else guard switch case default
            return throw throws try catch do async await
            for in while repeat break continue
            public private internal fileprivate open
            static final override mutating init deinit
            self super nil true false some any
            where associatedtype typealias actor
            """

        case "javascript", "typescript":
            words = """
            const let var function return async await
            import export from default class extends
            new this super if else switch case
            for while do break continue try catch
            throw finally typeof instanceof null
            undefined true false interface type
            implements public private readonly
            """

        case "python":
            words = """
            def class import from as return yield
            if elif else for while in is not and or
            try except finally raise with pass
            break continue lambda async await
            True False None global nonlocal assert
            """

        case "go":
            words = """
            package import func var const type struct
            interface map chan select go defer
            if else for range switch case default
            return break continue fallthrough
            nil true false make new
            """

        case "rust":
            words = """
            fn let mut pub struct enum impl trait
            use mod crate self super match if else
            loop while for in return async await
            move unsafe const static where
            true false Some None Ok Err
            """

        case "shell", "bash", "zsh":
            words = """
            if then else elif fi for while until
            do done case esac function export
            local readonly return exit source
            echo printf sudo cd mkdir rm cp mv
            docker git npm yarn pnpm curl wget
            grep sed awk chmod chown
            """

        case "sql":
            words = """
            SELECT FROM WHERE INSERT INTO VALUES
            UPDATE SET DELETE CREATE TABLE ALTER
            DROP JOIN LEFT RIGHT INNER OUTER
            GROUP BY ORDER HAVING LIMIT OFFSET
            DISTINCT AS AND OR NOT NULL IS
            UNION ALL PRIMARY KEY FOREIGN
            REFERENCES INDEX BEGIN COMMIT
            """

        case "dockerfile":
            words = """
            FROM RUN CMD LABEL EXPOSE ENV ADD
            COPY ENTRYPOINT VOLUME USER WORKDIR
            ARG ONBUILD STOPSIGNAL HEALTHCHECK
            SHELL AS
            """

        case "json", "yaml":
            words = "true false null"

        default:
            words = ""
        }

        return words
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    static func highlight(
        storage: NSTextStorage,
        language: String,
        font: NSFont
    ) {
        let source = storage.string

        let range = NSRange(
            location: 0,
            length: storage.length
        )

        storage.beginEditing()
        defer { storage.endEditing() }

        storage.addAttributes([
            .font: font,
            .foregroundColor: NSColor.labelColor
        ], range: range)

        let lang = language.lowercased()

        guard lang != "plain text" else {
            return
        }

        func apply(
            _ pattern: String,
            color: NSColor,
            options: NSRegularExpression.Options = []
        ) {
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: options
            ) else {
                return
            }

            regex.enumerateMatches(
                in: source,
                range: range
            ) { match, _, _ in
                guard let match else { return }

                storage.addAttribute(
                    .foregroundColor,
                    value: color,
                    range: match.range
                )
            }
        }

        // Numbers

        apply(
            #"\b(?:0x[0-9a-fA-F]+|\d+(?:\.\d+)?)\b"#,
            color: numberColor
        )

        // Operators

        apply(
            #"[+\-*/%=!<>|&^~?:]+"#,
            color: operatorColor
        )

        // Functions

        apply(
            #"\b[a-zA-Z_]\w*(?=\s*\()"#,
            color: functionColor
        )

        // Types

        if ["swift", "go", "rust", "typescript"]
            .contains(lang) {
            apply(
                #"\b[A-Z][a-zA-Z0-9_]*\b"#,
                color: typeColor
            )
        }

        // Keywords

        let words = keywords(for: language)

        if !words.isEmpty {
            let pattern = "\\b(?:" +
                words.map {
                    NSRegularExpression.escapedPattern(
                        for: $0
                    )
                }.joined(separator: "|") +
                ")\\b"

            apply(
                pattern,
                color: keywordColor,
                options: lang == "sql"
                    ? [.caseInsensitive]
                    : []
            )
        }

        // Shell-specific highlighting

        if ["shell", "bash", "zsh"].contains(lang) {

            // Variables
            apply(
                #"\$(?:\{[^}]+\}|[a-zA-Z_]\w*|\d+)"#,
                color: typeColor
            )

            // Command-line options
            apply(
                #"(?<!\S)--?[a-zA-Z][\w-]*"#,
                color: typeColor
            )

            // Command names at the beginning of a line
            apply(
                #"(?m)^\s*[a-zA-Z_][\w.-]*"#,
                color: functionColor
            )
        }

        // JSON property names

        if lang == "json" {
            apply(
                #"\"(?:\\.|[^\"\\])*\"(?=\s*:)"#,
                color: typeColor
            )
        }

        // Strings and comments

        let strings =
            #"\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`"#

        let comments: String

        switch lang {

        case "python", "shell", "bash", "zsh",
             "yaml", "dockerfile":
            comments = #"#[^\r\n]*"#

        case "sql":
            comments = #"--[^\r\n]*|/\*[\s\S]*?\*/"#

        case "json":
            comments = ""

        case "html":
            comments = #"<!--[\s\S]*?-->"#

        default:
            comments = #"//[^\r\n]*|/\*[\s\S]*?\*/"#
        }

        let pattern = comments.isEmpty
            ? "(\(strings))"
            : "(\(strings))|(\(comments))"

        guard let regex = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return
        }

        regex.enumerateMatches(
            in: source,
            range: range
        ) { match, _, _ in
            guard let match else { return }

            let isString =
                match.range(at: 1).location != NSNotFound

            var color = isString
                ? stringColor
                : commentColor

            if lang == "json", isString {
                let end = NSMaxRange(match.range)

                let remaining = (source as NSString)
                    .substring(from: end)
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                if remaining.hasPrefix(":") {
                    color = typeColor
                }
            }

            storage.addAttribute(
                .foregroundColor,
                value: color,
                range: match.range
            )
        }
    }
}
