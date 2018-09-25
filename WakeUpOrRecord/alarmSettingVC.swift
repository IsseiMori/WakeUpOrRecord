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
            <<< TimeRow("alarmTime") {
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
            <<< PickerInlineRow<String>(){
                $0.title = "Record Duration"
                $0.options = ["5s", "30s", "1m", "5m"]
                $0.value = $0.options[0]
                }.onChange({ (row) in
                    print(row.value!)
                })
        
        form +++ Section()
            <<< ButtonRow() {
                $0.title = "Set Alarm"
                }.onCellSelection({ (cell, row) in
                    print("pressed")
                    let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! cameraVC
                    print(self.form.allRows)
                    let timeRow = self.form.rowBy(tag: "alarmTime") as! TimeRow
                    cameraVC.alarmTime  = timeRow.value
                    cameraVC.recordDuration = 5
                    self.navigationController?.pushViewController(cameraVC, animated: true)
                })
    }


}
