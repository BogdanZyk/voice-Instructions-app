//
//  ScrubbingBarView.swift
//  Voice Instructions
//
//

import SwiftUI

struct ScrubbingBarView: View {
    var duration: CGFloat
    @Binding var time: Double
    let onChangeTime: (Double) -> Void
    @State private var lastOffset: CGFloat = .zero
    let colors: [Color] = [.black, .black.opacity(0.7), .black.opacity(0.45), .clear]
    var body: some View {
    
        ZStack {
            InfinityHScrollView(alignment: .center, onChange: onChange, onEnded: onEnded){
                imagesSection
            }
            HStack{
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                Spacer()
                LinearGradient(colors: colors, startPoint: .trailing, endPoint: .leading)
            }
            .allowsHitTesting(false)
        }
        .frame(height: 60)
    }
}

struct ScrubbingBarView_Previews: PreviewProvider {

    static var previews: some View {
        TestView()
    }
}


extension ScrubbingBarView{
    private var imagesSection: some View{
        HStack(spacing: 0){
            ForEach(1...10, id: \.self) { _ in
                Image("scrubbingImage")
            }
        }
    }
    
    private func onChange(dragOffset: CGFloat){
        updateTime(dragValue: dragOffset, dragDuration: 0)
    }
    
    private func onEnded(dragValue: CGFloat, dragDuration: CGFloat){
        updateTime(dragValue: dragValue, dragDuration: dragDuration)
    }
    
    private func updateTime(dragValue: CGFloat, dragDuration: CGFloat){
        
        let isAnimation = dragDuration >= 0.55
        let increaseValue = isAnimation ? 1.5 : 0.005
        
        if lastOffset > dragValue{
            time = max(time - increaseValue, 0)
        }else{
            time = min(time + increaseValue, duration)
        }
        
        lastOffset = dragValue
        
        onChangeTime(time)
    }
}


struct TestView: View{
    @State  var time: Double = 0
    var body: some View{
        ZStack{
            Color.black
            VStack {
                Text(time.humanReadableLongTime())
                    .foregroundColor(.white)
                ScrubbingBarView(duration: 15, time: $time, onChangeTime: {_ in})
            }
        }
    }
}
