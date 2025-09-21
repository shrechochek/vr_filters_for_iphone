import SwiftUI

struct VRScreen: View {
    @EnvironmentObject var camera: CameraModel
    @Environment(\.dismiss) private var dismiss

    @State private var ipd: CGFloat = 12.0
    @State private var mirrorRightEye: Bool = false
    @State private var showOverlayGuides: Bool = true

    var body: some View {
        GeometryReader { geo in
            // detect portrait vs landscape based on current geometry
            let isPortrait = geo.size.width < geo.size.height

            ZStack {
                Color.black.ignoresSafeArea()

                if let image = camera.image {
                    // The VR content (two eyes side-by-side)
                    // We'll build it in a container sized as if device were in landscape
                    // then rotate that container by 90deg when device is portrait.
                    let landscapeWidth = max(geo.size.width, geo.size.height)
                    let landscapeHeight = min(geo.size.width, geo.size.height)

                    Group {
                        HStack(spacing: 0) {
                            EyeView(image: image, ipd: -ipd, mirror: false)
                                .frame(width: landscapeWidth / 2, height: landscapeHeight)
                                .clipped()

                            EyeView(image: image, ipd: ipd, mirror: mirrorRightEye)
                                .frame(width: landscapeWidth / 2, height: landscapeHeight)
                                .clipped()
                        }
                    }
                    // Make container have landscape size, then rotate if needed
                    .frame(width: landscapeWidth, height: landscapeHeight)
                    .rotationEffect(isPortrait ? .degrees(90) : .degrees(0))
                    // After rotation, center it in the available geometry
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    // Slight upscale so shifting (ipd) won't show black edges
                    .scaleEffect(1.05)
                } else {
                    Text("Камера не готова")
                        .foregroundColor(.white)
                }

                // Top bar
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text("VR Preview")
                            .foregroundColor(.white)
                            .bold()
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding()
                    Spacer()
                }

                // Bottom controls
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        HStack {
                            Text("IPD")
                                .foregroundColor(.white)
                                .bold()
                                .frame(width: 40, alignment: .leading)
                            Slider(value: $ipd, in: 0...50)
                            Text("\(Int(ipd))")
                                .foregroundColor(.white)
                                .frame(width: 36)
                        }
                        HStack(spacing: 12) {
                            Toggle(isOn: $mirrorRightEye) {
                                Text("Зеркалить правый")
                                    .foregroundColor(.white)
                            }
                            Toggle(isOn: $showOverlayGuides) {
                                Text("Гиды")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
        }
        .statusBarHidden(true)
        .onAppear {
            // Рекомендуем запускать камеру до входа в VR
            camera.requestPermissionAndStart()
        }
    }
}

// EyeView без изменений (как раньше)
struct EyeView: View {
    let image: UIImage
    let ipd: CGFloat
    let mirror: Bool

    var body: some View {
        GeometryReader { g in
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                // немного увеличиваем, чтобы при сдвиге не появлялись чёрные края
                .frame(width: g.size.width * 1.2, height: g.size.height * 1.2)
                .offset(x: ipd)
                .scaleEffect(x: mirror ? -1.0 : 1.0, y: 1.0, anchor: .center)
        }
        .clipped()
    }
}
