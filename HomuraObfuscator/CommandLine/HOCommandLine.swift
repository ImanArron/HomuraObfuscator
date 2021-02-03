//
//  HOCommandLine.swift
//  HOObfuscator
//
//  Created by liulian on 2021/1/11.
//  Copyright © 2021 com.geetest. All rights reserved.
//

import Foundation

private struct StderrOutputStream: TextOutputStream {
    static let stream = StderrOutputStream()
    func write(_ string: String) {
        fputs(string, stderr)
    }
}

public class HOCommandLine {
    private var _arguments: [String]
    private var _options: [HOOption] = [HOOption]()
    private var _maxFlagDescriptionWidth: Int = 0
    private var _usedFlags: Set<String> {
        var usedFlags = Set<String>(minimumCapacity: _options.count * 2)
        
        for option in _options {
            for case let flag? in [option.shortFlag, option.longFlag] {
                usedFlags.insert(flag)
            }
        }
        
        return usedFlags
    }
    
    public private(set) var unparsedArguments: [String] = [String]()
    
    public var formatOutput: ((String, HOOutputType) -> String)?
    
    public var maxFlagDescriptionWidth: Int {
        if _maxFlagDescriptionWidth == 0 {
            _maxFlagDescriptionWidth = _options.map { $0.flagDescription.count }.sorted().first ?? 0
        }
        
        return _maxFlagDescriptionWidth
    }
    
    public enum HOOutputType {
        case About
        
        case Error
        
        case OptionFlag
        
        case OptionHelp
    }
    
    public enum HOParseError: Error, CustomStringConvertible {
        case InvalidArgument(String)
        
        case InvalidValueForOption(HOOption, [String])
        
        case MissingRequiredOptions([HOOption])
        
        public var description: String {
            switch self {
            case let .InvalidArgument(arg):
                return "Invalid argument: \(arg)"
                
            case let .InvalidValueForOption(opt, vals):
                let vs = vals.joined(separator: ",")
                return "Invalid value(s) for option \(opt.flagDescription): \(vs)"
                
            case let .MissingRequiredOptions(opts):
                return "Missing required options: \(opts.map { return $0.flagDescription })"
            }
        }
    }
    
    public init(argumets: [String] = CommandLine.arguments) {
        self._arguments = argumets
        setlocale(LC_ALL, "")
    }
    
    private func _getFlagValues(_ flagIndex: Int, _ attachedArg: String? = nil) -> [String] {
        var args: [String] = [String]()
        var skipFlagChecks = false
        
        if let attachedArg = attachedArg {
            args.append(attachedArg)
        }
        
        for i in flagIndex + 1 ..< _arguments.count {
            if !skipFlagChecks {
                if _arguments[i] == argumentStopper {
                    skipFlagChecks = true
                    continue
                }
                
                if _arguments[i].hasPrefix(shortOptionPrefix) && Int(_arguments[i]) == nil && _arguments[i].toDouble() == nil {
                    break
                }
            }
            
            args.append(_arguments[i])
        }
        
        return args
    }
    
    public func addOption(_ option: HOOption) {
        let uf = _usedFlags
        for case let flag? in [option.shortFlag, option.longFlag] {
            assert(!uf.contains(flag), "Flag '\(flag)' already in use")
        }
        
        _options.append(option)
        _maxFlagDescriptionWidth = 0
    }
    
    public func addOptions(_ options: [HOOption]) {
        for option in options {
            addOption(option)
        }
    }
    
    public func addOptions(_ options: HOOption...) {
        for option in options {
            addOption(option)
        }
    }
    
    public func setOptions(_ options: [HOOption]) {
        _options = [HOOption]()
        addOptions(options)
    }
    
    public func setOptions(_ options: HOOption...) {
        _options = [HOOption]()
        addOptions(options)
    }
    
