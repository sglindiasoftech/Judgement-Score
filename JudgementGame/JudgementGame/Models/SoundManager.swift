import Foundation
import AudioToolbox
import AVFoundation
import UIKit

public class SoundManager {
    public static let shared = SoundManager()
    
    private init() {}
    
    /// Plays a bright, metallic bell sound chime (🛎️) + system bell sound + haptic feedback
    public func playBellAlertSound() {
        // 1. Play iOS System Bell Sound ID 1013 (Subway/Desk Bell) & 1005 (Calendar Alert Bell)
        AudioServicesPlayAlertSound(1013)
        
        // 2. Trigger warning haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        // 3. Synthesize crisp metallic bell ring (C6 + E6 + G6 overtones with fast exponential decay)
        playSynthesizedBell()
    }
    
    private func playSynthesizedBell() {
        DispatchQueue.global(qos: .userInitiated).async {
            let sampleRate: Double = 44100.0
            let duration: Double = 0.7
            let numSamples = Int(sampleRate * duration)
            
            var samples = [Float](repeating: 0, count: numSamples)
            let freq1: Double = 1046.5  // C6 bell fundamental
            let freq2: Double = 1318.51 // E6 bell overtone
            let freq3: Double = 1567.98 // G6 bell overtone
            let freq4: Double = 2093.00 // C7 shimmer
            
            for i in 0..<numSamples {
                let t = Double(i) / sampleRate
                // Metallic bell envelope: sharp attack + exponential ring decay
                let envelope = exp(-t * 5.5)
                let signal = (sin(2.0 * .pi * freq1 * t) * 0.45 +
                              sin(2.0 * .pi * freq2 * t) * 0.28 +
                              sin(2.0 * .pi * freq3 * t) * 0.18 +
                              sin(2.0 * .pi * freq4 * t) * 0.09)
                samples[i] = Float(signal * envelope * 0.8)
            }
            
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
                return
            }
            
            buffer.frameLength = AVAudioFrameCount(numSamples)
            if let channelData = buffer.floatChannelData {
                for i in 0..<numSamples {
                    channelData[0][i] = samples[i]
                }
            }
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true)
                
                let engine = AVAudioEngine()
                let player = AVAudioPlayerNode()
                engine.attach(player)
                engine.connect(player, to: engine.mainMixerNode, format: format)
                
                try engine.start()
                player.scheduleBuffer(buffer) {
                    engine.stop()
                }
                player.play()
                
                // Keep engine alive until playback finishes
                Thread.sleep(forTimeInterval: duration + 0.1)
            } catch {
                // Fallback to System Sound 1005 (Calendar Alert Bell)
                AudioServicesPlayAlertSound(1005)
            }
        }
    }
}
