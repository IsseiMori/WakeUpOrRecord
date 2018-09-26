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
    
    let durations = ["5s", "30s", "1m", "5m"]
    let durationsInSec: [UInt32] = [5, 30, 60, 300]

    override func viewDidLoad() {
        super.viewDidLoad()

        
        form +++ Section(NSLocalizedString("setting", comment: ""))
            <<< TimeRow("alarmTime") {
                $0.title = NSLocalizedString("alarm time", comment: "")
                
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
            <<< PickerInlineRow<String>("recordDuration"){
                $0.title = NSLocalizedString("record duration", comment: "")
                $0.options = ["5s", "30s", "1m", "5m"]
                $0.value = $0.options[0]
                }.onChange({ (row) in
                    print(row.value!)
                })
        
        form +++ Section()
            <<< ButtonRow() {
                $0.title = NSLocalizedString("set alarm", comment: "")
                }.onCellSelection({ (cell, row) in
                    
                    let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! cameraVC
                    
                    // set selected alarm time in Date
                    let timeRow = self.form.rowBy(tag: "alarmTime") as! TimeRow
                    cameraVC.alarmTime  = timeRow.value
                    
                    // set selected duration in seconds
                    let pickerView = self.form.rowBy(tag: "recordDuration") as! PickerInlineRow<String>
                    cameraVC.recordDuration = self.durationsInSec[self.durations.index(of: pickerView.value!)!]
                    
                    self.navigationController?.pushViewController(cameraVC, animated: true)
                })
    }


}
