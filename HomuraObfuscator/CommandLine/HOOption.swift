//
//  HOOption.swift
//  HOObfuscator
//
//  Created by liulian on 2021/1/11.
//  Copyright © 2021 com.geetest. All rights reserved.
//

import Foundation

let shortOptionPrefix = "-"
let longOptionPrefix = "--"

let argumentStopper = "--"

let argumentAttacher: Character = "="

public class HOOption {
    public let shortFlag: String?
    public let longFlag: String?
    public let required: Bool
    public let helpMessage: String
    
    public var wasSet: Bool { return false }
    
    public var claimedValues: Int { return 0 }
    
    public var flagDescription: String {
        switch (shortFlag, longFlag) {
        case let (sf?, lf?):
            return "\(shortOptionPrefix)\(sf), \(longOptionPrefix)\(lf)"
        case (nil, let lf?):
            return "\(longOptionPrefix)\(lf)"
        case (let sf?, nil):
            return "\(shortOptionPrefix)\(sf)"
        default:
            return ""
        }
    }
    
    internal init(_ shortFlag: String?, _ longFlag: String?, _ required: Bool, _ helpMessage: String) {
        if let sf = shortFlag {
            assert(sf.count == 1, "Short flag must be a single character")
            assert(Int(sf) == nil && sf.toDouble() == nil, "Short flag cannout be a numeric value")
        }
        
        if let lf = longFlag {
            assert(Int(lf) == nil && lf.toDouble() == nil, "Long flag cannout be a numeric value")
        }
        
        self.shortFlag = shortFlag
        self.longFlag = longFlag
        self.required = required
        self.helpMessage = helpMessage
    }
    
    public convenience init(shortFlag: String, longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, longFlag, required, helpMessage)
    }
    
    public convenience init(shortFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, nil, required, helpMessage)
    }

    public convenience init(longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(nil, longFlag as String?, required, helpMessage)
    }

    func flagMatch(_ flag: String) -> Bool {
        return flag == shortFlag || flag == longFlag
    }

    func setValue(_ values: [String]) -> Bool {
        return false
    }
}

public class HOBoolOption: HOOption {
    private var _value: Bool = false
    
    public var value: Bool {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value
    }
    
    override func setValue(_ values: [String]) -> Bool {
        _value = true
        return true
    }
}

public class HOIntOption: HOOption {
    private var _value: Int?
    
    public var value: Int? {
        return _value
    }
    
    override public var wasSet: Bool {
        if let _ = _value {
            return true
        } else {
            return false
        }
    }
    
    override public var claimedValues: Int {
        if let _ = _value {
            return 1
        } else {
            return 0
        }
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if 0 == values.count {
            return false
        }
        
        if let val = Int(values[0]) {
            _value = val
            return true
        }
        
        return false
    }
}

public class HOCounterOption: HOOption {
    private var _value: Int = 0
    
    public var value: Int {
        return _value
    }
    
    override public var wasSet: Bool {
        return _value > 0
    }
    
    public func reset() {
        _value = 0
    }
    
    override func setValue(_ values: [String]) -> Bool {
        _value += 1
        return true
    }
}

public class HODoubleOption: HOOption {
    private var _value: Double?
    
    public var value: Double? {
        return _value
    }
    
    override public var wasSet: Bool {
        if let _ = _value {
            return true
        } else {
            return false
        }
    }
    
    override public var claimedValues: Int {
        if let _ = _value {
            return 1
        } else {
            return 0
        }
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if 0 == values.count {
            return false
        }
        
        if let val = values[0].toDouble() {
            _value = val
            return true
        }
        
        return false
    }
}

public class HOStringOption: HOOption {
    private var _value: String?
    
    public var value: String? {
        return _value
    }
    
    override public var wasSet: Bool {
        if let _ = _value {
            return true
        } else {
            return false
        }
    }
    
    override public var claimedValues: Int {
        if let _ = _value {
            return 1
        } else {
            return 0
        }
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if 0 == values.count {
            return false
        }
        
        _value = values[0]
        return true
    }
}

public class HOMultiStringOption: HOOption {
    private var _value: [String]?
    
    public var value: [String]? {
        return _value
    }
    
    override public var wasSet: Bool {
        if let _ = _value {
            return true
        } else {
            return false
        }
    }
    
    override public var claimedValues: Int {
        if let val = _value {
            return val.count
        } else {
            return 0
        }
    }
    
    override func setValue(_ values: [String]) -> Bool {
        if 0 == values.count {
            return false
        }
        
        _value = values
        return true
    }
}

public class HOEnumOption<T : RawRepresentable>: HOOption where T.RawValue == String {
    private var _value: T?
    
    public var value: T? {
        return _value
    }
    
    override public var wasSet: Bool {
        if let _ = _value {
            return true
        } else {
            return false
        }
    }
    
    override public var claimedValues: Int {
        if let _ = _value {
            return 1
        } else {
            return 0
        }
    }
    
    internal override init(_ shortFlag: String?, _ longFlag: String?, _ required: Bool, _ helpMessage: String) {
        super.init(shortFlag, longFlag, required, helpMessage)
    }
    
    public convenience init(shortFlag: String, longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, longFlag, required, helpMessage)
    }

    public convenience init(shortFlag: String, required: Bool = false, helpMessage: String) {
        self.init(shortFlag as String?, nil, required, helpMessage)
    }

    public convenience init(longFlag: String, required: Bool = false, helpMessage: String) {
        self.init(nil, longFlag as String?, required, helpMessage)
    }

    override func setValue(_ values: [String]) -> Bool {
        if values.count == 0 {
            return false
        }

        if let v = T(rawValue: values[0]) {
            _value = v
            return true
        }

        return true
    }
}
