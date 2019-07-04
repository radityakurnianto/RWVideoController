//
//  RWVideoController.swift
//  RWVideoController
//
//  Created by Raditya Kurnianto on 7/2/19.
//  Copyright © 2019 raditya. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

enum PlayerState {
    case played
    case paused
    case buffer
    case finished
    case ready
}

enum SliderState {
    case sliderBeingSeek
    case sliderIdle
}

enum ScreenState {
    case normal
    case full
}

class RWVideoController: UIViewController {
    fileprivate var videoUrlString: String?
    fileprivate var videoPlayer: AVPlayer?
    fileprivate var videoItem: AVPlayerItem?
    fileprivate var videoLayer: AVPlayerLayer?
    fileprivate var currentPlayhead: CMTime = .zero
    fileprivate var timeObserverToken: Any?
    
    var videoState: PlayerState = .ready
    var sliderState: SliderState = .sliderIdle
    var screenState: ScreenState = .normal
    var videoQualities: [[String: Any]]?
    
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var controlShadowView: UIView!
    @IBOutlet weak var controlButton: UIButton!
    @IBOutlet weak var controlLayerView: UIView!
    @IBOutlet weak var controlFullscreenButton: UIButton!
    @IBOutlet weak var controlQualityButton: UIButton!
    @IBOutlet weak var controlQualityView: UITableView!
    @IBOutlet weak var controlSlider: UISlider!
    @IBOutlet weak var controlQualityViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var controlQualityViewHeightConstraint: NSLayoutConstraint!
    
    convenience init(videoUrl: String) {
        self.init()
        let nib = loadNibController()
        if nib != nil{
            self.view = nib![0] as? UIView
        }
        
        self.videoUrlString = videoUrl
        self.createPlayer()
        self.setupQuality()
    }
    
    convenience init(defaultVideo: String, qualities: [[String: Any]]?) {
        self.init()
        let nib = loadNibController()
        if nib != nil{
            self.view = nib![0] as? UIView
        }
        
        self.videoUrlString = defaultVideo
        self.videoQualities = qualities
        
        self.setupQuality()
        self.createPlayer()
    }
    
    fileprivate func loadNibController() -> [AnyObject]?{
        let podBundle = Bundle(for: self.classForCoder)
        
        if let bundleURL = podBundle.url(forResource: "RWVideoController", withExtension: "bundle"){
            
            if let bundle = Bundle(url: bundleURL) {
                return bundle.loadNibNamed("RWVideoController", owner: self, options: nil) as [AnyObject]?
            }
            else {
                assertionFailure("Could not load the bundle")
            }
            
        }
        else if let nib = podBundle.loadNibNamed("RWVideoController", owner: self, options: nil) as [AnyObject]?{
            return nib
        }
        else{
            assertionFailure("Could not create a path to the bundle")
        }
        return nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.view.backgroundColor = .black
        self.controlFullscreenButton.setTitle(screenState == .normal ? "Fullscreen" : "Exit fullscreen", for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let layer = self.videoLayer else { return }
        layer.frame = self.controlLayerView.frame
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func controlButtonAction(_ sender: Any) {
        guard let player = self.videoPlayer else { return }
        
        if player.rate == 1 {
            pause()
        } else {
            play()
        }
    }
    
    @IBAction func controllFullscreenAction(_ sender: Any) {
        if screenState == .full {
            self.pause()
            self.dismiss(animated: true) {
            }
            return
        }
        
        guard let videoUrl = self.videoUrlString else { return }
        let controller = RWVideoController(defaultVideo: videoUrl, qualities: self.videoQualities)
        controller.videoLayer?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.width * 0.5625)
        controller.screenState = .full
        controller.seekPlayhead(to: self.currentPlayhead)
        
        self.pause()
        
        self.parent?.present(controller, animated: false, completion: nil)
    }
    
    @IBAction func controlQualityAction(_ sender: Any) {
        showQualityControl()
    }
}

extension RWVideoController {
    fileprivate func createPlayer() {
        guard let rawVideoUrl = videoUrlString, let videoUrl = URL(string: rawVideoUrl)  else { return }
        
        self.videoItem = AVPlayerItem(url: videoUrl)
        self.videoPlayer = AVPlayer(playerItem: self.videoItem)
        self.videoLayer = AVPlayerLayer(player: videoPlayer)
        self.videoLayer?.frame = self.controlLayerView.frame
        
        guard let layer = self.videoLayer else { return }
        self.view.layer.insertSublayer(layer, at: 0)
        
        self.setupSlider()
    }
    
    fileprivate func play() {
        guard let player = self.videoPlayer else { return }
        player.play()
        controlButton.setTitle("Pause", for: .normal)
        videoState = .played
    }
    
    fileprivate func pause() {
        guard let player = self.videoPlayer else { return }
        player.pause()
        controlButton.setTitle("Play", for: .normal)
        videoState = .paused
    }
    
