---
title: HomuraObfuscator 说明文档
type: HomuraObfuscator 说明文档
order: 0
---

# 概述

`HomuraObfuscator` 是用于对 `OC/C/C++` 的类名、方法名进行混淆的工具。

# 环境依赖

## 安装 `llvm`

```shell
brew install --build-from-source llvm
```

安装过程中可能需要科学上网，若出现 Failed to connect to raw.githubusercontent.com port 443: Connection refused 问题，可以先到 [https://www.ipaddress.com/](https://www.ipaddress.com/) 查询 raw.githubusercontent.com 对应的 ip，然后修改 hosts 文件，如，可在 hosts 文件中添加

```
199.232.96.133 raw.githubusercontent.com
```

`llvm` 安装成功之后，`cd` 到 `HomuraObfuscator` 目录，执行如下命令：

```shell
sudo swift utils/make-pkgconfig.swift
```

配置环境变量，打开 `~/.bash_profile` 文件，添加 `llvm` 路径：

```
# llvm
export PATH="/usr/local/opt/llvm/bin:${PATH}"
```

# 使用说明

## 使用方法

打开工程(本工程为 `macOS` 的 `Command Line Tool` 工程)后，找到 `main.swift` 文件中的 `parse` 方法，修改 `project` 为需要混淆的工程路径，修改 `target` 为 `project` 的 `target`，修改混淆后的文件存储路径(此处，建议新建一个 `.h` 文件，在工程的 `pch` 中导入该 `.h` 文件，再执行 `HomuraObfuscator` 即可实现混淆功能)，运行工程，待控制台中出现 `stop analyse` 即表示混淆结束。

```swift
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
```

**<font color="Red" >注意：此处为了调试方便，故使用 `macOS` 的 `Command Line Tool` 工程，调试通过之后，可新建 `Swift Package` 工程，然后将代码挪到工程中，后续直接在终端使用命令行完成混淆，当然，直接对 `Command Line Tool` 工程进行 `archive` 生成对应的工具，配置好环境变量，也可以实现直接在命令行通过命令完成混淆。</font>**

**<font color="Red" >注意：本工具依赖 `llvm`，若还未安装 `llvm`，请先通过 `Homebrew` 安装 `llvm`，在控制台中输入 `brew install llvm` 即可安装。</font>**

## 使用注意事项

1. 建议本工具只用于 SDK 的混淆，不建议用于 APP 的混淆

2. 对于工程中引用到的所有系统库，一定要将其写到 `HOObf.swift` 的 `systemSymbol` 中，以便排除对系统库中类名、方法名的混淆
    
    ```swift
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
    ```

3. 若工程中的类名、方法名与三方的 `.framework` 或者 `.a` 中的类名、方法名相同时，一定要将其添加到 `HOObf.swift` 的 `specifiedSymbols` 中，以便排除与三方库中类名、方法名同名的混淆，自动排除与三方库中类名、方法名同名的混淆功能需继续开发

    ```swift
    // 名称与三方库方法名、类名相同时，需要剔除(对于这种情况，需要有更好的解决方案)
    private lazy var specifiedSymbols: Set<String> = {
        return [
            "appSecret"
        ]
    }()
    ```
4. 若需要排除指定目录下所有文件的混淆，请在 `HOObf.swift` 的 `specifiedDirs` 中添加目录名

    ```swift
    // 指定目录
    private lazy var specifiedDirs: [String] = {
        return [
            "ThirdLibrary",
            "Pods"
        ]
    }()
    ```

5. 对于 `APP` 的混淆，若有 `UIViewController` 对应的 `xib` 在 `main.storyboard` 中，需要在 `HOObf.swift` 的 `xibFiles` 中添加对应类名

    ```swift
    // 带有 xib 的 ViewController 和 View 不能混淆，在 Main.storyboard 中的 xib 名称需要加到此处，若是单独的 xib，不用在此添加，程序会自动识别
    private lazy var xibFiles: Set<String> = {
        return [
            "ViewController"
        ]
    }()
    ```
    
**<font color="Red" >注意：本工具只在简单的 `APP` 中做过验证，但是已在公司核心 `SDK` 产品中进行了验证，故只建议用于 `SDK` 的混淆，不建议用于 `APP` 的混淆。</font>**

# 原理解析

本工具包含以下 4 个主要模块：

1. 命令行参数解析模块(直接使用 `Command Line Tool` 完成混淆时，可无需关注该模块)

2. `Xcode` 工程解析模块

3.  `Clang Translation Util` 模块 

4. 混淆模块   

## 命令行参数解析模块

该模块用于解析命令行混淆命令后携带的参数，使用命令行时，具体格式如下：

`swift run HomuraObfuscator [args]`

如：

```
swift run HomuraObfuscator -p=/Users/noctis/Downloads/OneLogin/OneLoginSDK/OneLoginSDK.xcodeproj -t=OneLoginSDK -o=/Users/noctis/Downloads/OneLogin/OneLoginSDK/OneLoginSDK/OLObfHeader.h
```

**<font color="Red" >注意：本工具不支持命令行形式解析，若要支持命令行，根据代码稍作改动即可。</font>**


## `Xcode` 工程解析模块

该模块用于解析 `Xcode` 工程，获取 `Xcode` 工程中所有的 `.h`、`.m`、`.mm`、`.c`、`.cpp` 文件，方便后续使用 `clang` 进行解析。

```swift
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
```

## `Clang Translation Util` 模块及混淆模块

该模块用于解析具体的源码文件，并得到类名、方法名、属性名、协议名，拿到名称后，即可进行混淆。本工具的混淆方法是：将需要混淆的字符串替换为随机字符串，随机字符串通过内置单词库生成，避免将字符串混淆为太过无意义的字符串而导致提交 `APP Store` 审核受阻。具体解析混淆逻辑可参考工程代码 `HOObf.swift` 的 `analyse` 方法。

以下说明混淆过程中需要注意的情况：

1. 一定要过滤掉系统库中的符号，对于工程中引用到的所有系统库，一定要将其写到 `HOObf.swift` 的 `systemSymbol` 中，以便排除对系统库中类名、方法名的混淆

2. `setter` 和 `getter` 方法不要轻易混淆，`getter` 方法名一般与 `property` 属性名一致，若将 `getter` 方法名进行了混淆，在具体的方法实现中，会出现找不到对应符号的错误

3. 初始化方法，以 `initWith` 开头的方法名，混淆之后，也要以 `initWith` 开头

4. 方法名中含有与 `property` 属性名相同的符号时，含有与 `C` 变量同名的符号时，不要混淆

5. 有对应 `xib` 文件的 `UIViewController` 和 `UIView` 不要混淆，比如，若 `xib` 中有一个 `UIButton` 在 `UIViewController` 中有对应的 `action`，这时，由于 `UIViewController` 中的 `action` 进行了混淆，而 `xib` 中的 `action` 是没有混淆的，那么在点击该按钮时，就会由于找不到 `action` 导致 `crash`

6. 工程中与三方 `framework` 或者 `.a` 同名的类名、方法名不能混淆

7. `CocoaPods` 等三方源码建议不要混淆

8. 其他未考虑到情况，待补充

**<font color="Red" >注意：混淆之后生成的 `.h` 文件一定要做好版本对应与备份，方便线上发生 `crash` 后能快速定位到具体位置。</font>**
