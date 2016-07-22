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
    private let inputFifoName = "menubar_fifo"
    
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
        stop()
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
        guard setupFifo(statusFifoPath) else {
            NSLog("Failed to set up FIFO")
            return false
        }
        
        inputFifoHandle = NSFileHandle(forUpdatingAtPath: statusFifoPath)
        guard inputFifoHandle != nil else {
            NSLog("Can't open '\(statusFifoPath)'")
            return false
        }
        
        inputFifoHandle?.readabilityHandler = statusReadHandler
        scriptRunner.launch()
        
#if DEBUG
        print("Started bash PID \(scriptRunner.processIdentifier)")
#endif
        
        return true
    }
    
    func stop() {
        if scriptRunner.running {            
#if DEBUG
            print("Terminating bash PID \(scriptRunner.processIdentifier)")
#endif
            scriptRunner.terminate()
        }
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
            NSLog("\(inputFifoName) doesn't exist in \(pathToFolder). Creating fifo")
            
            if !FifoHelper.createFifo(path) {
                return false
            }
        }
        
        if !FifoHelper.isFifo(path) {
            NSLog("\(path) isn't a FIFO.")
            return false
        }
        
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
            delegate?.commandReceived(input)
        }
    }
}
