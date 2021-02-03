//
//  HOObf.swift
//  HOCommandLineTool
//
//  Created by liulian on 2021/1/21.
//  Copyright © 2021 com.geetest. All rights reserved.
//

import Foundation
import Clang
import cclang

class HOObf {
    deinit {
        outputStream.close()
    }
    
    private var outputStream: OutputStream
    private let proj: HOXcodeProj
    private let index = Index(excludeDeclarationsFromPCH: true, displayDiagnostics: false)
    
    private lazy var clangArgs: [String] = {
        let headerArg = proj.publicHeaders.union(proj.internalHeaders).map { $0.deletingLastPathComponent().path }.map { "-I" + $0 }
        let index = Index(excludeDeclarationsFromPCH: true, displayDiagnostics: false)
        let sdk = HOPlatform.iPhoneOS.sdk("")
        let args = [
            "-x", "objective-c",
            "-fobjc-arc",
            "-fmodules -fsyntax-only -Xclang -ast-dump",
            "-mios-simulator-version-min=8.0",
            "-isysroot", sdk.path,
            "-I\(sdk.appendingPathComponent("usr/include").path)"
            ]
        return args + headerArg
    }()
    
    private static var systemSymbol: Set<String> = {
        // 工程中引用到的所有系统库都需要添加
        let source = """
        #import <Foundation/Foundation.h>
        #import <UIKit/UIKit.h>
        #import <WebKit/WebKit.h>
        #import <CoreMotion/CoreMotion.h>
        #import <objc/runtime.h>
        #import <objc/message.h>
        #import <AVFoundation/AVFoundation.h>
        #import <CoreGraphics/CoreGraphics.h>
        #import <tgmath.h>
        #import <CoreTelephony/CTTelephonyNetworkInfo.h>
        #import <CoreTelephony/CTCarrier.h>
        #import <CoreTelephony/CTCallCenter.h>
        #import <ifaddrs.h>
        #import <arpa/inet.h>
        #import <net/if.h>
        #import <sys/utsname.h>
        #import <Security/Security.h>
        #import <Security/SecureTransport.h>
        #import <dispatch/dispatch.h>
        #import <Availability.h>
        #import <CFNetwork/CFNetwork.h>
        #import <TargetConditionals.h>
        #import <arpa/inet.h>
        #import <fcntl.h>
        #import <ifaddrs.h>
        #import <netdb.h>
        #import <netinet/in.h>
        #import <net/if.h>
        #import <sys/socket.h>
        #import <sys/types.h>
        #import <sys/ioctl.h>
        #import <sys/poll.h>
        #import <sys/uio.h>
        #import <sys/un.h>
        #import <unistd.h>
        #import <sqlite3/sqlite3.h>
        #import <sqlite3.h>
        #import <SystemConfiguration/CaptiveNetwork.h>
        #include <sys/socket.h>
        #include <sys/sysctl.h>
        #include <net/if.h>
        #include <net/if_dl.h>
        #import <mach/mach.h>
        #include <ifaddrs.h>
        #include <arpa/inet.h>
        #import <sys/utsname.h>
        #import <dlfcn.h>
        #import <ifaddrs.h>
        #import <arpa/inet.h>
        #import <net/if.h>
        #import <sys/utsname.h>
        #import <SystemConfiguration/SystemConfiguration.h>
        #import <netinet/in.h>
        #import <arpa/inet.h>
        #import <ifaddrs.h>
        #import <netdb.h>
        #import <sys/socket.h>
        #import <netinet/in.h>
        #import <CoreFoundation/CoreFoundation.h>
        #include <CommonCrypto/CommonCrypto.h>
        """
        let args = [
            "-x", "objective-c",
            "-mios-simulator-version-min=8.0",
            "-isysroot", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
        ]
        let index = Index(excludeDeclarationsFromPCH: true, displayDiagnostics: false)
        let tu = try! TranslationUnit(clangSource: source, language: .objectiveC, index: index, commandLineArgs: args)
        return tu.obfuscatableSymbols()
    }()
    
    // 名称与三方库方法名、类名相同时，需要剔除(对于这种情况，需要有更好的解决方案)
    private lazy var specifiedSymbols: Set<String> = {
        return [
            "appSecret"
        ]
    }()
    
    // 指定目录
    private lazy var specifiedDirs: [String] = {
        return [
            "ThirdLibrary",
            "Pods"
        ]
    }()
    
    // 带有 xib 的 ViewController 和 View 不能混淆，在 Main.storyboard 中的 xib 名称需要加到此处，若是单独的 xib，不用在此添加，程序会自动识别
    private lazy var xibFiles: Set<String> = {
        return [
            "ViewController"
        ]
    }()
    
    init(project projectURL: URL, target targetName: String? = nil, output: OutputStream) throws {
        outputStream = output
        proj = try HOXcodeProj(project: projectURL, target: targetName)
    }
    
