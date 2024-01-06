//
//  Stroke.swift
//  Voice Instructions
//
//

import Foundation
import SwiftUI

struct Stroke: Identifiable {
    var id: UUID = UUID()
    var points = [CGPoint]()
    var color = Color.red
    var width: CGFloat = 3
}
