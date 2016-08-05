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
        
        // Quit item
        menu.addItem(NSMenuItem.separatorItem())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(Menu.onQuit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
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