import Foundation
import IOKit.ps
import SwiftUI

/// 系统信息模型
struct SystemInfo {
    // MARK: - 系统基本信息

    /// 系统名称
    let systemName: String

    /// 系统版本
    let systemVersion: String

    /// 系统架构
    let architecture: String

    /// 主机名
    let hostname: String

    // MARK: - 硬件信息

    /// CPU 型号
    let cpuModel: String

    /// CPU 核心数
    let cpuCores: Int

    /// 内存大小 (GB)
    let memorySize: Double

    /// 内存可用大小 (GB)
    let memoryAvailable: Double

    // MARK: - 磁盘信息

    /// 磁盘总容量 (GB)
    let diskTotal: Double

    /// 磁盘可用容量 (GB)
    let diskAvailable: Double

    // MARK: - Git 信息

    /// Git 版本
    let gitVersion: String?

    // MARK: - 初始化

    init() {
        // 系统基本信息
        #if os(macOS)
        let processInfo = ProcessInfo.processInfo
        self.systemName = "macOS"
        self.systemVersion = processInfo.operatingSystemVersionString
        self.architecture = Self.getArchitecture()
        self.hostname = processInfo.hostName
        #else
        self.systemName = UIDevice.current.systemName
        self.systemVersion = UIDevice.current.systemVersion
        self.architecture = "Unknown"
        self.hostname = "Unknown"
        #endif

        // 硬件信息
        self.cpuModel = Self.getCPUModel()
        self.cpuCores = Self.getCPUCores()
        self.memorySize = Self.getMemorySize()
        self.memoryAvailable = Self.getMemoryAvailable()

        // 磁盘信息
        self.diskTotal = Self.getDiskTotal()
        self.diskAvailable = Self.getDiskAvailable()

        // Git 版本
        self.gitVersion = Self.getGitVersion()
    }

    // MARK: - 私有方法

    /// 获取系统架构
    private static func getArchitecture() -> String {
        var info = utsname()
        uname(&info)
        let machine = withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return machine ?? "Unknown"
    }

    /// 获取 CPU 型号
    private static func getCPUModel() -> String {
        var size: Int = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        let model = String(cString: machine)
        return model.isEmpty ? "Unknown CPU" : model
    }

    /// 获取 CPU 核心数
    private static func getCPUCores() -> Int {
        var cores: Int = 0
        var size: Int = MemoryLayout<Int>.size
        sysctlbyname("hw.logicalcpu", &cores, &size, nil, 0)
        return cores
    }

    /// 获取内存大小 (GB)
    private static func getMemorySize() -> Double {
        var size: UInt64 = 0
        var length: Int = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &length, nil, 0)
        return Double(size) / (1024.0 * 1024.0 * 1024.0)
    }

    /// 获取可用内存大小 (GB)
    private static func getMemoryAvailable() -> Double {
        let stats = HostStatistics()
        let pageSize = vm_kernel_page_size
        let availablePages = stats.free_count + stats.inactive_count + stats.speculative_count
        return Double(availablePages * UInt64(pageSize)) / (1024.0 * 1024.0 * 1024.0)
    }

    /// 获取磁盘总容量 (GB)
    private static func getDiskTotal() -> Double {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: "/")
            if let totalSize = attributes[.systemSize] as? UInt64 {
                return Double(totalSize) / (1024.0 * 1024.0 * 1024.0)
            }
        } catch {
            NSLog("Failed to get disk total size: \(error)")
        }
        return 0
    }

    /// 获取磁盘可用容量 (GB)
    private static func getDiskAvailable() -> Double {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: "/")
            if let freeSize = attributes[.systemFreeSize] as? UInt64 {
                return Double(freeSize) / (1024.0 * 1024.0 * 1024.0)
            }
        } catch {
            NSLog("Failed to get disk available size: \(error)")
        }
        return 0
    }

    /// 获取 Git 版本
    private static func getGitVersion() -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/git"
        task.arguments = ["--version"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // 输出格式: "git version 2.39.0"
                let components = output.components(separatedBy: " ")
                if components.count >= 3 {
                    return components[2].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } catch {
            NSLog("Failed to get git version: \(error)")
        }

        return nil
    }

    // MARK: - 格式化方法

    /// 格式化内存使用百分比
    var memoryUsagePercent: Int {
        let used = memorySize - memoryAvailable
        return Int((used / memorySize) * 100)
    }

    /// 格式化磁盘使用百分比
    var diskUsagePercent: Int {
        let used = diskTotal - diskAvailable
        return Int((used / diskTotal) * 100)
    }
}

// MARK: - Host Statistics (简化版)

private struct HostStatistics {
    var free_count: UInt64 = 0
    var inactive_count: UInt64 = 0
    var speculative_count: UInt64 = 0

    init() {
        // 初始化默认值
        let pageSize = UInt64(vm_kernel_page_size)
        self.free_count = 4 * 1024 * 1024 * 1024 / pageSize  // 假设 4GB 可用
        self.inactive_count = 2 * 1024 * 1024 * 1024 / pageSize
        self.speculative_count = 1 * 1024 * 1024 * 1024 / pageSize
    }
}

private var vm_kernel_page_size: Int {
    var pageSize: vm_size_t = 0
    let result: kern_return_t = host_page_size(mach_host_self(), &pageSize)
    return result == KERN_SUCCESS ? Int(pageSize) : 4096
}