    public func parse(strict: Bool = false) throws {
        var strays = _arguments
        strays[0] = ""
        let argumentsEnumerator = _arguments.enumerated()
        for (idx, arg) in argumentsEnumerator {
            if arg == argumentStopper {
                break
            }
            
            if !arg.hasPrefix(shortOptionPrefix) {
                continue
            }
            
            let skipChars = arg.hasPrefix(longOptionPrefix) ? longOptionPrefix.count : shortOptionPrefix.count
            let flagWithArg = String(arg[arg.index(arg.startIndex, offsetBy: skipChars) ..< arg.endIndex])
            if flagWithArg.isEmpty {
                continue
            }
            
            let splitFlag = flagWithArg.split(by: argumentAttacher, maxSplits: 1)
            let flag = splitFlag[0]
            let attachedArg: String? = splitFlag.count == 2 ? String(splitFlag[1]) : nil
            var flagMatched = false
            for option in _options where option.flagMatch(String(flag)) {
                let vals = self._getFlagValues(idx, attachedArg)
                guard option.setValue(vals) else {
                    throw HOParseError.InvalidValueForOption(option, vals)
                }
                
                var claimedIdx = idx + option.claimedValues
                if let _ = attachedArg {
                    claimedIdx -= 1
                }
                if claimedIdx >= idx {
                    for i in idx ... claimedIdx {
                        strays[i] = ""
                    }
                }
                
                flagMatched = true
                break
            }
            
            let flagLen = flag.count
            if !flagMatched && !arg.hasPrefix(longOptionPrefix) {
                let flagCharactersEnumerator = flag.enumerated()
                for (i, c) in flagCharactersEnumerator {
                    for option in _options where option.flagMatch(String(c)) {
                        let vals = (i == flagLen - 1) ? self._getFlagValues(idx, attachedArg) : [String]()
                        guard option.setValue(vals) else {
                            throw HOParseError.InvalidValueForOption(option, vals)
                        }
                        
                        var claimedIdx = idx + option.claimedValues
                        if let _ = attachedArg {
                            claimedIdx -= 1
                        }
                        for i in idx ... claimedIdx {
                            strays[i] = ""
                        }
                        
                        flagMatched = true
                        break
                    }
                }
                
                guard !strict || flagMatched else {
                    throw HOParseError.InvalidArgument(arg)
                }
            }
        }
        
        let missingOptions = _options.filter { $0.required && !$0.wasSet }
        guard missingOptions.count == 0 else {
            throw HOParseError.MissingRequiredOptions(missingOptions)
        }
        
        unparsedArguments = strays.filter { $0 != "" }
    }
    
    public func defaultFormat(s: String, type: HOOutputType) -> String {
        switch type {
        case .About:
            return "\(s)\n"
        case .Error:
            return "\(s)\n\n"
        case .OptionFlag:
            return "  \(s.padded(toWidth: maxFlagDescriptionWidth)):\n"
        case .OptionHelp:
            return "     \(s)\n"
        }
    }
    
    public func printUsage<TargetStream: TextOutputStream>(_ to: inout TargetStream) {
        let format = formatOutput != nil ? formatOutput! : defaultFormat
        let name = _arguments[0]
        print(format("Usage: \(name) [options]", .About), terminator: "", to: &to)
        for opt in _options {
            print(format(opt.flagDescription, .OptionFlag), terminator: "", to: &to)
            print(format(opt.helpMessage, .OptionHelp), terminator: "", to: &to)
        }
    }
    
    public func printUsage<TargetStream: TextOutputStream>(_ error: Error, _ to: inout TargetStream) {
        let format = formatOutput != nil ? formatOutput! : defaultFormat
        print(format("\(error)", .Error), terminator: "", to: &to)
        printUsage(&to)
    }
    
    public func printUsage(_ error: Error) {
        var out = StderrOutputStream.stream
        printUsage(error, &out)
    }
    
    public func printUsage() {
        var out = StderrOutputStream.stream
        printUsage(&out)
    }
}
