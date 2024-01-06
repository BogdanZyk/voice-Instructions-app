//
//  VideoTrimBarView.swift
//  Voice Instructions
//
//

import SwiftUI

struct VideoTrimBarView: View {
    @State var isChangeTrimSlider: Bool = false
    @Binding private var editedRange: ClosedRange<Double>
    @Binding var currentTime: Double
    private let videoRange: ClosedRange<Double>
    private let thumbnailsImages: [ThumbnailImage]
    private let trimBarHeight: CGFloat = 70
    let seek: (Double) -> Void
    let onTapTrim: () -> Void
    
    init(videoRange: ClosedRange<Double>,
         thumbnailsImages: [ThumbnailImage],
         editedRange: Binding<ClosedRange<Double>>,
         currentTime: Binding<Double>,
         onTapTrim: @escaping () -> Void,
         seek: @escaping (Double) -> Void
    ){
        self._currentTime = currentTime
        self._editedRange = editedRange
        self.videoRange = videoRange
        self.onTapTrim = onTapTrim
        self.thumbnailsImages = thumbnailsImages
        self.seek = seek
    }
    
    var body: some View {
        ZStack{
            GeometryReader { proxy in
                thumbnailsImagesSection(weight: proxy.size.width)
                    .vCenter()
            }
            RangedSliderView(value: $editedRange,
                             bounds: videoRange,
                             onChange: onChangeTrimTime,
                             thumbView: {
                GeometryReader { proxy in
                    Rectangle()
                        .blendMode(.destinationOut)
                    timeSlider(size: proxy.size)
                        .opacity(isChangeTrimSlider ? 0 : 1)
                }
            })
        }
        .frame(height: trimBarHeight)
        .onChange(of: editedRange.lowerBound, perform: updateSeekAndTime)
        .onChange(of: editedRange.upperBound, perform: updateSeekAndTime)
    }
}

struct VideoTrimBarView_Previews: PreviewProvider {
    static var previews: some View {
        VideoTrimBarView.TestView()
            .padding(20)
    }
}


extension VideoTrimBarView{
    
    private func thumbnailsImagesSection(weight: CGFloat) -> some View{
        HStack(spacing: 0){
            ForEach(thumbnailsImages) { trimData in
                if let image = trimData.image{
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: weight / CGFloat(thumbnailsImages.count))
                        .clipped()
                }
            }
        }
        .onTapGesture {
           onTapTrim()
        }
    }
    
    
    private func timeSlider(size: CGSize) -> some View{
        CustomSlider(
            value: Binding(get: {
                currentTime
            }, set: { newValue in
                currentTime = newValue
                seek(newValue)
            }),
            in: editedRange,
            track: {
                Rectangle()
                    .foregroundColor(Color.clear)
                    .frame(width: size.width, height: size.height)
            }, fill: {
                Rectangle()
                    .foregroundColor(Color.clear)
            }, thumb: {
                Capsule()
                    .foregroundColor(.red)
                    .overlay(alignment: .top) {
                        Image(systemName: "arrowtriangle.down.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 10))
                            .offset(y: -11)
                    }
                    .overlay {
                        Color.clear
                            .frame(width: 50)
                            .contentShape(Rectangle())
                    }
            }, thumbSize: CGSize(width: 6, height: size.height)
        )
    }
    
    private func updateSeekAndTime(_ value: Double){
        seek(value)
        currentTime = value
    }
    
    private func onChangeTrimTime(_ isChange: Bool){
        isChangeTrimSlider = isChange
    }
}


extension VideoTrimBarView{
    
    
    struct TestView: View{
        
        @State var currentTime: Double = 2.10
        @State var editedRange: ClosedRange<Double> = 0...10
        var body: some View{
            VideoTrimBarView(videoRange: 0...10, thumbnailsImages: ThumbnailImage.mock, editedRange: $editedRange, currentTime: $currentTime, onTapTrim: {}, seek: {_ in})
        }
    }
    
}
