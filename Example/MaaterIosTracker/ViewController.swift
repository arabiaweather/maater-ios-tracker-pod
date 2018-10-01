//
//  ViewController.swift
//  MaaterIosTracker
//
//  Created by tillawy on 10/01/2018.
//  Copyright (c) 2018 tillawy. All rights reserved.
//

import UIKit
import MaaterIosTracker

class ViewController: UIViewController {

    @IBOutlet weak var buttonTrackMe: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func actionTrackMe(_ sender: Any) {
        Tracker.shared.trackUser(userId: 77, clientId: 11, fullname: "grendizer", email: "tiiiiia@asdasdf.com")
    }
}

