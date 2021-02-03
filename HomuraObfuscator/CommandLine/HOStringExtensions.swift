//
//  HOStringExtensions.swift
//  HOObfuscator
//
//  Created by liulian on 2021/1/11.
//  Copyright © 2021 com.geetest. All rights reserved.
//

import Foundation

#if os(OSX)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

internal extension String {
    private func _localDecimalPoint() -> Character {
        guard let local = localeconv(), let decimalPoint = local.pointee.decimal_point else {
            return "."
        }
        
        return Character(UnicodeScalar(UInt8(bitPattern: decimalPoint.pointee)))
    }
    
    func toDouble() -> Double? {
        let decimalPoint = String(self._localDecimalPoint())
        guard decimalPoint == "." || self.range(of: ".") == nil else {
            return nil
        }
        let localeSelf = self.replacingOccurrences(of: decimalPoint, with: ".")
        return Double(localeSelf)
    }
    
    func split(by: Character, maxSplits: Int = 0) -> [String] {
        var s = [String]()
        var numSplits = 0
        var curIdx = self.startIndex
        for i in self.indices {
            let c = self[i]
            if c == by && (maxSplits == 0 || numSplits < maxSplits) {
                s.append(String(self[curIdx ..< i]))
                curIdx = self.index(after: i)
                numSplits += 1
            }
        }
        
        if curIdx != self.endIndex {
            s.append(String(self[curIdx ..< self.endIndex]))
        }
        
        return s
    }
    
    func padded(toWidth width: Int, with padChar: Character = " ") -> String {
        var s = self
        var currlen = self.count
        while currlen < width {
            s.append(padChar)
            currlen += 1
        }
        return s
    }
    
    func wrapped(atWidth width: Int, wrapBy: Character = "\n", splitBy: Character = " ") -> String {
        var s = ""
        var currLineWidth = 0
        for word in self.split(by: splitBy) {
            let wordLen = word.count
            if currLineWidth + wordLen + 1 > width {
                if wordLen >= width {
                    s += word
                }
                
                s.append(wrapBy)
                currLineWidth = 0
            }
            
            currLineWidth += (wordLen + 1)
            s += word
            s.append(splitBy)
        }
        return s
    }
}
