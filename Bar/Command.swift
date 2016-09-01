//
//  Commands.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/27/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation
import Cocoa

class CommandFactory {
    static private let commandCreators = ["notify:": CommandFactory.createNotifyCommand,
                                          "ask:": CommandFactory.createAskCommand,
                                          "icon:": CommandFactory.createIconCommand]
    
    static func createFromLine(line: String, scriptsDir: String) -> Command? {
        for (prefix, handler) in commandCreators {
            if line.hasPrefix(prefix) {
                return handler(line, scriptsDir: scriptsDir)
            }
        }
        
        return createTextCommand(line, scriptsDir: scriptsDir)
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
        case "YES", "true", "1":
            return true
        default:
            return false
        }
    }
    
    // MARK: - Creators of different command types.
    static private func createTextCommand(line: String, scriptsDir: String) -> Command? {
        return TextCommand(line)
    }
    
    static private func createNotifyCommand(line: String, scriptsDir: String) -> Command? {
        let dict = splitToDictionary(line)
        let cmd = NotifyCommand()
        
        if let title = dict["notify"] {
            cmd.title = title
        }
        
        cmd.informativeText = dict["informativeText"]
        
        if let enable = dict["makeSound"] {
            cmd.makeSound = convertToBool(enable)
        }
        
        return cmd
    }
    
    static private func createAskCommand(line: String, scriptsDir: String) -> Command? {
        let dict = splitToDictionary(line)
        let cmd = AskCommand(scriptsDir: scriptsDir)
        
        if let title = dict["ask"] {
            cmd.title = title
        }
        
        cmd.informativeText = dict["informativeText"]
        
        if let protected = dict["protected"] {
            cmd.protected = convertToBool(protected)
        }
        
        return cmd
    }
    
    static private func createIconCommand(line: String, scriptsDir: String) -> Command? {
        let dict = splitToDictionary(line)
        if let imgString = dict["icon"] {
            let cmd = IconCommand(imagePath: imgString)
            if let width = dict["width"] {
                cmd.width = Int(width) ?? 0
            }
            
            if let height = dict["height"] {
                cmd.height = Int(height) ?? 0
            }
            
            return cmd
        }
        
        return nil
    }
}

// MARK: - Command documentation.
enum SupportedCommands {
    case Text
    case Notify
    case Ask
    case Icon
}

protocol Command {
    func type() -> SupportedCommands
    func run() -> Bool
}

// MARK: - Command implementations.
class TextCommand: Command {
    let text: String
    init(_ text: String) {
        self.text = text
    }
    
    func type() -> SupportedCommands {
        return .Text
    }
    
    func run() -> Bool {
        return false
    }
}

class NotifyCommand: Command {
    private var title = ""
    private var informativeText: String?
    private var makeSound = false
    
    func type() -> SupportedCommands {
        return .Notify
    }
    
    func run() -> Bool {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = informativeText
        
        if makeSound {
            notification.soundName = NSUserNotificationDefaultSoundName
        }
        
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        return true
    }
}

class AskCommand: Command {
    private var title = ""
    private var informativeText: String?
    private var protected = false
    
    private let scriptsDir: String
    private let outFifoName = "user_input_fifo"
    
    init(scriptsDir: String) {
        self.scriptsDir = scriptsDir
    }
    
    func type() -> SupportedCommands {
        return .Ask
    }
    
    func run() -> Bool {
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.addButtonWithTitle("Cancel")
        alert.messageText = title
        alert.informativeText = informativeText ?? ""
        alert.alertStyle = .InformationalAlertStyle
        
        let rect = NSMakeRect(0, 0, 250, 25)
        let input = protected ? NSSecureTextField(frame: rect) : NSTextField(frame: rect)
        alert.accessoryView = input

        let res = alert.runModal() == NSAlertFirstButtonReturn ? "OK" : "Cancel"
        let toWrite = "\(res):\(input.stringValue)"
        
        let fullPath = "\(scriptsDir)/\(outFifoName)"
        guard setupFifo(fullPath) else {
            return false
        }
        
        if let outFifo = NSFileHandle(forWritingAtPath: fullPath) {
            outFifo.writeData(toWrite.dataUsingEncoding(NSUTF8StringEncoding)!)
            return true
        }
        
        return false
    }
    
    private func setupFifo(path: String) -> Bool {
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            if !FifoHelper.createFifo(path) {
                NSLog("Failed to create fifo at '\(path)'")
                return false
            }
        }
        
        return FifoHelper.isFifo(path)
    }
}

class IconCommand: Command {
    private let imgPath: String
    var width = 0
    var height = 0
    
    init(imagePath: String) {
        imgPath = imagePath
    }
    
    func type() -> SupportedCommands {
        return .Icon
    }
    
    func run() -> Bool {
        return false
    }
    
    func image() -> NSImage? {
        if let img = NSImage(contentsOfFile: imgPath) {
            let imgWidth = width == 0 ? img.size.width : CGFloat(width)
            let imgHeight = height == 0 ? img.size.height : CGFloat(height)
            let size = NSSize(width: imgWidth, height: imgHeight)
            
            if size != img.size {
                img.size = size
            }
            
            return img
        }
        
        NSLog("Can't create image using URL: \(imgPath)")
        return nil
    }
}
