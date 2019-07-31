//
//  VideoCell.swift
//  RWVideoController
//
//  Created by Raditya Kurnianto on 7/30/19.
//  Copyright © 2019 raditya. All rights reserved.
//

import UIKit

class VideoCell: UITableViewCell {

    var video: RWVideoController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupVideo() -> Void {
        if video == nil {
            
            let quality = [
                ["720p": "http://vod.cnnindonesia.com/mc/_definst_/smil:http/mc/video/detiktv/videoservice/CNN/2019/07/02//9a87b70a17934677baa909c6f1b7e495.smil/playlist.m3u8"],
                ["480p": "http://vod.cnnindonesia.com/mc/_definst_/smil:http/mc/video/detiktv/videoservice/CNN/2019/07/02//9a87b70a17934677baa909c6f1b7e495.smil/playlist.m3u8"],
                ["240p": "http://vod.cnnindonesia.com/mc/_definst_/smil:http/mc/video/detiktv/videoservice/CNN/2019/07/02//9a87b70a17934677baa909c6f1b7e495.smil/playlist.m3u8"]
            ]
            
            video = RWVideoController(defaultVideo: "http://vod.cnnindonesia.com/mc/_definst_/smil:http/mc/video/detiktv/videoservice/CNN/2019/07/02//9a87b70a17934677baa909c6f1b7e495.smil/playlist.m3u8", qualities: quality)
            video?.autoplay = true
            
            contentView.addSubview(video!.view)
            video!.view.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.width * 0.5625)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