    func analyse() {
        print("start analyse \r\n")
        
        var blacklist = HOObf.systemSymbol
        blacklist.formUnion(specifiedSymbols)
        for path in proj.publicHeaders {
            if let tu = try? TranslationUnit(filename: path.path, index: index, commandLineArgs: clangArgs) {
                blacklist.formUnion(tu.obfuscatableSymbols(skipImport: true))
            }
        }
        
        // 找到所有的 xib 文件，xib 文件不混淆
        var xibs = Set<String>()
        for url in proj.sources.union(proj.internalHeaders) {
            let filename = url.path
            
            guard let unit = try? TranslationUnit(filename: filename, index: index, commandLineArgs: self.clangArgs) else {
                continue
            }
            
            let file = unit.cursor.range.start.file
            if let detailFileName = file.name.components(separatedBy: "/").last {
                let arr = detailFileName.components(separatedBy: ".")
                if 2 == arr.count {
                    if "xib" == arr[1] {
                        xibs.insert(arr[0])
                    }
                }
            }
        }
        xibs.formUnion(xibFiles)
        
        var macros = [String: String]()
        var properties = Set<String>()
        var setMethods = Set<String>()
        let stringUtils = HOStringUtils()

        for url in proj.sources.union(proj.internalHeaders) {
            let filename = url.path
            
            guard let unit = try? TranslationUnit(filename: filename, index: index, commandLineArgs: self.clangArgs) else {
                continue
            }
            
            let file = unit.cursor.range.start.file
            print(" ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ file: \(file.name) \r")
            
            if let detailFileName = file.name.components(separatedBy: "/").last {
                let arr = detailFileName.components(separatedBy: ".")
                if 2 == arr.count {
                    if xibs.contains(arr[0]) {
                        continue
                    }
                }
            }
            
            var isSpecifiedDir = false
            for dir in specifiedDirs {
                if file.name.contains("/" + dir + "/") {
                    isSpecifiedDir = true
                    break
                }
            }
            
            if isSpecifiedDir {
                continue
            }
                        
            print(" ################################ \r\n")
            
            let indexerCallbacks = Clang.IndexerCallbacks()
            indexerCallbacks.indexDeclaration = { decl in
                if let cursor = decl.cursor {
                    let desc = cursor.description
                    guard desc.count > 0 else { return }
                    guard !blacklist.contains(desc) else { return }
                    
                    var isInBlackList = false
                    if desc.contains(":") {
                        desc.components(separatedBy: ":").forEach { (str) in
                            if blacklist.contains(str) {
                                isInBlackList = true
                                return
                            }
                        }
                    }
                    guard !isInBlackList else { return }
                    
                    print(" desc: \(desc) \r")
                    // rawComment 表示注释
//                    if let rawComment = cursor.rawComment {
//                        print(" rawComment: \(rawComment) \r")
//                    }
                    
                    switch cursor {
                        // OC 的类(@interface 后面跟的名字)、协议(@protocol 后面跟的名字)
                    case is ObjCInterfaceDecl, is ObjCProtocolDecl:
                        if !macros.keys.contains(desc) {
                            macros[desc] = stringUtils.randomIdentifier(upper: true)
                        }
                        
                        // OC 的类方法、实例方法
                    case is ObjCClassMethodDecl, is ObjCInstanceMethodDecl:
                        desc.components(separatedBy: ":").forEach { (str) in
                            if str.hasPrefix("set") {   // setter 和 getter 方法不混淆
                                let startIndex = str.startIndex, endIndex = str.endIndex
                                let subStr = str[str.index(startIndex, offsetBy: "set".count) ..< endIndex]
                                setMethods.insert(String(subStr).lowercased())
                            } else if !macros.keys.contains(str) {
                                if str.hasPrefix("initWith") {
                                    macros[str] = "initWith" + stringUtils.randomIdentifier(upper: true)
                                } else {
                                    macros[str] = stringUtils.randomIdentifier()
                                }
                            }
                        }
                    
                        // OC 的属性
                    case is ObjCPropertyDecl, is ObjCIvarDecl:
                        // 跟属性同名的方法名、类名不混淆
                        properties.insert(desc)
                        
                        // C 方法名
                    case is FunctionDecl:
                        if !macros.keys.contains(desc) {
                            macros[desc] = stringUtils.randomIdentifier()
                        }
                        
                        // 变量
                    case is VarDecl:
                        // 跟变量同名的方法名、类名不混淆
                        properties.insert(desc)
                        
                    default:
                        break
                    }
                }
            }
            
            do {
                try unit.indexTranslationUnit(indexAction: IndexAction(), indexerCallbacks: indexerCallbacks, options: .none)
            } catch {
                print("index translation unit error: \(error) \r")
            }
            print(" ################################ \r\n")
        }
        
        macros.removeValue(forKey: "")
                
        let cs = CharacterSet(charactersIn: "_")
        for (key, val) in macros.sorted(by: { (macro1, macro2) -> Bool in
            return macro1.key.trimmingCharacters(in: cs) < macro2.key.trimmingCharacters(in: cs)
        }) {
            guard outputStream.hasSpaceAvailable else { break }
            
            guard !properties.contains(key) else { continue }
            guard !setMethods.contains(key.lowercased()) else { continue }
            guard !xibs.contains(key) else { continue }
            
            let paddedKey = key.padded(toWidth: 30)
            let macro = "#ifndef " + paddedKey + "\n" + "#define " + paddedKey + " " + val + "\n" + "#endif\n\r"
            outputStream.write(macro, maxLength: macro.count)
        }
        
        print("stop analyse \r\n")
    }
}

enum HOPlatform: String {
    case AppleTVOS
    case WatchSimulator
    case AppleTVSimulator
    case iPhoneOS
    case MacOSX
    case iPhoneSimulator
    case WatchOS
    
    func sdk(_ ver: String) -> URL {
        var devPath = URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer")
        devPath.appendPathComponent("Platforms/\(self).platform/Developer/SDKs/\(self)\(ver).sdk")
        return devPath
    }
}
