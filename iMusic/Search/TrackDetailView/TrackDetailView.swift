//
//  TrackDetailView.swift
//  iMusic
//
//  Created by MacBookPro on 24.02.2021.
//

import UIKit
import SDWebImage
import AVKit

protocol TrackMovingDelegate {
    func moveBackForPreviousTrack() -> SearchViewModel.Cell?
    func moveForwardForPreviousTrack() -> SearchViewModel.Cell?
}

class TrackDetailView: UIView {
    
    @IBOutlet weak var miniTrackView: UIView!
    @IBOutlet weak var miniGoForwardButton: UIButton!
    @IBOutlet weak var maximizedStackView: UIStackView!
    @IBOutlet weak var miniTrackImageView: UIImageView!
    @IBOutlet weak var miniTrackTitleLabel: UILabel!
    @IBOutlet weak var miniPlayPauseButton: UIButton!
    
    
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var curentTimeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var authorTitleLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    
    let player: AVPlayer = {
       
        let avPlayer = AVPlayer()
        avPlayer.automaticallyWaitsToMinimizeStalling = false
        return avPlayer
        
    }()
    
    var delegate: TrackMovingDelegate?
    weak var tabBarDelegate: MainTabBarControllerDelegate?
    
    // MARK: - AwakeFromNib
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let scale: CGFloat = 0.8
        trackImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
    
        trackImageView.layer.cornerRadius = 5
        
        miniPlayPauseButton.imageEdgeInsets = .init(top: 11, left: 11, bottom: 11, right: 11)
        
        setupGestures()
        
    }
    
    // MARK: - Setup
    
    func set(viewModel: SearchViewModel.Cell) {
        
        miniTrackTitleLabel.text = viewModel.trackName
        trackTitleLabel.text = viewModel.trackName
        authorTitleLabel.text = viewModel.artistName
        playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)

        playTrack(previewUrl: viewModel.previewUrl)
        monitorTime()
        observerPlayerCurrentTime()
        
        let string600 = viewModel.iconUrlString?.replacingOccurrences(of: "100x100", with: "600x600")
        guard let url = URL(string: string600 ?? "") else { return }
        miniTrackImageView.sd_setImage(with: url, completed: nil)
        trackImageView.sd_setImage(with: url, completed: nil)
    }
    
    private func setupGestures() {
        
        miniTrackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximized)))
        miniTrackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismissalPan)))
    }
    
   
    
    private func playTrack(previewUrl: String?) {
        print(previewUrl ?? "nil")
        
        guard let url = URL(string: previewUrl ?? "") else { return }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        player.play()
    }
    
    // MARK: - Maximizing and minimizing gestures
    
    @objc private func handleTapMaximized() {
        print("tapping to max")
        self.tabBarDelegate?.maximizedTrackDetailController(viewModel: nil)
    }
    
    @objc private func handlePan(gesture: UIGestureRecognizer) {
        
        switch gesture.state {
       
        case .began:
            print("began")
        case .changed:
            handlePanChanged(gesture: gesture as! UIPanGestureRecognizer)
        case .ended:
            handlePanEnded(gesture: gesture as! UIPanGestureRecognizer)
        
        @unknown default:
            print("unknown default")
        }
        
    }
    
    private func handlePanChanged(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        self.transform = CGAffineTransform(translationX: 0, y: translation.y)
        
        let newAlpha = 1 + translation.y / 200
        self.miniTrackView.alpha = newAlpha < 0 ? 0 : newAlpha
        self.maximizedStackView.alpha = -translation.y / 200
    }
    
    private func handlePanEnded(gesture: UIPanGestureRecognizer) {
        
        let translation = gesture.translation(in: self.superview)
        let velocity = gesture.velocity(in: self.superview)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.transform = .identity
            if translation.y < -200 || velocity.y < -500 {
                self.tabBarDelegate?.maximizedTrackDetailController(viewModel: nil)
            } else {
                self.miniTrackView.alpha = 1
                self.maximizedStackView.alpha = 0
            }
            
        }, completion: nil)
        
    }
    
    @objc private func handleDismissalPan(gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        
        case .changed:
            let translation = gesture.translation(in: self.superview)
            maximizedStackView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        case .ended:
            let translation = gesture.translation(in: self.superview)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.maximizedStackView.transform = .identity
                
                if translation.y > 50 {
                    self.tabBarDelegate?.minimizedTrackDetailController()
                }
                
            }, completion: nil)
    
        @unknown default:
            print("unknown default")
        }
        
    }
    
    // MARK: - Time setup
    
    private func monitorTime() {
        
        let time = CMTimeMake(value: 1, timescale: 3)
        let times = [NSValue(time: time)]
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            self?.enlargeTrackImageView()
        }
    }
    
    private func observerPlayerCurrentTime() {
        let interval = CMTimeMake(value: 1, timescale: 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] (time) in
            self?.currentTimeLabel.text = time.toDisplayString()
            
            let durationTime = self?.player.currentItem?.duration
            let currentDurationText = ((durationTime ?? CMTimeMake(value: 1, timescale: 1)) - time).toDisplayString()
            self?.durationLabel.text = "-\(currentDurationText)"
            self?.updateCurrentTimeSlider()
        }
    }
    
    private func updateCurrentTimeSlider() {
        let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))
        let percentage = currentTimeSeconds / durationSeconds
        self.curentTimeSlider.value = Float(percentage)
    }
    
    // MARK: - Animation
    
    private func enlargeTrackImageView() {
        
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.trackImageView.transform = .identity
        }, completion: nil)
        
        
        
    }
    
    private func reduceTrackImageView() {
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            let scale: CGFloat = 0.8
            self.trackImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: nil)
        
    }
    
    
    // MARK: - IBActions
    
    @IBAction func dragDownButtonTapped(_ sender: Any) {
        
        self.tabBarDelegate?.minimizedTrackDetailController()
        
       // self.removeFromSuperview()
        
    }
    
    
    @IBAction func handleCurrentTimeSlider(_ sender: Any) {
        
        let percantage = curentTimeSlider.value
        guard let duration = player.currentItem?.duration else { return }
        let durationInSeconds = CMTimeGetSeconds(duration)
        let SeekTimeUnSeconds = Float64(percantage) * durationInSeconds
        let seekTime = CMTimeMakeWithSeconds(SeekTimeUnSeconds, preferredTimescale: 1)
        player.seek(to: seekTime)
        
        
        
    }
    
    @IBAction func handleVolumeSlider(_ sender: Any) {
        player.volume = volumeSlider.value
    }
    
    @IBAction func previousTrack(_ sender: Any) {
        
        let cellViewModel = delegate?.moveBackForPreviousTrack()
        guard let cellInfo = cellViewModel else { return }
        self.set(viewModel: cellInfo)
        
    }
    
    
    @IBAction func nextTrack(_ sender: Any) {
        
        let cellViewModel = delegate?.moveForwardForPreviousTrack()
        guard let cellInfo = cellViewModel else { return }
        self.set(viewModel: cellInfo)
    }
    
    
    @IBAction func playPauseAction(_ sender: Any) {
        
        if player.timeControlStatus == .paused {
            player.play()
            playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            miniPlayPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            enlargeTrackImageView()
        } else {
            player.pause()
            playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            miniPlayPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            reduceTrackImageView()
        }
        
    }
    
}
