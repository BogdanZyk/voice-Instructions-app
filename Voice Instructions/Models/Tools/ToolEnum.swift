//
//  ToolEnum.swift
//  Voice Instructions
//
//

import SwiftUI

enum ToolEnum: Int, CaseIterable{
    
    case arrow, line, angle, polyLine, circle, rectangle, timer
    
    
    var shapeType: DragShape.ShapeType?{
    
        switch self {
        case .arrow: return .arrow
        case .line: return .line
        case .circle: return .circle
        case .rectangle: return .rectangle
        default: return nil
        }
    }
    
    var isShapeTool: Bool{
        switch self {
        case .arrow, .line, .circle, .rectangle: return true
        default: return false
        }
    }
    
    var image: String{
        switch self {
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .angle: return "angle"
        case .polyLine: return "scribble"
        case .circle: return "circle"
        case .rectangle: return "rectangle"
        case .timer: return "timer"
        }
    }
    var iconColor: Color{
        switch self {
        case .arrow: return .red
        case .line, .angle, .polyLine, .circle: return .yellow
        case .timer, .rectangle: return .green
        }
    }
}
