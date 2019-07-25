//
//  RWVideoProtocol.swift
//  RWVideoController
//
//  Created by Raditya Kurnianto on 7/19/19.
//  Copyright © 2019 raditya. All rights reserved.
//

import Foundation
import AVFoundation

protocol RWVideoDelegate {
    func video(_ player: RWVideoController, currentDuration: CMTime, totalDuration: CMTime) -> Void
    func videoStateDidChange(_ player: RWVideoController, state: PlayerState) -> Void
    func videoDidEnterFullscreen() -> Void
    func videoDidExitFullscreen() -> Void
    func video(_ player: RWVideoController, sliderState: SliderState) -> Void
    func video(didFinishPlaying: RWVideoController) -> Void
    //    func video(_ player: RWVideoController, didSelectQuality: [String: Any]?) -> Void
}
