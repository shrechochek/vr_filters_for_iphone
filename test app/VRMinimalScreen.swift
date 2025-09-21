import SwiftUI

struct VRMinimalScreen: View {
    @EnvironmentObject var camera: CameraModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = camera.image {
                    let landscapeW = max(geo.size.width, geo.size.height)
                    let landscapeH = min(geo.size.width, geo.size.height)

                    HStack(spacing: 0) {
                        VREyeView(image: image,
                                  ipd: CGFloat(-camera.ipd),
                                  mirror: false,
                                  scale: CGFloat(camera.imageScale),
                                  rotationDegrees: CGFloat(camera.rotationDegrees))
                            .frame(width: landscapeW / 2, height: landscapeH)
                            .clipped()

                        VREyeView(image: image,
                                  ipd: CGFloat(camera.ipd),
                                  mirror: false,
                                  scale: CGFloat(camera.imageScale),
                                  rotationDegrees: CGFloat(camera.rotationDegrees))
                            .frame(width: landscapeW / 2, height: landscapeH)
                            .clipped()
                    }
                    .frame(width: landscapeW, height: landscapeH)
                    .rotationEffect(geo.size.width < geo.size.height ? .degrees(90) : .degrees(0))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .scaleEffect(1.0)
                }
            }
            .onAppear {
                camera.requestPermissionAndStart()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                dismiss()
            }
        }
        .statusBarHidden(true)
    }
}

// Переименование EyeView -> VREyeView, чтобы не конфликтовать с уже существующими типами
struct VREyeView: View {
    let image: UIImage
    let ipd: CGFloat
    let mirror: Bool
    let scale: CGFloat
    let rotationDegrees: CGFloat

    var body: some View {
        GeometryReader { g in
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: g.size.width * scale, height: g.size.height * scale)
                .rotationEffect(.degrees(Double(rotationDegrees)))
                .offset(x: ipd)
                .rotationEffect(.degrees(180.0))
                .scaleEffect(x: mirror ? -1.0 : 1.0, y: 1.0, anchor: .center)
        }
        .clipped()
    }
}
