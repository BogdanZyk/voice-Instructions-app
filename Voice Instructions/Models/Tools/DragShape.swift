//
//  DragShape.swift
//  Voice Instructions
//
//

import SwiftUI


protocol LayerElement{
    
    var isActive: Bool { get set }
    var isSelected: Bool { get set }
    var location: CGPoint { get set }
    var color: Color { get set }
    var id: UUID { get set }
    var lineWeight: CGFloat { get }
    
    mutating func deactivate()
}

struct DragShape: Identifiable, LayerElement{
    
    var id: UUID = UUID()
    var isActive = false
    var isSelected = false
    var type: ShapeType
    var location: CGPoint
    var startLocation: CGPoint
    var endLocation: CGPoint
    var size: CGSize = .zero
    var color: Color
    var lineWeight: CGFloat{
        isActive || isSelected ? 5 : 3
    }
    
    init(type: ShapeType,
         location: CGPoint,
         color: Color,
         size: CGSize = .zero,
         endLocation: CGPoint = .zero) {
        self.type = type
        self.location = location
        self.startLocation = location
        self.color = color
        self.size = size
        self.endLocation = endLocation
    }
    
    
    var isShapeType: Bool{
        type == .circle || type == .rectangle
    }
    
    mutating func deactivate(){
        isActive = false
        isSelected = false
    }
    
    enum ShapeType: Int {
        
        case line, arrow, circle, rectangle
    }
}