    fileprivate func seekPlayhead(to: CMTime) {
        guard let player = self.videoPlayer else { return }
        player.seek(to: to, toleranceBefore: .zero, toleranceAfter: .zero) { (status) in
            self.play()
        }
    }
}

extension RWVideoController {
    fileprivate func setupQuality() {
        // qualities
        controlQualityView.isHidden = true
        guard let qualities = self.videoQualities else {
            controlQualityButton.isEnabled = false
            controlQualityView.isHidden = true
            return
        }
        
        if qualities.count > 0 {
            controlQualityViewHeightConstraint.constant = CGFloat(qualities.count * 44)
            controlQualityButton.isEnabled = true
        }
    }
    
    fileprivate func changeQuality(videoUrl: String) {
        guard let url = URL(string: videoUrl) else { return }
        let playerItem = AVPlayerItem(url: url)
        self.videoPlayer?.replaceCurrentItem(with: playerItem)
        self.seekPlayhead(to: self.currentPlayhead)
    }
    
    fileprivate func showQualityControl() {
        if controlQualityViewBottomConstraint.constant == 0 {
            guard let qualities = self.videoQualities else {
                controlQualityView.isHidden = false
                controlQualityViewBottomConstraint.constant = 0
                return
            }
            
            controlQualityView.isHidden = true
            controlQualityViewBottomConstraint.constant = CGFloat(qualities.count * 44)
            return
        }
        
        controlQualityView.isHidden = false
        controlQualityViewBottomConstraint.constant = 0
    }
    
    fileprivate func setupSlider() {
        self.controlSlider.minimumValue = 0
        self.controlSlider.isContinuous = false
        self.controlSlider.addTarget(self, action: #selector(playbackSliderChanged(_:)), for: .valueChanged)
        guard let player = self.videoPlayer, let duration = player.currentItem?.asset.duration else { return }
        
        let seconds = Float(CMTimeGetSeconds(duration))
        
        if !seconds.isNaN {
            self.controlSlider.maximumValue = seconds
            self.getReadableFormat(currendSeconds: 0, duration: Int(seconds))
            
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (timeInterval) in
                if player.currentItem?.status == .readyToPlay {
                    if self.sliderState == .sliderIdle {
                        let currentDuration = CMTimeGetSeconds(player.currentTime())
                        self.currentPlayhead = player.currentTime()
                        self.controlSlider.setValue(Float(currentDuration), animated: true)
                        self.getReadableFormat(currendSeconds: Int(currentDuration), duration: Int(seconds))
                    }
                }
            }
        } else {
            self.controlSlider.isHidden = true
            self.startTimeLabel.isHidden = true
            self.endTimeLabel.text = "Live"
        }
    }
    
    func convertSecondsToReadableFormat(seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func getReadableFormat(currendSeconds: Int, duration: Int) {
        let currentTime = convertSecondsToReadableFormat(seconds: currendSeconds)
        let endTime = convertSecondsToReadableFormat(seconds: duration)
        
        let currentHour = currentTime.0 < 10 ? "0\(currentTime.0)" : "\(currentTime.0)"
        let currentMinute = currentTime.1 < 10 ? "0\(currentTime.1)" : "\(currentTime.1)"
        let currentSecond = currentTime.2 < 10 ? "0\(currentTime.2)" : "\(currentTime.2)"
        
        let startTimeString = "\(currentHour):\(currentMinute):\(currentSecond)"
        self.startTimeLabel.text = startTimeString
        
        let endHour = endTime.0
        let endMinute = endTime.1
        let endSecond = endTime.2
        
        let endTimeString = "\(endHour > 0 ? "\(endHour):": "")\(endMinute):\(endSecond)"
        self.endTimeLabel.text = endTimeString
    }
    
    @objc fileprivate func playbackSliderChanged(_ playbackSlider: UISlider) {
        guard let player = self.videoPlayer else { return }
        
        player.pause()
        sliderState = .sliderBeingSeek
        
        let seconds: Int64 = Int64(playbackSlider.value)
        let targetTime: CMTime = CMTimeMakeWithSeconds(Float64(Float(seconds)), preferredTimescale: 1)
        
        player.seek(to: targetTime)
        
        if player.rate == 0 {
            player.play()
            sliderState = .sliderIdle
        }
    }
}

extension RWVideoController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let qualities = self.videoQualities else { return 0 }
        return qualities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        guard let qualities = self.videoQualities else { return cell }
        
        let item = qualities[indexPath.row]
        cell.textLabel?.text = item.keys.first
        return cell
    }
}

extension RWVideoController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let qualities = self.videoQualities else { return }
        
        let item = qualities[indexPath.row]
        if let key = item.keys.first, let content = item[key] as? String {
            changeQuality(videoUrl: content)
        }
        
        showQualityControl()
    }
}

extension UINavigationController {
    
    override open var shouldAutorotate: Bool {
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.shouldAutorotate
            }
            return super.shouldAutorotate
        }
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation{
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.preferredInterfaceOrientationForPresentation
            }
            return super.preferredInterfaceOrientationForPresentation
        }
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        get {
            if let visibleVC = visibleViewController {
                return visibleVC.supportedInterfaceOrientations
            }
            return super.supportedInterfaceOrientations
        }
    }}
