//
//  View.swift
//  Voice Instructions
//
//

import SwiftUI

extension View{
    
    
    /// Get bounds screen
    func getRect() -> CGRect{
        return UIScreen.main.bounds
    }
    
    /// Vertical Center
    func vCenter() -> some View{
        self
            .frame(maxHeight: .infinity, alignment: .center)
    }
    /// Vertical Top
    func vTop() -> some View{
        self
            .frame(maxHeight: .infinity, alignment: .top)
    }
    
    /// Vertical Bottom
    func vBottom() -> some View{
        self
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
    /// Horizontal Center
    func hCenter() -> some View{
        self
            .frame(maxWidth: .infinity, alignment: .center)
    }
    /// Horizontal Leading
    func hLeading() -> some View{
        self
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    /// Horizontal Trailing
    func hTrailing() -> some View{
        self
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    /// All frame
    func allFrame() -> some View{
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Off animation for view
    func withoutAnimation() -> some View {
        self.animation(nil, value: UUID())
    }
    
    var isSmallScreen: Bool{
        getRect().height < 700
    }
}


struct MaskOptionallyViewModifier<C>: ViewModifier where C: View {

    var isActive: Bool
    @ViewBuilder var view: C
    
    func body(content: Content) -> some View {
        if isActive{
            content
                .mask {
                    view
                }
        }else{
            content
        }
    }
}

extension View{
    
    func maskOptionally<Mask>(isActive: Bool, @ViewBuilder mask: () -> Mask) -> some View where Mask : View{
        self
            .modifier(MaskOptionallyViewModifier(isActive: isActive, view: mask))
    }
    
    @ViewBuilder
    func positionOptionally(_ point: CGPoint?) -> some View{
        if let point{
            self.position(point)
        }else{
            self
        }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}



extension View{
    
    func frame(size: CGSize) -> some View{
        self
            .frame(width: size.width, height: size.height)
    }
    
}


struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

struct MeasureSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self,
                                   value: geometry.size)
        })
    }
}

extension View {
    func getSize(perform action: @escaping (CGSize) -> Void) -> some View {
        self.modifier(MeasureSizeModifier())
            .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}
