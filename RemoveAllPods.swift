#!/usr/bin/swift
//
//  RemoveAllPods.swift
//  Created by Dzmitry Sotnikov on 10.03.2022.
//

import Foundation

enum ANSIColor: String {

    typealias This = ANSIColor

    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case `default` = "\u{001B}[0;0m"

    static var values: [This] {
        return [.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white, .default]
    }

    static var names: [This: String] {
        return [
            .black: "black",
            .red: "red",
            .green: "green",
            .yellow: "yellow",
            .blue: "blue",
            .magenta: "magenta",
            .cyan: "cyan",
            .white: "white",
            .default: "default",
        ]
    }

    var name: String {
        return This.names[self] ?? "unknown"
    }

    static func + (lhs: This, rhs: String) -> String {
        return lhs.rawValue + rhs
    }

    static func + (lhs: String, rhs: This) -> String {
        return lhs + rhs.rawValue
    }

}

extension String {

    func colored(_ color: ANSIColor) -> String {
        return color + self + ANSIColor.default
    }

    var black: String {
        return colored(.black)
    }

    var red: String {
        return colored(.red)
    }

    var green: String {
        return colored(.green)
    }

    var yellow: String {
        return colored(.yellow)
    }

    var blue: String {
        return colored(.blue)
    }

    var magenta: String {
        return colored(.magenta)
    }

    var cyan: String {
        return colored(.cyan)
    }

    var white: String {
        return colored(.white)
    }

}

extension URL {
    func subDirectories() throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter(\.hasDirectoryPath)
    }
}

class RemoveAllPods : NSObject {

    let fileManager = FileManager.default
    var startDir : String = ""
    var projectsList : [String] = []

    init(startDir : String) {
        self.startDir = startDir
    }

    func run() {
        print("Creating directories list. Top directory:".colored(.green), self.startDir.colored(.default))
        createProjectsList(dir: self.startDir)
        print("Processed".colored(.green))
        print("")
        if projectsList.count > 0 {
            print("Found \(projectsList.count) projects with pods installed".colored(.green))
            print("")
            projectsList.forEach {
                print("Process deintegrate for: ".colored(.blue), $0.colored(.default))
                if
                    fileManager.changeCurrentDirectoryPath($0),
                    let _ = try? safeShell("pod deintegrate")
                {
                    print("*********".green)
                } else {
                    print("************************************************".colored(.cyan))
                    print("Start deintegrate failure for: ".colored(.red), $0.colored(.default))
                }
            }
        } else {
            print("No one project with pods installed found".colored(.red))
        }
    }

    func safeShell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")

        try task.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }

    func createProjectsList(dir: String) {
        if let url = URL(string: dir), let subDirs = try? url.subDirectories() {
            subDirs.forEach {
                if fileManager.fileExists(atPath: $0.path + "/Pods") {
                    self.projectsList.append($0.path)
                }
                createProjectsList(dir: $0.path)
            }
        }
    }

}

// app start

print("************************************************************".colored(.yellow))
print("******** ALL PODS DEINTEGRATE IN ALL SUBDIRECTORIES ********".colored(.yellow))
print("************************************************************".colored(.yellow))
print("")
let arguments = CommandLine.arguments
if arguments.count > 1 {
    print("Start directory: ".colored(.yellow), arguments[1].colored(.green))
    RemoveAllPods(startDir: arguments[1]).run()
} else {
    print("Use current directory for start: ".colored(.yellow), FileManager.default.currentDirectoryPath.colored(.green))
    RemoveAllPods(startDir: FileManager.default.currentDirectoryPath).run()
}
print("")
print("************************************************************".colored(.yellow))
print("************************** END *****************************".colored(.yellow))
print("************************************************************".colored(.yellow))
print("")
