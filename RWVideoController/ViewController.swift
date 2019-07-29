//
//  ViewController.swift
//  RWVideoController
//
//  Created by Raditya Kurnianto on 7/2/19.
//  Copyright © 2019 raditya. All rights reserved.
//

import UIKit
import CoreMedia

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        let quality = [
            ["720p": "http://vod.cnnindonesia.com/mc/_definst_/smil:http/mc/video/detiktv/videoservice/CNN/2019/07/02//9a87b70a17934677baa909c6f1b7e495.smil/playlist.m3u8"],
            ["480p": "http://vod.cnnindonesia.com/mc/_definst_/smil:http/mc/video/detiktv/videoservice/CNN/2019/07/02//9a87b70a17934677baa909c6f1b7e495.smil/playlist.m3u8"],
            ["240p": "http://vod.cnnindonesia.com/mc/_definst_/smil:http/mc/video/detiktv/videoservice/CNN/2019/07/02//9a87b70a17934677baa909c6f1b7e495.smil/playlist.m3u8"]
        ]
        
        let url = "https://www.youtube.com/watch?v=0VbTT5GUqBk"
//        let url = "https://live.cnbcindonesia.com/livecnbc/smil:cnbctv.smil/playlist.m3u8"
        let livestream = RWVideoController(videoUrl: url)
        
        addChild(livestream)
        self.view.addSubview(livestream.view)
        livestream.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width * 0.5625)
        livestream.didMove(toParent: self)
        
        let video = RWVideoController(defaultVideo: "http://vod.cnnindonesia.com/mc/_definst_/smil:http/mc/video/detiktv/videoservice/CNN/2019/07/02//9a87b70a17934677baa909c6f1b7e495.smil/playlist.m3u8", qualities: quality)
        video.delegate = self
        video.autoplay = true
        addChild(video)
        self.view.addSubview(video.view)
        video.view.frame = CGRect(x: 0, y: (self.view.frame.width * 0.5625) + 50, width: self.view.frame.width, height: self.view.frame.width * 0.5625)
        video.didMove(toParent: self)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ViewController: RWVideoDelegate {
    func video(didFinishPlaying: RWVideoController) {
        print("didFinishPlaying")
    }
    
    func videoDidEnterFullscreen() {
        print("videoDidEnterFullscreen")
    }
    
    func videoDidExitFullscreen() {
        print("videoDidExitFullscreen")
    }
    
    func videoStateDidChange(_ player: RWVideoController, state: PlayerState) {
        if state == .played {
            print("video is playing")
        } else if state == .paused {
            print("video is being pause")
        }
    }
    
    func video(_ player: RWVideoController, currentDuration: CMTime, totalDuration: CMTime) {
        print("video \(Float(CMTimeGetSeconds(currentDuration))):\(Float(CMTimeGetSeconds(totalDuration)))")
    }
    
    func video(_ player: RWVideoController, sliderState: SliderState) {
        print("slider is being \(sliderState == .sliderIdle ? "idle" : "seek")")
    }
}
