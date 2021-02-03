//
//  HOXcodeProj.swift
//  HOCommandLineTool
//
//  Created by liulian on 2021/1/21.
//  Copyright © 2021 com.geetest. All rights reserved.
//

import Foundation
import XcodeProj
import PathKit

enum HOXcodeProjError: Error {
    case NoAvailableTarget
    case InvalidProject
}

class HOXcodeProj {
    private let pbxProj: PBXProj
    private let target: PBXNativeTarget
    let srcRootURL: URL
    var buildSettings = BuildSettings()
    
    var publicHeaders: Set<URL> = []
    var internalHeaders: Set<URL> = []
    var sources: Set<URL> = []
    
    init(project projectURL: URL, target targetName: String?) throws {
        let xcodeproj = try XcodeProj(path: Path(projectURL.path))
        self.pbxProj = xcodeproj.pbxproj
        self.srcRootURL = projectURL.deletingLastPathComponent()
        let targets = self.pbxProj.nativeTargets
        guard let target = targets.first(where: { $0.name == targetName }) ?? targets.first else {
            throw HOXcodeProjError.NoAvailableTarget
        }
        self.target = target
        if pbxProj.buildConfigurations.count > 0 {
            self.buildSettings = pbxProj.buildConfigurations[0].buildSettings
        }
        target.buildPhases.forEach(analyse(phase:))
    }
    
    private func analyse(phase: PBXBuildPhase) {
        let srcRoot = Path(srcRootURL.path)
        guard let files = phase.files else {
            return
        }
        
        for file in files {
            guard let pbxFile = file.file else {
                continue
            }
            
            guard let fullPath = try? pbxFile.fullPath(sourceRoot: srcRoot) else {
                continue
            }
            
            if phase is PBXSourcesBuildPhase {
                // 若工程为 APP 工程，文件会被加入到 sources 中，为需要进行混淆的文件
                sources.insert(fullPath.url)
            } else {
                // 若工程为 framework 工程，对外暴露的文件会被加入到 publicHeaders 中，此部分文件不能进行混淆，其他文件会被加入到 internalHeaders 中，为需要进行混淆的文件
                if let settings = file.settings, let attributes = settings["ATTRIBUTES"] as? Array<String>, let attribute = attributes.first, attribute.contains("Public") {
                    publicHeaders.insert(fullPath.url)
                } else {
                    internalHeaders.insert(fullPath.url)
                }
            }
        }
    }
}
