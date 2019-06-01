//
//  ViewController.swift
//  HallenFilme
//
//  Created by Andreas Pohl on 15.10.17.
//  Copyright © 2017 Andreas Pohl. All rights reserved.
//


import Cocoa
import AVKit
import AVFoundation
import NetFS

class ViewController: NSViewController {

    var raid: Drive?
    var halle: Drive?

    var raidMovies: [Movie]?
    var hallenMovies: [Movie]?
    
    var sortOrder: Drive.Order = Drive.Order.Category
    var sortAscending: Bool = true
    var filterString: String = ""
    
    var prefs = Preferences()

    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    @IBOutlet weak var detailNameField: NSTextField!
    @IBOutlet weak var detailCategoryBox: NSComboBox!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var progressLabel: NSTextField!
    
    //MARK: Buttons
    //cancel copying
    @IBAction func cancelButton(_ sender: Any) {
        progressLabel.stringValue = "Kopieren wird gestoppt..."
        progressLabel.isHidden = false
        progressIndicator.isHidden = true
        raid?.cancelCopying()
    }
    
    // move all selected movies to selected category
    @IBAction func saveButton(_ sender: NSButton) {
        
        // get all selected movies
        let selection = tableView.selectedRowIndexes
        let category = detailCategoryBox.stringValue
        
        for  row in selection {
            let movie = raidMovies?[row]
            movie?.setCategory(to: category)
        }
        
        reloadFileList()
    }
    
    //connect to halle and copy all new moview from there
    @IBAction func syncButton(_ sender: NSButton) {
        
        updateRaid()
        updateHalle()
        
        _ = raid?.copyNewMovies(from: halle!)
        
        reloadFileList()
    }
    
    
    //MARK: View
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Do any additional setup after loading the view.
                
        let raidURL: URL = URL(fileURLWithPath: prefs.raidUrlString, isDirectory: true)
        raid = Drive(url: raidURL, failMessage: prefs.raidFailMessage)
        
        raidMovies = raid?.getMovies()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchField.delegate = self
        
        // sorting
        let descriptorName = NSSortDescriptor(key: Drive.Order.Name.rawValue , ascending: true)
        let descriptorCategory = NSSortDescriptor(key: Drive.Order.Category.rawValue, ascending: true)
        
        tableView.tableColumns[0].sortDescriptorPrototype = descriptorName
        tableView.tableColumns[1].sortDescriptorPrototype = descriptorCategory
        
        let categories = raid?.getCategories()
        for category in categories! {
            detailCategoryBox.addItem(withObjectValue: category)
        }
        
        self.setupPrefs()
        self.setupProgressBar()
        
        let trackingArea = NSTrackingArea(rect: playerView.visibleRect, options: [.activeInKeyWindow, .mouseMoved], owner: self, userInfo: nil)
        playerView.addTrackingArea(trackingArea)
        
    }
    
    override var representedObject: Any? {
        
        didSet {
        // Update the view, if already loaded.
            
        }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.characters! {
            
        case " ":
            if (playerView.player?.rate)! >= Float(1.0) {
                playerView.player?.pause()
            } else {
                playerView.player?.play()
            }
            
        case "\u{7F}": // cmd - backspace for deleting a movie
            self.deleteMovies()
            
        default:
            break
        }
    }
    
    func reloadFileList() {
        
        _ = raid?.getMovies()
        raid?.filter(by: filterString)
        raid?.sort(by: sortOrder, ascending: sortAscending)
        raidMovies = raid?.movies
        tableView.reloadData()
        updateStatus()
    }
    
    // the selection in the table view has changed - play selected movie
    func updateStatus() {
        
        let row = tableView.selectedRow
        
        if raidMovies!.count > 0 {
            // there are movies
            
            if (row < 0) || (row > ((raidMovies?.count)!-1)) {
                // selectedRow not valid
                // select the first row anyway
                tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                updateStatus()
                return
            } else {
                // selection is valid, fill the details window
                let lastSelectedMovie = raidMovies![row]
                playerView.player = AVPlayer(url: lastSelectedMovie.url)
                playerView.player?.play()
                detailNameField.stringValue = lastSelectedMovie.name
                detailCategoryBox.selectItem(withObjectValue: lastSelectedMovie.category)
            }
            
        } else {
                // no movies in table
                playerView.player = nil
                detailNameField.stringValue = ""
                return
        }
    }
    
    func deleteMovies() {
        // get all selected movies
        let selection = tableView.selectedRowIndexes
        var alertText = ""
        var infoText = ""
        
        switch selection.count {
        case 0:
            return
        case 1:
            alertText = "Diesen Film wirlich löschen?"
        default:
            alertText = "Diese Filme wirklich löschen?"
        }
        
        for row in selection {
            if infoText != "" {
                infoText = infoText.appending("\n")
            }
            infoText = infoText.appending((raidMovies?[row].name)!)
        }
        
        let alert = NSAlert()
        alert.messageText = alertText
        alert.informativeText = infoText
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        
        let result = alert.runModal()
        if result == NSApplication.ModalResponse.alertFirstButtonReturn {
            for  row in selection {
                let movie = raidMovies?[row]
                _ = movie?.delete()
            }
        } else {
            // do nothing
        }
        reloadFileList()
    }
}

