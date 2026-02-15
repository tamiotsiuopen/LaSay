//
//  PunctuationConverter.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation

enum PunctuationConverter {
    
    private static let fullToHalf: [(String, String)] = [
        ("，", ","), ("。", "."), ("！", "!"), ("？", "?"),
        ("：", ":"), ("；", ";"), ("「", "\""), ("」", "\""),
        ("（", "("), ("）", ")"), ("、", ","),
    ]
    
    private static let fullWidthSet: [Character: String] = {
        var map = [Character: String]()
        for (fw, hw) in fullToHalf {
            map[Character(fw)] = hw
        }
        return map
    }()
    
    private static let halfWidthSet: [Character: String] = {
        var map = [Character: String]()
        for (fw, hw) in fullToHalf {
            map[Character(hw)] = fw
        }
        return map
    }()
    
    private static let allPunctuation: Set<Character> = {
        var chars = Set<Character>()
        for (fw, hw) in fullToHalf {
            chars.insert(Character(fw))
            chars.insert(Character(hw))
        }
        return chars
    }()
    
    private static func isCJK(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let v = scalar.value
        return (0x4E00...0x9FFF).contains(v) ||
               (0x3400...0x4DBF).contains(v) ||
               (0x3000...0x303F).contains(v) ||
               (0x3040...0x309F).contains(v) ||
               (0x30A0...0x30FF).contains(v) ||
               (0xAC00...0xD7AF).contains(v) ||
               (0x20000...0x2A6DF).contains(v)
    }
    
    static func convert(_ text: String, to style: PunctuationStyle) -> String {
        switch style {
        case .fullWidth:
            return convertToFullWidth(text)
        case .halfWidth:
            return convertToHalfWidth(text)
        case .spaces:
            return convertToSpaces(text)
        }
    }
    
    private static func convertToFullWidth(_ text: String) -> String {
        let chars = Array(text)
        var result = ""
        result.reserveCapacity(text.count)
        for i in chars.indices {
            let char = chars[i]
            if let fw = halfWidthSet[char] {
                let prevIsCJK = i > 0 && isCJK(chars[i - 1])
                let nextIsCJK = i < chars.count - 1 && isCJK(chars[i + 1])
                if prevIsCJK || nextIsCJK {
                    result.append(contentsOf: fw)
                } else {
                    result.append(char)
                }
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    private static func convertToHalfWidth(_ text: String) -> String {
        let chars = Array(text)
        var result = ""
        result.reserveCapacity(text.count)
        for i in chars.indices {
            let char = chars[i]
            if let hw = fullWidthSet[char] {
                let prevIsCJK = i > 0 && isCJK(chars[i - 1])
                let nextIsCJK = i < chars.count - 1 && isCJK(chars[i + 1])
                if prevIsCJK || nextIsCJK {
                    result.append(contentsOf: hw)
                } else {
                    result.append(char)
                }
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    private static func convertToSpaces(_ text: String) -> String {
        let chars = Array(text)
        var result = ""
        var lastWasPunctuation = false
        for i in chars.indices {
            let char = chars[i]
            if allPunctuation.contains(char) {
                let prevIsCJK = i > 0 && isCJK(chars[i - 1])
                let nextIsCJK = i < chars.count - 1 && isCJK(chars[i + 1])
                if prevIsCJK || nextIsCJK {
                    if !lastWasPunctuation {
                        result.append(" ")
                    }
                    lastWasPunctuation = true
                } else {
                    result.append(char)
                    lastWasPunctuation = false
                }
            } else {
                result.append(char)
                lastWasPunctuation = false
            }
        }
        return result
    }
}
