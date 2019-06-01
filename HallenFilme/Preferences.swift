//
//  Preferences.swift
//  HallenFilme
//
//  Created by Andreas Pohl on 06.11.17.
//  Copyright © 2017 Andreas Pohl. All rights reserved.
//

import Foundation

struct Preferences {
    
    var raidUrlString: String {
        get {
            if let raidUrlString = UserDefaults.standard.string(forKey: "raidUrlString") {
                return raidUrlString
            } else {
                return "/Users/andreas/Documents/Movies"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "raidUrlString")
        }
    }
    
    var raidFailMessage: String {
        get {
            if let raidFailMessage = UserDefaults.standard.string(forKey: "raidFailMessage") {
                return raidFailMessage
            } else {
                return "RAID konnte nicht erreicht werden. Ist das Laufwerk eingeschaltet?"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "raidFailMessage")
        }
    }
    
    var halleUrlString: String {
        get {
            if let halleUrlString = UserDefaults.standard.string(forKey: "halleUrlString") {
                return halleUrlString
            } else {
                return "/Users/andreas/Documents/MoviesHalle"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "halleUrlString")
        }
    }
    
    var halleFailMessage: String {
        get {
            if let halleFailMessage = UserDefaults.standard.string(forKey: "halleFailMessage") {
                return halleFailMessage
            } else {
                return "Hallenkamera konnte nicht erreicht werden. Gib Deinem Mann ein Küsschen und flüstere ihm das ins Ohr!"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "halleFailMessage")
        }
    }
    
    var halleUser: String {
        get {
            if let halleUser = UserDefaults.standard.string(forKey: "halleUser") {
                return halleUser
            } else {
                return ""
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "halleUser")
        }
    }
    
    var hallePassword: String {
        get {
            if let hallePassword = UserDefaults.standard.string(forKey: "hallePassword") {
                return hallePassword
            } else {
                return ""
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hallePassword")
        }
    }
}
