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
    case failed
}

enum SliderState {
    case sliderBeingSeek
    case sliderIdle
}

enum ScreenState {
    case normal
    case full
}

enum Observer: String {
    case status = "status"
    case bufferEmpty = "playbackBufferEmpty"
    case likelyToKeepUp = "playbackLikelyToKeepUp"
    case bufferFull = "playbackBufferFull"
}

class RWVideoController: UIViewController {
    fileprivate var videoUrlString: String?
    fileprivate var videoPlayer: AVPlayer?
    fileprivate var videoItem: AVPlayerItem?
    fileprivate var videoLayer: AVPlayerLayer?
    fileprivate var currentPlayhead: CMTime = .zero
    fileprivate var timeObserverToken: Any?
    fileprivate var fullscreenController: RWVideoController?
    fileprivate var timer = Timer()
    fileprivate let timerDuration = 2.0
    fileprivate var originRect: CGRect = .zero
    
    lazy var tap: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(sender:)))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        print("gesture_created")
        return gesture
        }()
    
    lazy var container: UIView = { [unowned self] in
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .red
        return view
    }()
    
    var videoState: PlayerState = .ready
    var sliderState: SliderState = .sliderIdle
    var screenState: ScreenState = .normal
    var videoQualities: [[String: Any]]?
    var delegate: RWVideoDelegate?
    var autoplay: Bool = false {
        didSet {
            if autoplay {
                self.play()
            }
        }
    }
    
    var presentAsFullscreen: Bool = false {
        didSet {
            if presentAsFullscreen {
                screenState = .full
                self.controlFullscreenButton.setTitle(screenState == .normal ? "Fullscreen" : "Exit fullscreen", for: .normal)
            }
        }
    }
    
    var controlShow: Bool = false {
        didSet {
            if controlShow {
                self.showControl()
            } else {
                self.hideControl()
            }
        }
    }
    
    @IBOutlet weak private var startTimeLabel: UILabel!
    @IBOutlet weak private var endTimeLabel: UILabel!
    @IBOutlet weak private var controlShadowView: UIView!
    @IBOutlet weak private var controlButton: UIButton!
    @IBOutlet weak private var controlLayerView: UIView!
    @IBOutlet weak private var controlFullscreenButton: UIButton!
    @IBOutlet weak private var controlQualityButton: UIButton!
    @IBOutlet weak private var controlQualityView: UITableView!
    @IBOutlet weak private var controlSlider: UISlider!
    @IBOutlet weak private var bufferIndicator: UIActivityIndicatorView!
    @IBOutlet weak private var controlQualityViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak private var controlQualityViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerView: UIView!
    
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
    
    override var isBeingPresented: Bool {
        return presentAsFullscreen
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.view.backgroundColor = .black
        self.controlFullscreenButton.setTitle(screenState == .normal ? "Fullscreen" : "Exit fullscreen", for: .normal)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        if self.presentingViewController?.presentedViewController == self {
            presentAsFullscreen = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.videoItem?.removeObserver(self, forKeyPath: Observer.status.rawValue)
        self.videoItem?.removeObserver(self, forKeyPath: Observer.bufferEmpty.rawValue)
        self.videoItem?.removeObserver(self, forKeyPath: Observer.likelyToKeepUp.rawValue)
        self.videoItem?.removeObserver(self, forKeyPath: Observer.bufferFull.rawValue)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let layer = self.videoLayer else { return }
        layer.frame = self.playerView.frame
    }
    
    deinit {
        self.videoItem?.removeObserver(self, forKeyPath: Observer.status.rawValue)
        self.videoItem?.removeObserver(self, forKeyPath: Observer.bufferEmpty.rawValue)
        self.videoItem?.removeObserver(self, forKeyPath: Observer.likelyToKeepUp.rawValue)
        self.videoItem?.removeObserver(self, forKeyPath: Observer.bufferFull.rawValue)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func controlButtonAction(_ sender: Any) {
        guard let player = self.videoPlayer else { return }
        
        stopTimer()
        if player.rate == 1 {
            pause()
        } else {
            play()
        }
        runTimer()
    }
    
    @IBAction func controllFullscreenAction(_ sender: Any) {
        if presentAsFullscreen {
            self.dismiss(animated: true, completion: nil)
        }
        
        if screenState == .full {
            exitFullscreen()
        } else {
            enterFullscreen()
        }
    }
    
    @IBAction func controlQualityAction(_ sender: Any) {
        showQualityControl()
    }
    
    @objc func canRotate() -> Void {
        // do nothing
        presentAsFullscreen = true
        self.screenState = .full
        self.controlFullscreenButton.setTitle(self.screenState == .normal ? "Fullscreen" : "Exit fullscreen", for: .normal)
    }
    
    @objc func playerDidFinish() -> Void {
        self.controlButton.setTitle("Replay", for: .normal)
        self.videoState = .finished
        self.showControl()
        delegate?.video(didFinishPlaying: self)
    }
    
    @objc func didTap(sender: UITapGestureRecognizer) -> Void {
        if controlShow {
            controlShow = false
        } else {
            controlShow = true
        }
    }
    
    func showControl() -> Void {
        self.controlLayerView.alpha = 1.0
        self.controlShadowView.alpha = 0.5
        self.controlLayerView.addGestureRecognizer(tap)
        self.playerView.removeGestureRecognizer(tap)
        self.runTimer()
    }
    
    @objc func hideControl() -> Void {
        self.controlLayerView.alpha = 0.0
        self.controlShadowView.alpha = 0.0
        self.controlLayerView.removeGestureRecognizer(tap)
        self.playerView.addGestureRecognizer(tap)
    }
}

// MARK: Setup
extension RWVideoController {
    fileprivate func createPlayer() {
        guard let rawVideoUrl = videoUrlString, let videoUrl = URL(string: rawVideoUrl)  else { return }
        
        self.videoItem = AVPlayerItem(url: videoUrl)
        self.videoPlayer = AVPlayer(playerItem: self.videoItem)
        self.videoLayer = AVPlayerLayer(player: videoPlayer)
        self.videoLayer?.frame = self.playerView.frame
        
        self.videoItem?.addObserver(self, forKeyPath: Observer.status.rawValue, options: .new, context: nil)
        self.videoItem?.addObserver(self, forKeyPath: Observer.bufferEmpty.rawValue, options: .new, context: nil)
        self.videoItem?.addObserver(self, forKeyPath: Observer.likelyToKeepUp.rawValue, options: .new, context: nil)
        self.videoItem?.addObserver(self, forKeyPath: Observer.bufferFull.rawValue, options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        guard let layer = self.videoLayer else { return }
        self.playerView.layer.insertSublayer(layer, at: 0)
        self.playerView.backgroundColor = .black
        
        self.setupSlider()
        bufferIndicator.stopAnimating()
        self.controlLayerView.addGestureRecognizer(tap)
    }
    
    func runTimer() -> Void {
        if videoState == .played {
            timer = Timer.scheduledTimer(timeInterval: timerDuration, target: self, selector: #selector(hideControl), userInfo: nil, repeats: false)
        }
    }
    
    func stopTimer() -> Void {
        timer.invalidate()
    }
    
    fileprivate func play() {
        guard let player = self.videoPlayer else { return }
        player.play()
        
        if videoState == .finished {
            seekPlayhead(to: .zero)
        }
        stopTimer()
        controlButton.setTitle("Pause", for: .normal)
        videoState = .played
        delegate?.videoStateDidChange(self, state: videoState)
        runTimer()
    }
    
    fileprivate func pause() {
        stopTimer()
        guard let player = self.videoPlayer else { return }
        player.pause()
        controlButton.setTitle("Play", for: .normal)
        videoState = .paused
        delegate?.videoStateDidChange(self, state: videoState)
        runTimer()
    }
    
    fileprivate func seekPlayhead(to: CMTime) {
        guard let player = self.videoPlayer else { return }
        player.seek(to: to, toleranceBefore: .zero, toleranceAfter: .zero) { (status) in
            self.play()
        }
    }
    
    fileprivate func enterFullscreen() -> Void {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                guard let window = UIApplication.shared.keyWindow else {
                    print("No root view on which to draw")
                    return
                }
                
                // 1. add container to window
                window.addSubview(self.container)
                
                // 2. remove player view then attach to window
                self.originRect = self.playerView.frame
                self.playerView.removeFromSuperview()
                window.addSubview(self.playerView)
                
                // 3. adjust autolayout according to window
                self.playerView.translatesAutoresizingMaskIntoConstraints = true
                self.playerView.frame = window.frame
                
                self.screenState = .full
                self.controlFullscreenButton.setTitle(self.screenState == .normal ? "Fullscreen" : "Exit fullscreen", for: .normal)
                self.delegate?.videoDidEnterFullscreen()
            })
        }
    }
    
    fileprivate func exitFullscreen() -> Void {
        UIView.animate(withDuration: 0.3) {
            // 1. remove container and playerView from window
            self.container.removeFromSuperview()
            self.playerView.removeFromSuperview()
            
            // 2. adjust playerView frame to originRect
            self.playerView.transform = .identity
            
            // 3. add playerview to view
            self.view.addSubview(self.playerView)
            
            // 4. adjust autolayout according to view
            self.playerView.frame = self.originRect
            
            self.screenState = .normal
            self.delegate?.videoDidExitFullscreen()
            self.originRect = .zero
            self.controlFullscreenButton.setTitle(self.screenState == .normal ? "Fullscreen" : "Exit fullscreen", for: .normal)
        }
    }
    
    @objc func orientationDidChange(notification: NotificationCenter) -> Void {
        if screenState == .normal {
            return
        }
        
        let orientation = UIDevice.current.orientation
        let screenRect = UIScreen.main.bounds
        
        switch orientation {
        case .landscapeLeft:
            UIView.animate(withDuration: 0.2) {
                let rotationDegrees =  90.0
                let rotationAngle = CGFloat(rotationDegrees * .pi / 180.0)

                // 1. transform playerview
                self.playerView.transform = CGAffineTransform(rotationAngle: rotationAngle)
                
                // 2. adjust playerView autolayout
                self.playerView.translatesAutoresizingMaskIntoConstraints = true
                self.playerView.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
                self.videoLayer?.frame = self.playerView.bounds
            }
            print("orientation_landscapeLeft")
            break
        case .landscapeRight:
            let rotationDegrees =  -90.0
            let rotationAngle = CGFloat(rotationDegrees * .pi / 180.0)
            
            self.playerView.transform = CGAffineTransform(rotationAngle: rotationAngle)
            self.playerView.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
            self.videoLayer?.frame = self.playerView.bounds
            print("orientation_landscapeRight")
            break
        default:
            UIView.animate(withDuration: 0.2) {
                self.playerView.transform = .identity
                self.playerView.frame = screenRect
                self.videoLayer?.frame = self.playerView.bounds
            }
            
            print("orientation_force_portrait")
        }
        
    }
    
    internal override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is AVPlayerItem {
            guard let playerItem = object as? AVPlayerItem else { return }
            
            switch keyPath {
            case Observer.bufferEmpty.rawValue:
                self.bufferIndicator.startAnimating()
                self.controlButton.isHidden = true
                self.videoState = .buffer
                self.showControl()
            case Observer.bufferFull.rawValue:
                self.bufferIndicator.stopAnimating()
                self.controlButton.isHidden = false
                self.videoState = .played
                self.showControl()
            case Observer.likelyToKeepUp.rawValue:
                self.bufferIndicator.stopAnimating()
                self.controlButton.isHidden = false
                self.videoState = .played
                self.showControl()
            case Observer.status.rawValue:
                switch playerItem.status {
                case .unknown:
                    self.controlButton.setTitle("Retry", for: .normal)
                    self.controlButton.isHidden = false
                    self.videoState = .failed
                    self.showControl()
                case .failed:
                    self.controlButton.setTitle("Retry", for: .normal)
                    self.controlButton.isHidden = false
                    self.videoState = .failed
                    self.showControl()
                case .readyToPlay:
                    self.controlButton.isHidden = false
                    self.videoState = .ready
                    self.showControl()
                @unknown default:
                    print("playerItem unknown")
                }
            default:
                print("do nothing")
            }
        }
    }
}

