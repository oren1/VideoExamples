//
//  ViewController.swift
//  VideoFilter
//
//  Created by oren shalev on 16/06/2023.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    var playerController: AVPlayerViewController!
    var coinsAsset: AVAsset!
    var composition: AVMutableComposition!
    
    var context: CIContext!
    var currentFilter: CIFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let coinsUrl = Bundle.main.url(forResource: "Coins", withExtension: "mov")!
        coinsAsset = AVAsset(url: coinsUrl)
        
        context = CIContext()
        currentFilter = CIFilter(name: "CIExposureAdjust")
        
        Task {
            let videoComposition = try! await AVMutableVideoComposition.videoComposition(with: self.coinsAsset) { [weak self] request in
                guard let self = self else {return}
                self.currentFilter.setValue(request.sourceImage, forKey: kCIInputImageKey)
                self.currentFilter.setValue(0.4, forKey: kCIInputEVKey)
                request.finish(with: self.currentFilter.outputImage!, context: nil)
            }
            
            let coinsTrack = try! await coinsAsset.loadTracks(withMediaType: .video)[0]
            let videoDuration = try! await coinsAsset.load(.duration)
            let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask)[0]
            let temp_url = documentDirectory.appendingPathComponent("coin_asset_5.mov")
            try! FileManager.default.removeItem(at: temp_url)
            let exportSession = AVAssetExportSession(asset: self.coinsAsset, presetName: AVAssetExportPresetMediumQuality)

//            let temp_url = documentDirectory.appendingPathComponent("coin_asset_5.mov")
            exportSession?.outputURL = temp_url
            exportSession?.outputFileType = .mov
            exportSession?.timeRange = CMTimeRange(start: .zero, duration: videoDuration - CMTime(value: 8, timescale: 1))
            exportSession?.videoComposition = videoComposition
            await exportSession?.export()
            var exportedAsset = AVAsset(url: temp_url)
            
            // Do any additional setup after loading the view.
            let playerItem = AVPlayerItem(asset: exportedAsset)
//            playerItem.videoComposition = videoComposition
            let player = AVPlayer(playerItem: playerItem)
            playerController = AVPlayerViewController()
            playerController.player = player
            addPlayerToTop()
        }

    }

    func addPlayerToTop() {
        //add as a childviewcontroller
        addChild(playerController)

         // Add the child's View as a subview
         self.view.addSubview(playerController.view)
        playerController.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height * 0.5)
        playerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

         // tell the childviewcontroller it's contained in it's parent
        playerController.didMove(toParent: self)
        self.playerController.player?.play()
    }

}

