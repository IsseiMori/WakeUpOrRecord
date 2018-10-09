//
//  cameraVC.swift
//  WakeUpOrRecord
//
//  Created by MoriIssei on 9/23/18.
//  Copyright © 2018 IsseiMori. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos

class cameraVC: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    // alarm time
    var alarmTime: Date!
    
    // record duration
    var recordDuration: UInt32!
    
    var timerStartCamera: Timer?
    var timerStartAlarm: Timer?
    var timerEndAlarm: Timer?
    var timerShowTime: Timer?

    // セッションの作成
    var session: AVCaptureSession!
    
    // 録画状態フラグ
    private var recording: Bool = false
    
    // ビデオのアウトプット
    private var myVideoOutput: AVCaptureMovieFileOutput!
    
    // ビデオレイヤー
    private var myVideoLayer: AVCaptureVideoPreviewLayer!
    
    // ボタン
    private var button: UIButton!
    
    var audioPlayer: AVAudioPlayer!
    
    // black view to turn off the screen
    var blackView: UIView!
    
    // white view to hide camera preview
    var whiteView: UIView!
    
    // label: tap to hide screen
    var tapToHideTxt: UILabel!
    
    // clock label
    var clockLbl: UILabel!
    
    // camera preview button
    var previewBtn: UIButton!
    var previewOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set nav title
        self.navigationItem.title = NSLocalizedString("app name", comment: "")
        
        // new back button
        self.navigationItem.hidesBackButton = true
        let backBtn = UIBarButtonItem(image: UIImage(named: "back.png"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.back))
        self.navigationItem.leftBarButtonItem = backBtn

        // セッションの作成
        session = AVCaptureSession()
        
        // 出力先を生成
        let myImageOutput = AVCapturePhotoOutput()
        
        // バックカメラを取得
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        let videoInput = try! AVCaptureDeviceInput.init(device: camera!)
        
        // ビデオをセッションのInputに追加
        session.addInput(videoInput)
        
        // マイクを取得
        let mic = AVCaptureDevice.default(.builtInMicrophone, for: AVMediaType.audio, position: .unspecified)
        let audioInput = try! AVCaptureDeviceInput.init(device: mic!)
        
        // オーディオをセッションに追加
        session.addInput(audioInput)
        
        // セッションに追加
        session.addOutput(myImageOutput)
        
        // 動画の保存
        myVideoOutput = AVCaptureMovieFileOutput()
        
        // ビデオ出力をOutputに追加
        session.addOutput(myVideoOutput)
        
        // 画像を表示するレイヤーを生成
        myVideoLayer = AVCaptureVideoPreviewLayer.init(session: session)
        myVideoLayer?.frame = self.view.bounds
        myVideoLayer.zPosition = -1
        myVideoLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // Viewに追加
        self.view.layer.addSublayer(myVideoLayer!)

        let width = self.view.frame.size.width
        let height = self.view.frame.size.height

        whiteView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        whiteView.backgroundColor = UIColor.white
        self.view.addSubview(whiteView)
        
        let screenTap = UITapGestureRecognizer(target: self, action: #selector(self.screenTap))
        screenTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(screenTap)
        
        // black view to turn off the screen
        blackView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        blackView.backgroundColor = UIColor.black
        blackView.isHidden = true
        blackView.isUserInteractionEnabled = true
        self.navigationController?.view.addSubview(blackView)
        
        let blackScreenTap = UITapGestureRecognizer(target: self, action: #selector(self.screenTap))
        blackScreenTap.numberOfTapsRequired = 1
        blackView.addGestureRecognizer(blackScreenTap)
        
        // clock label
        clockLbl = UILabel(frame: CGRect(x: width * 0.1, y: 0, width: width * 0.8, height: 100))
        let date = NSDate()
        let calendar = NSCalendar.current
        let hour = "\(calendar.component(.hour, from: date as Date))"
        var minute = "\(calendar.component(.minute, from: date as Date))"
        // add 0 to minute if one digit
        if minute.count <= 1 {
            minute = "0\(minute)"
        }
        clockLbl.text = hour + " : " + minute
        clockLbl.font = clockLbl.font.withSize(width / 5)
        /*clockLbl.numberOfLines = 1
        clockLbl.adjustsFontSizeToFitWidth = true
        clockLbl.minimumScaleFactor = 1
        clockLbl.lineBreakMode = NSLineBreakMode.byClipping
        clockLbl.backgroundColor = .red
        clockLbl.setNeedsLayout()*/
        clockLbl.sizeToFit()
        clockLbl.center = self.view.center
        self.view.addSubview(clockLbl)
        
        
        // text label to tell tap to show/hide screen
        tapToHideTxt = UILabel(frame: CGRect(x: 0, y: clockLbl.frame.origin.y + clockLbl.frame.size.height + 20, width: self.view.frame.size.width * 0.8, height: 20))
        tapToHideTxt.text = NSLocalizedString("tap to show/hide screen", comment: "")
        tapToHideTxt.sizeToFit()
        tapToHideTxt.center.x = self.view.center.x
        self.view.addSubview(tapToHideTxt)
        
        // camera preview button
        previewBtn = UIButton(frame: CGRect(x: 10, y: self.view.frame.size.height - 50, width: width * 0.3, height: 40))
        previewBtn.setTitle(NSLocalizedString("preview", comment: ""), for: UIControlState.normal)
        previewBtn.backgroundColor = UIColor.gray
        previewBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
        previewBtn.layer.cornerRadius = 5
        previewBtn.clipsToBounds = true
        self.view.addSubview(previewBtn)
        
        // camera preview button tap
        let previewBtnTap = UITapGestureRecognizer(target: self, action: #selector(self.previewBtnTap))
        previewBtnTap.numberOfTapsRequired = 1
        previewBtn.addGestureRecognizer(previewBtnTap)

        let alert = UIAlertController(title: NSLocalizedString("good night", comment: ""), message: NSLocalizedString("good night msg", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) { (UIAlertAction) in
            self.setAlarm()
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)

    }
    
    func setAlarm() {
        // set timer
        var timeInterval = alarmTime.timeIntervalSince(Date())
        if timeInterval < 0 {
            timeInterval = timeInterval + 86400
        }
        print(timeInterval)
        // timeInterval = 5
        self.timerStartCamera = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(self.startRecord), userInfo: nil, repeats: false)
        self.timerStartAlarm = Timer.scheduledTimer(timeInterval: timeInterval - 1, target: self, selector: #selector(self.startAlarm), userInfo: nil, repeats: false)
        self.timerEndAlarm = Timer.scheduledTimer(timeInterval: timeInterval + Double(recordDuration), target: self, selector: #selector(self.stopRecord), userInfo: nil, repeats: false)
        self.timerShowTime = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
    }
    
    
    // show and hide black screen
    @objc func screenTap() {
        blackView.isHidden = !blackView.isHidden
    }
    
    
    @objc func startAlarm() {
        print("start alarm")
        
        // show screen
        whiteView.isHidden = true
        blackView.isHidden = true
        tapToHideTxt.isHidden = true
        clockLbl.isHidden = true
        previewBtn.isHidden = true
        
        
        print("hide things")
        
        
        // start camera session
        session.startRunning()
        
        // add stop button
        button = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        button.backgroundColor = .red
        button.layer.masksToBounds = true
        button.setTitle(NSLocalizedString("stop", comment: ""), for: .normal)
        button.layer.cornerRadius = 10.0
        button.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height-50)
        button.addTarget(self, action: #selector(self.onTapButton), for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    @objc func startRecord() {
        
        print("start record")
        
        //play .mp3 sound
        playSound(name: "watch")
        
        // set up file path
        let path: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let filePath: String = path + "/test.mov"
        let fileURL: URL = URL(fileURLWithPath: filePath)
        
        // Start recording
        myVideoOutput.startRecording(to: fileURL, recordingDelegate: self)
        
        self.recording = true
    }
    
    @objc func stopRecord() {
        if (self.recording) {
    
            print("you didn't wake up")
    
            // stop
            myVideoOutput.stopRecording()
    
            // session.stopRunning()
            self.recording = false
            
            // hide video view
            whiteView.isHidden = false
    
            let alert = UIAlertController(title: NSLocalizedString("good morning", comment: ""), message: NSLocalizedString("did not wake up msg", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) { (UIAlertAction) in
                self.stopSound()
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc internal func onTapButton(sender: UIButton){
        print("stop button")
        if (self.recording) {
            
            self.stopSound()
            
            // stop
            myVideoOutput.stopRecording()
            
            
            // hide video view
            whiteView.isHidden = false
            
            let alert = UIAlertController(title: NSLocalizedString("good morning", comment: ""), message: NSLocalizedString("good morning msg", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) { (UIAlertAction) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func updateTime() {
        let date = NSDate()
        let calendar = NSCalendar.current
        let hour = "\(calendar.component(.hour, from: date as Date))"
        var minute = "\(calendar.component(.minute, from: date as Date))"
        // add 0 to minute if one digit
        if minute.count <= 1 {
            minute = "0\(minute)"
        }
        clockLbl.text = hour + " : " + minute
        clockLbl.sizeToFit()
        clockLbl.center = self.view.center
    }
    
    @objc func previewBtnTap(sender: UIButton) {
        if previewOn {
            print("turn off preview")
            session.stopRunning()
            whiteView.isHidden = false
            previewBtn.backgroundColor = UIColor.gray
        } else {
            print("turn on preview")
            session.startRunning()
            whiteView.isHidden = true
            previewBtn.backgroundColor = UIColor.red
        }
        previewOn = !previewOn
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        print("export video")
        
        // 動画URLからアセットを生成
        let videoAsset: AVURLAsset = AVURLAsset(url: outputFileURL, options: nil)
        
        // ベースとなる動画のコンポジション作成
        let mixComposition : AVMutableComposition = AVMutableComposition()
        let compositionVideoTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let compositionAudioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        // アセットからトラックを取得
        let videoTrack: AVAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
        let audioTrack: AVAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.audio)[0]
        
        // コンポジションの設定
        try! compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), of: videoTrack, at: kCMTimeZero)
        compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        
        try! compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), of: audioTrack, at: kCMTimeZero)
        
        // 動画のサイズを取得
        var videoSize: CGSize = videoTrack.naturalSize
        var isPortrait: Bool = false
        
        // ビデオを縦横方向
        if myVideoLayer.connection?.videoOrientation == .portrait {
            isPortrait = true
            videoSize = CGSize(width: videoSize.height, height: videoSize.width)
        }
        
        // ロゴのCALayerの作成
        let logoImage: UIImage = UIImage(named: "logologo.png")!
        let logoLayer: CALayer = CALayer()
        logoLayer.contents = logoImage.cgImage
        logoLayer.frame = CGRect(x: 5, y: 25, width: 100, height: 100)
        logoLayer.opacity = 0.9
        
        // 親レイヤーを作成
        let parentLayer: CALayer = CALayer()
        let videoLayer: CALayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(logoLayer)
        
        // 合成用コンポジション作成
        let videoComp: AVMutableVideoComposition = AVMutableVideoComposition()
        videoComp.renderSize = videoSize
        videoComp.frameDuration = CMTimeMake(1, 30)
        videoComp.animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        // インストラクション作成
        let instruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration)
        let layerInstruction: AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        
        // 縦方向で撮影なら90度回転させる
        if isPortrait {
            let FirstAssetScaleFactor:CGAffineTransform = CGAffineTransform(scaleX: 1.0, y: 1.0);
            layerInstruction.setTransform(videoTrack.preferredTransform.concatenating(FirstAssetScaleFactor), at: kCMTimeZero)
        }
        
        // インストラクションを合成用コンポジションに設定
        videoComp.instructions = [instruction]
        
        // 動画のコンポジションをベースにAVAssetExportを生成
        let assetExport = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality)
        // 合成用コンポジションを設定
        assetExport?.videoComposition = videoComp
        
        // エクスポートファイルの設定
        let videoName: String = "test.mov"
        let documentPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let exportPath: String = documentPath + "/" + videoName
        let exportUrl: URL = URL(fileURLWithPath: exportPath)
        assetExport?.outputFileType = AVFileType.mov
        assetExport?.outputURL = exportUrl
        assetExport?.shouldOptimizeForNetworkUse = true
        print(assetExport?.outputURL!)
        
        // ファイルが存在している場合は削除
        if FileManager.default.fileExists(atPath: exportPath) {
            try! FileManager.default.removeItem(atPath: exportPath)
        }
        
        // エクスポート実行
        assetExport?.exportAsynchronously(completionHandler: {() -> Void in
            // 端末に保存
            PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportUrl)
            }, completionHandler: {(success, err) -> Void in
            var message = ""
            if success {
            message = "保存しました"
                print("saved")
            } else {
            message = "保存に失敗しました"
                print(err!)
            }
            // アラートを表示
            DispatchQueue.main.async(execute: {
            let alert = UIAlertController.init(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default){ (action: UIAlertAction) in
            }
            alert.addAction(action)
            // self.present(alert, animated: true, completion: nil)
            });
            })
        })
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // Delete timer schedules
        if timerStartCamera != nil {
            timerStartCamera?.invalidate()
        }
        if timerStartAlarm != nil {
            timerStartAlarm?.invalidate()
        }
        if timerEndAlarm != nil {
            timerEndAlarm?.invalidate()
        }
    }
    
    @objc func back(sender: UIBarButtonItem) {
        
        // push back
        self.navigationController?.popViewController(animated: true)
    }

}

extension cameraVC: AVAudioPlayerDelegate {
    func playSound(name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: "mp3") else {
            print("No sound file found")
            return
        }
        
        do {
            // Instantiate AVAudioPlayer
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            
            // Set AVAudioPlayer delegate
            audioPlayer.delegate = self
            
            // repeat sound
            audioPlayer.numberOfLoops = -1
            
            // play sound
            audioPlayer.play()
        } catch {
        }
    }
    
    func stopSound() {
        audioPlayer.stop()
    }
}