//MARK: NSTableViewDataSource
extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return raidMovies?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        
        guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        if let order = Drive.Order(rawValue: sortDescriptor.key!) {
            sortOrder = order
            sortAscending = sortDescriptor.ascending
            reloadFileList()
        }
    }
    
}

//MARK: NSTableViewDelegate
extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCellID"
        static let CategoryCell = "CategoryCellID"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text: String = ""
        var cellIdentifier: String = ""
                
        guard let item = raidMovies?[row] else {
            return nil
        }
        
        if tableColumn == tableView.tableColumns[0] {
            text = item.name
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.category
            cellIdentifier = CellIdentifiers.CategoryCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateStatus()
    }
    
    override func viewDidAppear() {
        scrollView.becomeFirstResponder()
        reloadFileList()
    }

}


//MARK: NSSearchFieldDelegate
extension ViewController: NSSearchFieldDelegate {
    
    func searchFieldDidStartSearching(_ sender: NSSearchField) {
        
        filterString = searchField.stringValue
        reloadFileList()
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        
        filterString = searchField.stringValue
        reloadFileList()
    }
    
}


//MARK: Preferences
extension ViewController {
    
    func setupPrefs() {
        
        var notificationName = Notification.Name(rawValue: "raidUrlChanged")
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) {
            (notification) in
            self.updateRaid()
        }
        
        notificationName = Notification.Name(rawValue: "halleUrlChanged")
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) {
            (notification) in
            self.updateHalle()
        }
    }
    
    func updateRaid() {
        let raidURL: URL = URL(fileURLWithPath: prefs.raidUrlString, isDirectory: true)
        raid = Drive(url: raidURL, failMessage: prefs.raidFailMessage)
        reloadFileList()
    }
    
    func updateHalle() {
        let halleURL: URL = URL(fileURLWithPath: prefs.halleUrlString, isDirectory: true)
        halle = Drive(url: halleURL, failMessage: prefs.halleFailMessage, user: prefs.halleUser, password: prefs.hallePassword)
    }
    
}

//MARK: Progress Bar
extension ViewController {
    
    func setupProgressBar() {
        
        var notificationName = Notification.Name(rawValue: "initProgressBar")
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) {
            (notification) in
            let maxValue = notification.userInfo?["numberOfFiles"] as! Double
            self.initProgressBar(maxValue: maxValue)
        }
        
        notificationName = Notification.Name(rawValue: "incrementProgressBar")
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) {
            (notification) in
            self.incrementProgressBar()
        }
        
        notificationName = Notification.Name(rawValue: "cancelProgressBar")
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) {
            (notification) in
            self.cancelProgressBar()
        }
        
        progressIndicator.isDisplayedWhenStopped = false
        progressIndicator.stopAnimation(nil)
        cancelButton.isTransparent = true
        
        progressLabel.isHidden = true
        
        
        
        //self.animateBarForTest()
    }
    
    func animateBarForTest() {
    
        func delay(delay: Double, closure: @escaping ()->()) {
            let deadline = DispatchTime.now() + delay
            DispatchQueue.main.asyncAfter(deadline: deadline, execute: closure)
        }
        
        let numberOfFiles = Double(100)
        DistributedNotificationCenter.default.post(name: Notification.Name(rawValue: "initProgressBar"), object: nil, userInfo: ["numberOfFiles" : numberOfFiles])
        
        for i in 1...10 {
            delay(delay: 0.5 * Double(i) + 5.0, closure: {
                DistributedNotificationCenter.default.post(name: Notification.Name(rawValue: "incrementProgressBar"), object: nil)
            })
            
            delay(delay: 12, closure: {
                DistributedNotificationCenter.default.post(name: Notification.Name(rawValue: "cancelProgressBar"), object: nil)
            })
        }
    }
    
    func initProgressBar(maxValue: Double) {
        progressIndicator.minValue = 0
        progressIndicator.maxValue = maxValue
        progressIndicator.doubleValue = 0.1
        progressIndicator.isDisplayedWhenStopped = true
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        cancelButton.isTransparent = false
    }
    
    func incrementProgressBar() {
        progressIndicator.increment(by: 1.0)
        reloadFileList()
    }
    
    func cancelProgressBar() {
        progressLabel.isHidden = true
        progressIndicator.isDisplayedWhenStopped = false
        progressIndicator.stopAnimation(nil)
        cancelButton.isTransparent = true
    }
}
