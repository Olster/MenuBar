//
//  StatusTextProvider.swift
//  Bar
//
//  Created by Pavlo Denysiuk on 4/20/16.
//  Copyright © 2016 Pavlo Denysiuk. All rights reserved.
//

import Foundation

protocol CommandProviderDelegate {
    func commandReceived(text: String)
}

class CommandProvider {
    private let scriptName = "default.sh"
    private let inputFifoName = "appStatus"
    
    private let scriptRunner = NSTask()
    private let pathToFolder: String
    
    private var inputFifoHandle: NSFileHandle?
    
    var delegate: CommandProviderDelegate?
    
    var scriptPID: Int32 {
        return scriptRunner.processIdentifier
    }
    
    init(pathToFolder: String) {
        self.pathToFolder = pathToFolder
        print("Setting task path: \(pathToFolder)")
        scriptRunner.currentDirectoryPath = pathToFolder
        scriptRunner.launchPath = "/bin/bash"
    }
    
    deinit {
        scriptRunner.terminate()
    }
    
    func start() -> Bool {
        // Set up script runner.
        let script = String(format: "%@/%@", pathToFolder, scriptName)
        guard setupScript(script) else {
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
    
    private func setupScript(path: String) -> Bool {
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            NSLog("default.sh doesn't exist in '\(path)'. Copying from resources.")
            
            guard let defaultScript = NSBundle.mainBundle().pathForResource("default", ofType: "sh") else {
                NSLog("No default.sh in resources")
                return false
            }
            
            do {
                try NSFileManager.defaultManager().copyItemAtPath(defaultScript, toPath: path)
            } catch {
                NSLog("Can't copy default script: \(error)")
                return false
            }
        }
        
        return true
    }
    
    private func setupFifo(path: String) -> Bool {
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            NSLog("\(inputFifoName) doesn't exist in \(pathToFolder). Can't start task")
            return false
        }
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
            delegate?.commandReceived(input)
        }
    }
    
    // MARK: - FIFO related.
    private func isFifo(path: String) -> Bool {
        guard let handle = NSFileHandle(forReadingAtPath: path) else {
            let fn = #function
            NSLog("\(fn): 'path' does not exist")
            return false
        }
        
        let ret = isFifo(handle.fileDescriptor)
        handle.closeFile()
        return ret
    }
    
    private func isFifo(descriptor: Int32) -> Bool {
        var statPtr = stat()
        guard fstat(descriptor, &statPtr) == 0 else {
            NSLog("fstat failed: \(errno)")
            return false
        }
        
        return (statPtr.st_mode & S_IFIFO) == 1
    }
}
