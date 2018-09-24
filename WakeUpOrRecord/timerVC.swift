//
//  timerVC.swift
//  WakeUpOrRecord
//
//  Created by MoriIssei on 9/23/18.
//  Copyright © 2018 IsseiMori. All rights reserved.
//

import UIKit

class timerVC: UIViewController {
    
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        print("set timer")
        self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.alarm), userInfo: nil, repeats: false)
        
    }
    
    @objc func update(){
        
    }
    
    @objc func alarm() {
        print("alarm")
    }
    

}
