//
//  AVAudioSession.swift
//  Voice Instructions
//
//

import AVFoundation

extension AVAudioSession{
    
    /// Configuring play and record session
    func playAndRecord(){
        print("Configuring playAndRecord session")
        do {
            try self.setCategory(.playAndRecord, mode: .default)
            try self.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            try self.setActive(true)
        } catch{
            print("Error while configuring audio session: \(error.localizedDescription)")
        }
    }
    
    /// Configuring record session
    func configureRecordAudioSessionCategory() {
      print("Configuring record session")
      do {
          try self.setCategory(.record, mode: .default)
          try self.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
          try self.setActive(true)
      } catch{
          print("Error while configuring audio session: \(error.localizedDescription)")
      }
    }
    
    /// Configuring playback session
    func configurePlaybackSession(){
        print("Configuring playback session")
        do {
            try self.setCategory(.playback, mode: .default)
            try self.overrideOutputAudioPort(.none)
            try self.setActive(true)
        } catch{
            print("Error while configuring audio session: \(error.localizedDescription)")
        }
    }
}

