//
//  Movie.swift
//  HallenFilme
//
//  Created by Andreas Pohl on 16.10.17.
//  Copyright © 2017 Andreas Pohl. All rights reserved.
//

import Foundation

// represents a movie

class Movie: NSObject {
    
    var url: URL
    var name: String
    var category: String
    
    private var path: URL
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.path = url.deletingLastPathComponent()
                
        if (self.path.path == self.url.baseURL!.path) {
            self.category = "" // movie is in top folder, therefore no (or 'new') category
        } else {
            self.category = path.lastPathComponent
        }
    }
    
    
    // changes the category of a movie by moving it to the given directory
    // an empty category means top directory
    func setCategory(to toCategory: String) {
        var toUrl: URL = self.url.baseURL!
        toUrl = toUrl.appendingPathComponent(toCategory).appendingPathComponent(self.name)
        
        do {
            try FileManager().moveItem(at: self.url, to: toUrl)
        }
        
        catch {
            print(error.localizedDescription)
        }
    }
    
    // copies the movie to another URL
    func copy(to toURL: URL) {
        let atUrl = URL(fileURLWithPath: self.url.path)
        var toFileUrl = URL(fileURLWithPath: toURL.absoluteString, isDirectory: true)
        toFileUrl = toFileUrl.appendingPathComponent(self.name)

        do {
            try FileManager().copyItem(at: atUrl, to: toFileUrl)
        }
        
        catch {
            print(error.localizedDescription)
        }
    }
    
    // deletes the movie, returns true if successful
    func delete() -> Bool {
        do {
            try FileManager().removeItem(at: self.url)
            return true
        }
        catch {
            print (error.localizedDescription)
            return false
        }
    }
    
}
