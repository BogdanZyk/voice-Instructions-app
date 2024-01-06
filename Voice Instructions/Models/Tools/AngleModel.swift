//
//  AngleModel.swift
//  Voice Instructions
//
//

import SwiftUI


struct AngleModel: Identifiable, LayerElement{

    var id: UUID = UUID()
    var location: CGPoint
    var isSelected: Bool = false
    var isActive: Bool = true
    var color: Color = .red
    var endPointFirstLine: CGPoint = .init(x: 200, y: 200)
    var endPointSecondLine: CGPoint = .init(x: 200, y: 50)
    var lineWeight: CGFloat{
        isActive || isSelected ? 5 : 3
    }
    
    func angleBetweenLines() -> CGFloat {
        let startPoint = location
        let angle1 = atan2(endPointFirstLine.y - startPoint.y, endPointFirstLine.x - startPoint.x)
        let angle2 = atan2(endPointSecondLine.y - startPoint.y, endPointSecondLine.x - startPoint.x)
        var angle = angle1 - angle2
        if angle < 0 {
            angle += 2 * .pi
        }
        return angle
    }
    
    mutating func deactivate() {
        isSelected = false
        isActive = false
    }
    
    
    init(location: CGPoint, color: Color) {
        self.location = location
        self.color = color
        self.endPointFirstLine = .init(x: location.x + 50, y: location.y + 50)
        self.endPointSecondLine = .init(x: location.x - 50, y: location.y + 50)
    }
    
    
    
}
