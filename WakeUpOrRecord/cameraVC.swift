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

    // 録画状態フラグ
    private var recording: Bool = false
    
    // ビデオのアウトプット
    private var myVideoOutput: AVCaptureMovieFileOutput!
    
    // ビデオレイヤー
    private var myVideoLayer: AVCaptureVideoPreviewLayer!
    
    // ボタン
    private var button: UIButton!
    
    var audioPlayer: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // セッションの作成
        let session = AVCaptureSession()
        
        // 出力先を生成
        let myImageOutput = AVCapturePhotoOutput()
        
        // バックカメラを取得
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
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
        myVideoLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // Viewに追加
        self.view.layer.addSublayer(myVideoLayer!)
        
        // セッション開始.
        session.startRunning()
        
        // UI
        button = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        button.backgroundColor = .red
        button.layer.masksToBounds = true
        button.setTitle("START", for: .normal)
        button.layer.cornerRadius = 20.0
        button.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height-50)
        button.addTarget(self, action: #selector(self.onTapButton), for: .touchUpInside)
        self.view.addSubview(button)
        
        
        // mp3音声(SOUND.mp3)の再生
        playSound(name: "dog")
        
        // start recording
        let path: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let filePath: String = path + "/test.mov"
        let fileURL: URL = URL(fileURLWithPath: filePath)
        
        // 録画開始
        myVideoOutput.startRecording(to: fileURL, recordingDelegate: self)
        button.setTitle("STOP", for: .normal)
        
        sleep(5)
        
        // stop
        myVideoOutput.stopRecording()
        button.isEnabled = false
        button.isHidden = true
    }
    
    
    @objc internal func onTapButton(sender: UIButton){
        print("撮影！")
        if (self.recording) {
            // stop
            myVideoOutput.stopRecording()
            button.isEnabled = false
            button.isHidden = true
        } else {
            // start recording
            let path: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let filePath: String = path + "/test.mov"
            let fileURL: URL = URL(fileURLWithPath: filePath)
            
            // 録画開始
            myVideoOutput.startRecording(to: fileURL, recordingDelegate: self)
            button.setTitle("STOP", for: .normal)
        }
        
        self.recording = !self.recording
    }
    
    
    
    
    
    
    
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
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
            } else {
            message = "保存に失敗しました"
            }
            // アラートを表示
            DispatchQueue.main.async(execute: {
            let alert = UIAlertController.init(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default){ (action: UIAlertAction) in
            self.button.setTitle("START", for: .normal)
            self.button.isEnabled = true
            self.button.isHidden = false
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            });
            })
        })
    }

}

extension cameraVC: AVAudioPlayerDelegate {
    func playSound(name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: "mp3") else {
            print("音源ファイルが見つかりません")
            return
        }
        
        do {
            // AVAudioPlayerのインスタンス化
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            
            // AVAudioPlayerのデリゲートをセット
            audioPlayer.delegate = self
            
            // 音声の再生
            audioPlayer.play()
        } catch {
        }
    }
}
