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
    func onQuit()
}

class Menu: NSObject {
    let menu = NSMenu()
    private let scriptsDir: NSURL
    var delegate: MenuDelegate?
    
    init(scriptsDir: NSURL) {
        self.scriptsDir = scriptsDir
        super.init()
        
        // Open scripts dir
        let scriptItem = NSMenuItem(title: "Open scripts dir", action: #selector(onOpenScriptsDir), keyEquivalent: "")
        scriptItem.target = self
        menu.addItem(scriptItem)
        
        // Restart script.
        let restartScriptItem = NSMenuItem(title: "Restart script", action: #selector(onRestartScript), keyEquivalent: "")
        restartScriptItem.target = self
        menu.addItem(restartScriptItem)
        menu.addItem(NSMenuItem.separatorItem())
        
        // Add menus from folder.
        // TODO: Move outside of initializer.
        setUpCustomMenus()
        
        // Quit item
        menu.addItem(NSMenuItem.separatorItem())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(Menu.onQuit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    func dump() -> String {
        let menusUrl = scriptsDir.URLByAppendingPathComponent("menus", isDirectory: true)
        return MenuFileInfo.createFrom(menusUrl)?.map {"\($0)"}.joinWithSeparator("\n\t") ?? "NONE"
    }
    
    private func setUpCustomMenus() {
        let menusUrl = scriptsDir.URLByAppendingPathComponent("menus", isDirectory: true)
        if let menus = MenuFileInfo.createFrom(menusUrl) {
            addMenus(menu, menus: menus)
        }
    }
    
    private func addMenus(addTo: NSMenu, menus: [MenuFileInfo]) {
        for m in menus {
            let item = NSMenuItem(title: m.name, action: nil, keyEquivalent: "")
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
    
    @objc private func onOpenScriptsDir() {
        NSWorkspace.sharedWorkspace().openURL(scriptsDir)
    }
    
    @objc private func onQuit() {
        print("Quitting")
        delegate?.onQuit()
    }
}

class MenuFileInfo: CustomStringConvertible {
    let name: String
    let isDirectory: Bool
    let URLPath: NSURL
    let isReadable: Bool
    var submenus: [MenuFileInfo]?
    
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
    
    var description: String {
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
    }
}

/*
class MenuHandler: NSObject {
    private var pathToFolder: String
    var menu: NSMenu
    
    var itemHandler = [Int: String]()
    let startingTag = 1
    var lastTag: Int
    
    init(pathToFolder: String, menu: NSMenu) {
        self.pathToFolder = pathToFolder
        self.menu = menu
        
        lastTag = startingTag
    }
    
    func walkDir() {
        let dirToWalk = pathToFolder + "/menu"
        guard NSFileManager.defaultManager().fileExistsAtPath(dirToWalk) else {
            NSLog("Directory '\(dirToWalk)' doesn't exist")
            return
        }
        
        let enumerator = NSFileManager.defaultManager().enumeratorAtPath(dirToWalk)
        while let fileName = enumerator?.nextObject() as? String {
            
            // Skip directories.
            if let val = enumerator?.fileAttributes?[NSFileType] as? String {
                if val == NSFileTypeDirectory {
                    continue
                }
            }
            
            var menuItemTitle = fileName
            if fileName.hasSuffix(".sh") {
                let index = fileName.endIndex.advancedBy(-3)
                menuItemTitle = fileName.substringToIndex(index)
            }
            
            let selector = #selector(MenuHandler.itemAction(_:))
            let item = NSMenuItem(title: menuItemTitle, action: selector, keyEquivalent: "")
            item.tag = lastTag
            item.target = self
            
            menu.addItem(item)
            
            let path = dirToWalk + "/" + fileName
            itemHandler[lastTag] = path
            lastTag += 1
        }
    }
    
    func dump() {
        print(itemHandler)
    }
    
    func itemAction(sender: NSMenuItem) {
        if let handler = itemHandler[sender.tag] {
            print(handler)
        }
    }
}
*/