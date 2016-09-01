//
//  MenuHandler.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/21/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa
import Foundation

protocol MenuDelegate {
    func onRestartScript()
    func onRescanMenu()
    func onQuit()
}

class Menu: NSObject {
    private(set) var menu = NSMenu()
    private let scriptsDir: NSURL
    var delegate: MenuDelegate?
    var customMenus: [MenuFileInfo]?
    
    init(scriptsDir: NSURL) {
        self.scriptsDir = scriptsDir
        super.init()
    }
    
    func dump() -> String {
        let menusUrl = scriptsDir.URLByAppendingPathComponent("menus", isDirectory: true)
        return MenuFileInfo.createFrom(menusUrl)?.map {"\($0)"}.joinWithSeparator("\n\t") ?? "NONE"
    }
    
    func cleanUp() {
        if customMenus != nil {
            for m in customMenus! {
                m.cleanUp()
            }
            
            customMenus = nil
        }
        
        menu = NSMenu()
    }
    
    func setUpMenus() {
        // Open scripts dir
        let scriptItem = NSMenuItem(title: "Open scripts dir", action: #selector(onOpenScriptsDir), keyEquivalent: "")
        scriptItem.target = self
        menu.addItem(scriptItem)
        
        // Restart script.
        let restartScriptItem = NSMenuItem(title: "Restart script", action: #selector(onRestartScript), keyEquivalent: "")
        restartScriptItem.target = self
        menu.addItem(restartScriptItem)
        
        // Rescan menus
        let rescanMenus = NSMenuItem(title: "Recan custom menus", action: #selector(onRescanMenus), keyEquivalent: "")
        rescanMenus.target = self
        menu.addItem(rescanMenus)
        menu.addItem(NSMenuItem.separatorItem())
        
        // Add menus from folder.
        // TODO: Move outside of initializer.
        setUpCustomMenus()
        
        // Quit item
        menu.addItem(NSMenuItem.separatorItem())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(onQuit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    private func setUpCustomMenus() {
        let menusUrl = scriptsDir.URLByAppendingPathComponent("menus", isDirectory: true)
        customMenus = MenuFileInfo.createFrom(menusUrl)
        if customMenus != nil {
            addMenus(menu, menus: customMenus!)
        }
    }
    
    private func addMenus(addTo: NSMenu, menus: [MenuFileInfo]) {
        for m in menus {
            let item = NSMenuItem(title: m.name, action: #selector(m.handleMenu), keyEquivalent: "")
            item.target = m
            
            addTo.addItem(item)
            
            if m.submenus != nil {
                let newMenu = NSMenu()
                addMenus(newMenu, menus: m.submenus!)
                item.submenu = newMenu
            }
        }
    }
    
    @objc private func onRestartScript() {
        delegate?.onRestartScript()
    }
    
    @objc private func onRescanMenus() {
        delegate?.onRescanMenu()
    }
    
    @objc private func onOpenScriptsDir() {
        NSWorkspace.sharedWorkspace().openURL(scriptsDir)
    }
    
    @objc private func onQuit() {
        delegate?.onQuit()
    }
}

class MenuFileInfo: NSObject {
    let name: String
    let isDirectory: Bool
    let URLPath: NSURL
    let isReadable: Bool
    var submenus: [MenuFileInfo]?
    
    var runner = NSTask()
    
    static func createFrom(path: NSURL) -> [MenuFileInfo]? {
        if !NSFileManager.defaultManager().fileExistsAtPath(path.path!) {
            return nil
        }
        
        var descriptions = [MenuFileInfo]()
        
        let properties = [NSURLNameKey, NSURLIsDirectoryKey, NSURLPathKey, NSURLIsReadableKey]
        if let enumerator = NSFileManager.defaultManager().enumeratorAtURL(path, includingPropertiesForKeys: properties, options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants], errorHandler: enumeratorErrorHandler) {
            for case let fileURL as NSURL in enumerator {
                guard let resValues = try? fileURL.resourceValuesForKeys(properties),
                    let isDir = resValues[NSURLIsDirectoryKey] as? Bool,
                    let name = resValues[NSURLNameKey] as? String,
                    let path = resValues[NSURLPathKey] as? String,
                    let isReadable = resValues[NSURLIsReadableKey] as? Bool
                    else {
                        continue
                }
                
                let fileInfo = MenuFileInfo(name: name, isDir: isDir, url: NSURL(fileURLWithPath: path), isReadable: isReadable)
                if isDir {
                    fileInfo.submenus = createFrom(NSURL(fileURLWithPath: path))
                }
                
                descriptions.append(fileInfo)
            }
            
            return descriptions
        }
        
        return nil
    }
    
    static private func enumeratorErrorHandler(url: NSURL, err: NSError) -> Bool {
        NSLog("Error enumerating \(url): \(err)")
        return true
    }
    
    override var description: String {
        var str = ""
        if submenus != nil {
            str = "\n\tSubmenus:\n\t" + submenus!.map {"\($0)"}.joinWithSeparator("\n\t")
        }
        
        return "Name: \(name), isDir: \(isDirectory), path: \(URLPath.path!), isReadable: \(isReadable)\(str)"
    }
    
    init(name: String, isDir: Bool, url: NSURL, isReadable: Bool) {
        self.name = name
        isDirectory = isDir
        URLPath = url
        self.isReadable = isReadable
        super.init()
    }
    
    deinit {
        cleanUp()
    }
    
    func cleanUp() {
        if runner.running {
            runner.terminate()
        }
        
        if submenus != nil {
            for menu in submenus! {
                menu.cleanUp()
            }
            
            submenus = nil
        }
    }
    
    @objc private func handleMenu() {
        #if DEBUG
        NSLog("Starting \(URLPath.path!)")
        #endif
        
        // Dispatching to another queue for possible long operations. Otherwise the app would
        // appear to be hanging.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if self.runner.running {
                self.runner.terminate()
            }
            
            self.runner = NSTask()
            self.runner.arguments = [self.URLPath.path!]
            self.runner.launchPath = "/bin/bash"
            self.runner.currentDirectoryPath = self.URLPath.URLByDeletingLastPathComponent!.path!
            
            let stdout = NSPipe()
            self.runner.standardOutput = stdout
            self.runner.standardError = stdout
            stdout.fileHandleForReading.readabilityHandler = self.menuOutHandler
            self.runner.launch()
            self.runner.waitUntilExit()
            
            stdout.fileHandleForReading.readabilityHandler = nil
        }
    }
    
    private func menuOutHandler(handle: NSFileHandle) {
        if let out = String(data: handle.availableData, encoding: NSUTF8StringEncoding) {
            NSLog("Menu script out/err: " + out)
        }
    }
}
