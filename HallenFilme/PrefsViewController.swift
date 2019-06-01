//
//  PrefsViewController.swift
//  HallenFilme
//
//  Created by Andreas Pohl on 06.11.17.
//  Copyright © 2017 Andreas Pohl. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {

    @IBOutlet weak var raidUrlPref: NSTextField!
    @IBOutlet weak var raidFailMessage: NSTextField!
    
    @IBOutlet weak var halleUrlPref: NSTextField!
    @IBOutlet weak var halleFailMessage: NSTextField!
    
    @IBOutlet weak var halleUser: NSTextField!
    @IBOutlet weak var hallePassword: NSSecureTextField!
    
    var prefs = Preferences()
    
    @IBAction func raidUrlChanged(_ sender: Any) {
        prefs.raidUrlString = raidUrlPref.stringValue
        NotificationCenter.default.post(name: Notification.Name(rawValue: "raidUrlChanged"), object: nil)
    }
    
    @IBAction func raidFailMsgChanged(_ sender: Any) {
        prefs.raidFailMessage = raidFailMessage.stringValue
    }

    @IBAction func halleUrlChanged(_ sender: Any) {
        prefs.halleUrlString = halleUrlPref.stringValue
        NotificationCenter.default.post(name: Notification.Name(rawValue: "halleUrlChanged"), object: nil)
    }
    
    @IBAction func halleFailMsgChanged(_ sender: Any) {
        prefs.halleFailMessage = halleFailMessage.stringValue
    }
    
    @IBAction func halleUserChanged(_ sender: Any) {
        prefs.halleUser = halleUser.stringValue
    }
    
    @IBAction func hallePasswordChanged(_ sender: Any) {
        prefs.hallePassword = hallePassword.stringValue
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showExistingPrefs()
    }
    
    func showExistingPrefs() {
        raidUrlPref.stringValue = prefs.raidUrlString
        raidFailMessage.stringValue = prefs.raidFailMessage
        
        halleUrlPref.stringValue = prefs.halleUrlString
        halleFailMessage.stringValue = prefs.halleFailMessage
        
        halleUser.stringValue = prefs.halleUser
        hallePassword.stringValue = prefs.hallePassword
    }
}
