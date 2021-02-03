//
//  main.swift
//  HOCommandLineTool
//
//  Created by liulian on 2021/1/21.
//  Copyright © 2021 com.geetest. All rights reserved.
//

import Foundation

let commandLine = HOCommandLine()
let projectPathOption = HOStringOption(shortFlag: "p", longFlag: "project", required: true, helpMessage: "Path to Xcode project")
let targetNameOption = HOStringOption(shortFlag: "t", longFlag: "target", required: true, helpMessage: "Target name in Xcode project")
let outputPathOption = HOStringOption(shortFlag: "o", longFlag: "output", required: true, helpMessage: "Path to output file")
let helpOption = HOBoolOption(shortFlag: "h", longFlag: "help", required: false, helpMessage: "Print a help message")

enum HOObfMainError: Error, CustomStringConvertible {
    case InvalidProjectPath
    case InvalidProjectURL
    case InvalidTargetName
    case InvalidOutputPath
    case InvalidOutputStream
    
    var description: String {
        switch self {
        case .InvalidProjectPath:
            return "invalid project path"
        case .InvalidProjectURL:
            return "invalid project url"
        case .InvalidTargetName:
            return "invalid target name"
        case .InvalidOutputPath:
            return "invalid output path"
        case .InvalidOutputStream:
            return "invalid output stream"
        }
    }
}

func analyse() throws {
    guard let projectPath = projectPathOption.value else {
        throw HOObfMainError.InvalidOutputPath
    }
    let projectURL = URL(fileURLWithPath: projectPath)
    guard let outputPath = outputPathOption.value else {
        throw HOObfMainError.InvalidOutputPath
    }
    guard let outputStream = OutputStream(toFileAtPath: outputPath, append: false) else {
        throw HOObfMainError.InvalidOutputStream
    }
    outputStream.open()
    defer { outputStream.close() }
    
    let target = targetNameOption.value
    let geeObf = try HOObf(project: projectURL, target: target, output: outputStream)
    geeObf.analyse()
}

func startObf() throws {
    try parse()
    try analyse()
}

func parse() throws {
    var arguments = CommandLine.arguments
    while arguments.count > 1 {
        arguments.removeLast()
    }
    // 修改 `project` 为需要混淆的工程路径
    arguments.append("-p=your xcode project path")
    // 修改 `target` 为 `project` 的 `target`
    arguments.append("-t=target of your project")
    // 修改混淆后的文件存储路径(此处，建议新建一个 `.h` 文件，在工程的 `pch` 中导入该 `.h` 文件，再执行 `HomuraObfuscator` 即可实现混淆功能
    arguments.append("-o=your .h file path")
    arguments.append("-h=PrintHelpMessage")
    let commandLine = HOCommandLine(argumets: arguments)
    commandLine.addOptions([projectPathOption, targetNameOption, outputPathOption, helpOption])
    try commandLine.parse()
}

do {
    try startObf()
} catch let error as HOCommandLine.HOParseError {
    commandLine.printUsage(error)
    exit(EX_USAGE)
} catch let error as HOObfMainError {
    print("homura obfuscator main error: \(error)")
    exit(EX_USAGE)
}


