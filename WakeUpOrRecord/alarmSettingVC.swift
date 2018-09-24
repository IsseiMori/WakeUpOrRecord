//
//  alarmSettingVC.swift
//  WakeUpOrRecord
//
//  Created by MoriIssei on 9/24/18.
//  Copyright © 2018 IsseiMori. All rights reserved.
//

import UIKit
import Eureka

class alarmSettingVC: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
        form +++ Section("Setting")
            <<< TimeRow() {
                $0.title = "Alarm Time"
                
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                formatter.locale = Locale.current
                
                $0.dateFormatter = formatter
                $0.value = NSDate() as Date
                }.onChange({ (row) in
                    print(row.value!)
                    print(NSDate())
                    print(row.value!.timeIntervalSince(NSDate() as Date))
                })
    }


}
