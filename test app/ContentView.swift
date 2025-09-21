import SwiftUI

// Удобный переиспользуемый ряд слайдера
struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let formatter: (Double) -> String

    init(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, formatter: @escaping (Double) -> String = { String(format: "%.2f", $0) }) {
        self.title = title
        self._value = value
        self.range = range
        self.formatter = formatter
    }

    var body: some View {
        HStack(spacing: 12) {
            // Фиксированная колонка для подписи — не меняет ширину при перестройке
            Text(title)
                .frame(width: 140, alignment: .leading)
                .foregroundColor(.primary)

            // Слайдер занимает всё доступное пространство
            Slider(value: $value, in: range)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)

            // Значение справа с фиксированной шириной
            Text(formatter(value))
                .frame(width: 56, alignment: .trailing)
                .foregroundColor(.secondary)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var camera: CameraModel
    @State private var showVR = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Превью с фиксированной высотой — чтобы высота не менялась при старте камеры
                Group {
                    if let img = camera.image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .clipped()
                            .rotationEffect(.degrees(-90))
                            .cornerRadius(8)
                            .rotationEffect(.degrees(camera.rotationDegrees))
                    } else {
                        Color.black.frame(height: 300).cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                // Эффект (Picker)
                Picker("Filter", selection: $camera.selectedFilter) {
                    ForEach(CameraModel.FilterType.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Контролы — обёрнуты так, чтобы перестройка при запуске камеры не анимировалась
                VStack(spacing: 10) {
                    SliderRow("Интенсивность", value: $camera.intensity, range: 0...1) { String(format: "%.2f", $0) }
                    SliderRow("Размер изображения", value: $camera.imageScale, range: 1.0...1.4) { String(format: "%.2f", $0) }
                    SliderRow("Расстояние между глазами (IPD)", value: $camera.ipd, range: 0...60) { String(format: "%.0f", $0) }
                    SliderRow("Выравнивание (°)", value: $camera.rotationDegrees, range: -15...15) { String(format: "%.0f", $0) }
                }
                .padding(.horizontal)
                // Отключаем анимацию перестроения, когда меняется состояние isRunning
                .animation(nil, value: camera.isRunning)

                HStack(spacing: 12) {
                    Button(action: {
                        if camera.isRunning { camera.stop() } else { camera.requestPermissionAndStart() }
                    }) {
                        Text(camera.isRunning ? "Остановить" : "Запустить")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        if !camera.isRunning { camera.requestPermissionAndStart() }
                        showVR = true
                    }) {
                        Text("Открыть VR")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Filters → VR")
            .fullScreenCover(isPresented: $showVR) {
                VRMinimalScreen().environmentObject(camera)
            }
        }
    }
}
