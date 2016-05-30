//
//  StatusTextProvider.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/20/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation

protocol StatusTextReceiver {
    func textDidUpdate(text: String)
}

class StatusTextProvider {
    let scriptName = "default.sh"
    let inputFifoName = "appStatus"
    
    var delegate: StatusTextReceiver?
    let scriptRunner = NSTask()
    let pathToFolder: String
    
    var inputFifoHandle: NSFileHandle?
    
    var scriptPID: Int32 {
        return scriptRunner.processIdentifier
    }
    
    init(pathToFolder: String) {
        self.pathToFolder = pathToFolder
        
        if !NSFileManager.defaultManager().fileExistsAtPath(pathToFolder) {
            NSLog("Path to resource folder is invalid: '\(pathToFolder)'")
            return
        }
        
        print("Setting task path: " + pathToFolder)
        scriptRunner.currentDirectoryPath = pathToFolder
        scriptRunner.launchPath = "/bin/bash"
    }
    
    deinit {
        scriptRunner.terminate()
    }
    
    func setTextReceiver(obj: StatusTextReceiver) {
        delegate = obj
    }
    
    func start() -> Bool {
        // Set up script runner.
        let script = String(format: "%@/%@", pathToFolder, scriptName)
        guard NSFileManager.defaultManager().fileExistsAtPath(script) else {
            NSLog("default.sh doesn't exist in \(script). Can't start task")
            return false
        }
        
        scriptRunner.arguments = [script]
        
        let outPipe = NSPipe()
        let errPipe = NSPipe()
        
        scriptRunner.standardOutput = outPipe
        scriptRunner.standardError = errPipe
        
        outPipe.fileHandleForReading.readabilityHandler = outReadHandler
        errPipe.fileHandleForReading.readabilityHandler = errReadHandler
        
        // Set up fifo.
        let statusFifoPath = String(format: "%@/%@", pathToFolder, inputFifoName)
        guard NSFileManager.defaultManager().fileExistsAtPath(statusFifoPath) else {
            NSLog("\(inputFifoName) doesn't exist in \(pathToFolder). Can't start task")
            return false
        }
        
        inputFifoHandle = NSFileHandle(forUpdatingAtPath: statusFifoPath)
        guard inputFifoHandle != nil else {
            NSLog("Can't open '\(statusFifoPath)'")
            return false
        }
        
        inputFifoHandle?.readabilityHandler = statusReadHandler
        scriptRunner.launch()
        return true
    }
    
    private func outReadHandler(handle: NSFileHandle) {
        if let out = String(data: handle.availableData, encoding: NSUTF8StringEncoding) {
            NSLog("Script out: " + out)
        }
    }
    
    private func errReadHandler(handle: NSFileHandle) {
        if let out = String(data: handle.availableData, encoding: NSUTF8StringEncoding) {
            NSLog("Script err: " + out)
        }
    }
    
    private func statusReadHandler(handle: NSFileHandle) {
        if let input = String(data: handle.availableData, encoding: NSUTF8StringEncoding) {
            delegate?.textDidUpdate(input)
        }
    }
}