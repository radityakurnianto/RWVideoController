//
//  ViewController.swift
//  RWVideoController
//
//  Created by Raditya Kurnianto on 7/2/19.
//  Copyright © 2019 raditya. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        let quality = [
            ["720p": "quality1"],
            ["480p": "quality2"],
            ["240p": "quality3"]
        ]
        
        let livestream = RWVideoController(videoUrl: "live_stream_url_here")
        
        addChild(livestream)
        self.view.addSubview(livestream.view)
        livestream.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width * 0.5625)
        livestream.didMove(toParent: self)
        
        let video = RWVideoController(defaultVideo: "video_url_here", qualities: quality)
        addChild(video)
        self.view.addSubview(video.view)
        video.view.frame = CGRect(x: 0, y: (self.view.frame.width * 0.5625) + 50, width: self.view.frame.width, height: self.view.frame.width * 0.5625)
        video.didMove(toParent: self)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}

