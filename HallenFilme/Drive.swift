//
//  Drive.swift
//  HallenFilme
//
//  Created by Andreas Pohl on 15.10.17.
//  Copyright © 2017 Andreas Pohl. All rights reserved.
//

import Foundation
import AppKit
import NetFS

// access point for a location on a drive
// used for 'halle' and 'raid'

class Drive: NSObject {
    
    var url: URL
    var failMessage: String?
    var user: String?
    var password: String?
    
    var movies: [Movie]
    private var cancelCopy: Bool    //set when cancel button is pressed
    private var copyLock: Bool      //set when copying to prevent concurrent copying
    
    public enum Order: String {
        case Name
        case Category
    }
    
    init(url: URL, failMessage: String?, user: String = "", password: String = "", test: Bool = false) {
        self.url = url
        self.movies = []
        self.failMessage = failMessage
        self.user = user
        self.password = password
        self.cancelCopy = false
        self.copyLock = false

        super.init()
        
        //check if it is a remote drive
        if (self.url.absoluteString.contains("smb:")) {
            connectToNetShare()
        }
        
        if (!self.connected() && !test) {
            let alert = NSAlert()
            alert.messageText = self.failMessage!
            alert.informativeText = ""
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "Wiederholen")
            _ = alert.runModal()
        }
    }
    
    func connectToNetShare() {
        
        // expect url like smb://1234.local/Movies/4_transfer
        let urlParts = self.url.relativePath.components(separatedBy: "/")
        
        if urlParts.count > 1 {
            let serverAddress = urlParts[1]
            let shareName = urlParts[2]
        
            var path = "/Volumes"
            for i in 2..<urlParts.count {
                path = "\(path)/\(urlParts[i])"
            }
            
            // bend url to mount point
            self.url = URL(string: path)!

            mountShare(serverAddress: serverAddress, shareName: shareName)
        }
    }
    
    
    func mountShare(serverAddress: String, shareName: String) {
        let mountPoint = "/Volumes/".appending(shareName)
        var isDir: ObjCBool = false
        if FileManager().fileExists(atPath: mountPoint, isDirectory: &isDir) {
            if isDir.boolValue {
                _ = NetFS.unmount(mountPoint, 0)
            }
        }
        
        var uc = URLComponents()
        uc.scheme = "smb"
        uc.host = serverAddress
        uc.path = "/" + shareName
        let sharePath = uc.url!
        
        let mounted: Int32 = NetFSMountURLSync(sharePath as NSURL, nil, self.user! as CFString, self.password! as CFString, nil, nil, nil)
        if mounted > 0 {
            print("Error: sharePath: \(sharePath) not valid")
        } else {
            print("Mounted: \(sharePath)")
        }
    }

    
    func connected() -> Bool {
        return  FileManager().fileExists(atPath: self.url.path)
    }
    
    func cancelCopying() {
        self.cancelCopy = true
    }
    
    // copies all new movies from other drive into own url 
    // a new movie is a movie that is at the other drive and not yet on self
    // returns number of files copied
    func copyNewMovies(from: Drive) -> Int {
        
        
        if (!self.connected()) {
            return 0
        }
        
        if self.copyLock {
            return 0
        }
        
        self.copyLock = true
        self.cancelCopy = false
        
        let ownMovies = self.getMovies()
        
        //extract names
        var ownMovieNames: [String] = []
        
        for movie in ownMovies {
            ownMovieNames.append(movie.name)
        }
        
        let newRemoteMovies = from.getMovies(except: ownMovieNames)
        
        if newRemoteMovies.count > 0 {
            
            let numberOfFiles: Double = Double(newRemoteMovies.count)
            

            DispatchQueue.global(qos: .utility).async {
                

                DispatchQueue.main.sync {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "initProgressBar"), object: nil, userInfo: ["numberOfFiles": numberOfFiles])
                }
                
                //copy those new movies
                for movie in newRemoteMovies {
                    
                    if self.cancelCopy {break}

                    DispatchQueue.main.sync {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "incrementProgressBar"), object: nil)
                    }
                    movie.copy(to: self.url)
                }
                
                self.copyLock = false
                DispatchQueue.main.sync {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "cancelProgressBar"), object: numberOfFiles)
                }
            }
        }
        
        return newRemoteMovies.count
        
    }
    
    // looks for all movies except those listed in except. and refills self.movies
    func getMovies(except: [String] = []) -> [Movie] {
        //deallocate all old Movie instances
        self.movies = []
        
        //read directory tree, instantiate movies, and fill in self.movies
        
        if (!self.connected()) {
            return []
        }
        
        do {
            let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
            let enumerator = FileManager.default.enumerator(at: self.url,
                                                            includingPropertiesForKeys: resourceKeys,
                                                            options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                print("directoryEnumerator error at \(url): ", error)
                                                                return true
            })!
            
            for case let fileURL as URL in enumerator {
                //calculate relative path from baseURL
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                if (resourceValues.isDirectory!  == false) {
                    var relPath: String = ""
                    var tempURL: URL = fileURL
                    
                    // check if fileURL shoud be excluded
                    if (except.contains(fileURL.lastPathComponent)) {
                            continue // take next file
                    }
                    
                    // now cut off last parts of URL until the remaining URL is self.url
                    // while adding the cut off parts to the relPath
                    while (tempURL.path !=  self.url.path) {
                        if (relPath == "") {
                            relPath = tempURL.lastPathComponent
                        } else {
                            relPath = tempURL.lastPathComponent + "/" + relPath
                        }
                        tempURL = tempURL.deletingLastPathComponent()
                    }
                    let movieURL = URL(fileURLWithPath: relPath, isDirectory: false, relativeTo: tempURL)
                    self.movies.append(Movie(url: movieURL))
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return self.movies
    }
    
    func getCategories() -> [String]? {
        
        if (!self.connected()) {
            return []
        }
        
        let contents  = try! FileManager().contentsOfDirectory(at: self.url, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
        let directories = contents.filter{$0.hasDirectoryPath}
        
        var categories: [String] = []
        
        for directory: URL in directories {
            categories.append(directory.lastPathComponent)
        }
        
        // add empty ('new') directory
        categories.append("")
        
        return categories
    }
    
    // sort movies by name or category
    func sort(by: Order, ascending: Bool) {
        switch by {
        case .Name:
            switch ascending {
            case true:
                self.movies.sort{ ($0.name) < ($1.name)}
            case false:
                self.movies.sort{ ($0.name) > ($1.name)}
            }
        case .Category:
            switch ascending {
            case true:
                self.movies.sort{ ($0.category) < ($1.category)}
            case false:
                self.movies.sort{ ($0.category) > ($1.category)}
            }
        }
    }
    
    // filters movies by category
    // '' gets all movies ' ' gets all new movies
    func filter(by: String) {
        if by == " " {
            // 'new' movies
            self.movies = self.movies.filter{ (movie) in movie.category == "" }
        } else if by == "" {
            // do nothing
        } else {
            self.movies = self.movies.filter{ (movie) in movie.category.contains(by) }
        }
    }

}
