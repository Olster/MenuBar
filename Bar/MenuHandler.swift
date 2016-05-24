//
//  MenuHandler.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/21/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Cocoa
import Foundation

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
