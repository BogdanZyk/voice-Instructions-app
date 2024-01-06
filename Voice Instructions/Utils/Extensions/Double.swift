//
//  Double.swift
//  Voice Instructions
//
//

import Foundation

extension Double{
    
    
    /// Time string format
    /// - Returns: 01.23 or 01:02.45
    func humanReadableLongTime() -> String {

        let time = Int(self)

        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 100)
        let seconds = time % 60
        let minutes = (time / 60) % 60
    
        return minutes == 0 ?
        String(format: "%0.2d.%0.2d", seconds, ms) :
        String(format: "%0.2d:%0.2d.%0.2d", minutes, seconds, ms)
        
    }

    /// Short time
    /// - Returns: 02:22
    func humanReadableShortTime() -> String{
        let minutes = Int(self / 60)
          let seconds = Int(self.truncatingRemainder(dividingBy: 60))
          return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    func timerTime() -> String{
        let time = Int(self)

        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
            
        return String(format: "%0.2d:%0.2d.%0.3d", abs(minutes), abs(seconds), abs(ms))
        
    }
    
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension CGFloat{

    func rad2deg() -> Double {
        return self * 180 / Double.pi
    }
    
}
