//
//  String+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/29.
//

import Foundation

extension String {
    static let vowels: [Regex] = [
        // English
        /[aeiou]+/,
        /[aeou]+[hm]+/,
        /hm*/,
        // Japanese
        /[あえいおう]+/,
        // Chinese
        /[啊呀哈嗯嘿噢哦嗷呼嘻呃呵]+/
    ]
}

extension String {
    func extractNearest(from startString: String? = nil, to endString: String? = nil) -> Substring {
        let startIndex = if let startString, let index = range(of: startString)?.lowerBound {
            index
        } else {
            self.startIndex
        }
        let endIndex = if let endString, let index = String(self[..<startIndex]).range(of: endString)?.upperBound {
            index
        } else {
            self.endIndex
        }
        return self[startIndex ..< endIndex]
    }
}

extension String {
    func toTTMLTimestamp() -> TimeInterval? {
        let prefixMillisecondsRegex = /(.+)\.(\d+)/
        let minutesSecondsRegex = /(\d+)\:(\d+)/

        do {
            guard
                let prefixMillisecondsMatch = try prefixMillisecondsRegex.wholeMatch(in: self),
                let milliseconds = Double(prefixMillisecondsMatch.output.2)
            else { return nil }
            let prefix = prefixMillisecondsMatch.output.1

            if let minutesSecondsMatch = try minutesSecondsRegex.wholeMatch(in: prefix) {
                guard
                    let minutes = Double(minutesSecondsMatch.output.1),
                    let seconds = Double(minutesSecondsMatch.output.2)
                else { return nil }

                return minutes * 60 + seconds + milliseconds / 1000
            } else if let seconds = Double(prefix) {
                return seconds + milliseconds / 1000
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension String {
    var reversed: String {
        String(reversed())
    }

    var removingParentheses: String {
        replacing(/[\[\]\()（）]/, with: "")
    }

    var removingPunctuations: String {
        replacing(/[\p{P}\s]/, with: "")
    }

    var normalizingSpaces: String {
        replacing(/\\u{(00A0|20[0-9A])}/, with: "")
    }

    func countConsecutiveSpacesBetweenNumbers(terminator: Character) -> [Int: Int] {
        var result: [Int: Int] = [:]
        var currentNumber: Int?
        var spaceCount = 0
        var buffer = ""

        for character in self {
            if character.isWholeNumber {
                // Builds multi-digit numbers
                buffer.append(character)
            } else if character == terminator {
                // Handles the end of a number
                if let number = Int(buffer) {
                    if let previousNumber = currentNumber {
                        // Store the previous number and its space count
                        result[previousNumber] = spaceCount
                    }
                    // Updates current number
                    currentNumber = number
                    spaceCount = 0
                }
                buffer = ""
            } else if character.isWhitespace {
                // Counts consecutive spaces
                spaceCount += 1
            }
        }

        // Adds the last number to the result (if it exists)
        if let number = Int(buffer), let previousNumber = currentNumber {
            result[previousNumber] = spaceCount
            result[number] = 0
        }

        return result
    }
}

public extension String.Encoding {
    static let gbk: String.Encoding = {
        let gbkEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        return String.Encoding(rawValue: gbkEncoding)
    }()
}