extension RWVideoController {
    fileprivate func setupQuality() {
        // qualities
        controlQualityView.isHidden = true
        guard let qualities = self.videoQualities else {
            controlQualityButton.isEnabled = false
            controlQualityButton.isHidden = true
            controlQualityView.isHidden = true
            return
        }
        
        if qualities.count > 0 {
            controlQualityViewHeightConstraint.constant = CGFloat(qualities.count * 44)
            controlQualityButton.isEnabled = true
            controlQualityButton.isHidden = false
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
        self.controlSlider.addTarget(self, action: #selector(playbackSliderChanged(_:)), for: .valueChanged)
        guard let player = self.videoPlayer, let duration = player.currentItem?.asset.duration else {
            return
        }
        
        let seconds = Float(CMTimeGetSeconds(duration))
        
        if !seconds.isNaN {
            self.controlSlider.maximumValue = seconds
            self.updateTimeLabel(currendSeconds: 0, duration: Int(seconds))
            
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (timeInterval) in
                guard let playerItem = player.currentItem else {
                    self.videoState = .failed
                    return
                }
                
                if playerItem.status == .readyToPlay {
                    if self.sliderState == .sliderIdle {
                        self.videoState = .ready
                        let currentDuration = CMTimeGetSeconds(player.currentTime())
                        self.currentPlayhead = player.currentTime()
                        self.controlSlider.setValue(Float(currentDuration), animated: true)
                        self.updateTimeLabel(currendSeconds: Int(currentDuration), duration: Int(seconds))
                        
                        self.delegate?.video(self, currentDuration: self.currentPlayhead, totalDuration: duration)
                    }
                } else if playerItem.status == .failed {
                    self.videoState = .failed
                }
            }
        } else {
            self.controlSlider.isHidden = true
            self.startTimeLabel.isHidden = true
            self.endTimeLabel.text = "Live"
        }
    }
    
    func updateTimeLabel(currendSeconds: Int, duration: Int) {
        let readableFormat = RWTimeFormatter.getReadableFormat(currendSeconds: currendSeconds, duration: duration)
        self.startTimeLabel.text = readableFormat.0
        self.endTimeLabel.text = readableFormat.1
    }
    
    @objc fileprivate func playbackSliderChanged(_ playbackSlider: UISlider) {
        guard let player = self.videoPlayer else { return }
        
        if playbackSlider.isTracking {
            stopTimer()
            pause()
            sliderState = .sliderBeingSeek
            delegate?.video(self, sliderState: sliderState)
            return
        }
        
        let seconds: Int64 = Int64(playbackSlider.value)
        let targetTime: CMTime = CMTimeMakeWithSeconds(Float64(Float(seconds)), preferredTimescale: 1)
        
        player.seek(to: targetTime) { (seekComplete) in
            if player.rate == 0 {
                self.play()
                self.runTimer()
                self.sliderState = .sliderIdle
                self.delegate?.video(self, sliderState: self.sliderState)
            }
        }
    }
}

// MARK: tablview delegate & datasource
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

// MARK: tap delegate
extension RWVideoController: RWGestureProtocol {
    func gestureHandlerDidTap() {
        if controlShow {
            controlShow = false
        } else {
            controlShow = true
        }
    }
}

// MARK: app delegate
extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let rootViewController = self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController) as? RWVideoController {
            if rootViewController.responds(to: #selector(RWVideoController.canRotate)) {
                // Unlock landscape view orientations for this view controller
                return .allButUpsideDown
            }
        }
        
        // Only allow portrait (standard behaviour)
        return .portrait;
    }
    
    func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController? {
        if (rootViewController == nil) { return nil }
        if rootViewController.isKind(of: UITabBarController.self) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UITabBarController).selectedViewController)
        } else if (rootViewController.isKind(of: UINavigationController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UINavigationController).visibleViewController)
        } else if (rootViewController.presentedViewController != nil) {
            return topViewControllerWithRootViewController(rootViewController: rootViewController.presentedViewController)
        }
        return rootViewController
    }
}
