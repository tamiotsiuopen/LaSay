//
//  TextCleaner.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation

struct TextCleaner {
    static func basicCleanup(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.replacingOccurrences(of: "([。！？!?,，])\\1+", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\b(\\w+)(\\s+\\1\\b)+", with: "$1", options: .regularExpression)
        return result
    }
}
