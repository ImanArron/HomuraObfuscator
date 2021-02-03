//
//  HOStringUtils.swift
//  HOCommandLineTool
//
//  Created by liulian on 2021/1/29.
//  Copyright © 2021 com.geetest. All rights reserved.
//

import Foundation

extension RandomAccessCollection where Index == Int {
    func randomElement() -> Element? {
        guard !self.isEmpty else { return nil }
        let random = arc4random_uniform(UInt32(count))
        return self[Int(random)]
    }
}

extension String {
    func titleUpperCased() -> String {
        return String(self.first!).uppercased() + dropFirst()
    }
    
    mutating func titleUpperCase() {
        self = titleUpperCased()
    }
}

class HOStringUtils {
    private let words: [String] = {
        let dirURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let bundleURL = URL(fileURLWithPath: "HomuraObfuscatorBundle.bundle", relativeTo: dirURL)
        if let bundle = Bundle(url: bundleURL), let path = bundle.path(forResource: "corncub", ofType: "txt") {
            let url = URL(fileURLWithPath: path)
            let str = try! String(contentsOf: url)
            return str.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        }
        return []
    }()
    
    func randomIdentifier(len: Int = 4, upper: Bool = false) -> String {
        guard var prefix = self.words.randomElement() else { return "" }
        if upper {
            prefix.titleUpperCase()
        }
        
        for _ in 0 ..< len {
            prefix += self.words.randomElement()!.titleUpperCased()
        }
        
        return prefix
    }
}
