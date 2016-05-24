//
//  Commands.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/27/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation

// Specification of commands:
// General description:
// command:argument\targ1Name:arg1
//
// command - name of supported commands
// argument - argument for a command
// Optional:
// arg1Name - name of the first argument
// arg1 - first argument
// There can be as many arguments as needed, all of them must be separated by '\v' character
class CommandFactory {
    static private let commandCreators = ["notify:": CommandFactory.createNotifyCommand,
                                          "ask:": CommandFactory.createAskCommand]
    
    static func createFromLine(line: String) -> Command? {
        for (prefix, handler) in commandCreators {
            if line.hasPrefix(prefix) {
                return handler(line)
            }
        }
        
        return createTextCommand(line)
    }
    
    static private func splitToDictionary(input: String) -> [String: String] {
        let lines = input.componentsSeparatedByString("\t")
        var out = [String: String]()
        
        for line in lines {
            if let sep = line.rangeOfString(":") {
                let first = line.substringToIndex(sep.startIndex).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let second = line.substringFromIndex(sep.endIndex).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                
                out[first] = second
            } else {
                NSLog("Warning: line without argument name: \(line)")
            }
        }
        
        return out
    }
    
    static private func convertToBool(str: String) -> Bool {        
        switch str {
        case "YES", "true", "1", "+":
            return true
        default:
            return false
        }
    }
    
    static private func createTextCommand(line: String) -> Command? {
        return Command(line)
    }
    
    static private func createNotifyCommand(line: String) -> Command? {
        let dict = splitToDictionary(line)
        let cmd = NotifyCommand(line)
        
        if let title = dict["notify"] {
            cmd.title = title
        }
        
        cmd.informativeText = dict["informativeText"]
        
        if let enable = dict["makeSound"] {
            cmd.makeSound = convertToBool(enable)
        }
        
        return cmd
    }
    
    static private func createAskCommand(line: String) -> Command? {
        let dict = splitToDictionary(line)
        
        let cmd = AskCommand(line)
        
        if let title = dict["ask"] {
            cmd.title = title
        }
        
        cmd.informativeText = dict["informativeText"]
        
        if let protected = dict["protected"] {
            cmd.protected = convertToBool(protected)
        }
        
        return cmd
    }
}

class Command {
    var text: String
    
    enum SupportedCommands {
        case Notify
        case Ask
        case Text
    }
    
    init(_ text: String) {
        self.text = text
    }
    
    // Must be overriden by subclasses.
    func type() -> SupportedCommands {
        return .Text
    }
}

class NotifyCommand: Command {
    var title = ""
    var informativeText: String?
    var makeSound = false
    
    override func type() -> Command.SupportedCommands {
        return .Notify
    }
}

class AskCommand: Command {
    var title = ""
    var informativeText: String?
    var protected = false
    
    override func type() -> Command.SupportedCommands {
        return .Ask
    }
}
