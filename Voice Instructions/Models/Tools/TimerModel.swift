//
//  TimerModel.swift
//  Voice Instructions
//
//

import SwiftUI

struct TimerModel: Identifiable, LayerElement{
    
    var id: UUID = UUID()
    var isActive: Bool = false
    var location: CGPoint
    var isSelected: Bool = false
    var activateTime: Double
    var color: Color
    var lineWeight: CGFloat{
        isActive || isSelected ? 5 : 3
    }
    
    mutating func setNewTime(_ time: Double){
        activateTime = time
    }
    
    mutating func deactivate(){
        isSelected = false
        isActive = false
    }
}

