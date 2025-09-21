import SwiftUI

struct CameraScreen: View {
    @EnvironmentObject var camera: CameraModel
    @Environment(\.dismiss) private var dismiss

    // состояние для поворота/масштаба, если нужно
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Group {
                if let img = camera.image {
                    GeometryReader { geo in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea()

            // Верхняя панель
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }

            // Нижняя панель — кнопки
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button(action: {
                        // сделать фото (сохранение в фотоальбом)
                        if let image = camera.image {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                    }) {
                        Label("Снимок", systemImage: "camera")
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        // просто переключаем фильтр для примера
                        let all = CameraModel.FilterType.allCases
                        if let currentIndex = all.firstIndex(of: camera.selectedFilter) {
                            let next = all[(currentIndex + 1) % all.count]
                            camera.selectedFilter = next
                        }
                    }) {
                        Label("След. фильтр", systemImage: "sparkles")
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Запускаем камеру при открытии экрана (если нужно)
            camera.requestPermissionAndStart()
        }
        .onDisappear {
            // Реши сам: останавливать камеру при выходе или держать её запущенной
            // camera.stop()
        }
    }
}
