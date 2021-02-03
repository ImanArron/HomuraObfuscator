//
//  TranslationUnit+Extras.swift
//  HOCommandLineTool
//
//  Created by liulian on 2021/1/21.
//  Copyright © 2021 com.geetest. All rights reserved.
//

import Foundation
import Clang
import cclang

extension TranslationUnit {
    func obfuscatableSymbols(skipImport: Bool = false) -> Set<String> {
        var symbols: Set<String> = []
        let indexerCallbacks = Clang.IndexerCallbacks()
        indexerCallbacks.indexDeclaration = { decl in
            if let cursor = decl.cursor {
                switch cursor {
                case is ObjCClassMethodDecl, is ObjCInstanceMethodDecl:
                    cursor.description.components(separatedBy: ":").forEach { (str) in
                        symbols.insert(str)
                    }
                default:
                    symbols.insert(cursor.description)
                }
            }
        }
        
        do {
            try self.indexTranslationUnit(indexAction: IndexAction(), indexerCallbacks: indexerCallbacks, options: .none)
        } catch {
            print("index translation unit error: \(error) \r")
        }
        symbols.remove("")
        return symbols
    }
}
