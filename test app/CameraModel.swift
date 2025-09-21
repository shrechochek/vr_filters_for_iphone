import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal

final class CameraModel: NSObject, ObservableObject {
    // Публичные параметры, которыми управляет UI
    @Published var image: UIImage? = nil
    @Published var isRunning: Bool = false

    // Параметры управления эффектом и VR
    @Published var selectedFilter: FilterType = .none
    @Published var intensity: Double = 0.7      // 0..1
    @Published var ipd: Double = 12.0           // pixels shift
    @Published var imageScale: Double = 1.05    // масштаб для EyeView (1.0 = без масштаба)
    @Published var rotationDegrees: Double = 0.0 // ручная подстройка выравнивания (в градусах)

    enum FilterType: String, CaseIterable, Identifiable {
        case none = "None"
        case sepia = "Sepia"
        case noir = "Noir"
        case invert = "Invert"
        case pixellate = "Pixellate"
        case blur = "Blur"

        var id: String { rawValue }
    }

    // AVFoundation
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutput = AVCaptureVideoDataOutput()

    // Core Image
    private let ciContext: CIContext
    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    override init() {
        if let device = MTLCreateSystemDefaultDevice() {
            ciContext = CIContext(mtlDevice: device)
        } else {
            ciContext = CIContext()
        }
        super.init()
        configureSession()
    }

    deinit {
        stop()
    }

    // MARK: - Session configuration
    private func configureSession() {
        sessionQueue.sync {
            session.beginConfiguration()
            session.sessionPreset = .hd1280x720

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)

            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }

            if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }

            session.commitConfiguration()
        }
    }

    // MARK: - Control
    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async { self.isRunning = true }
            }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async { self.isRunning = false }
            }
        }
    }

    func requestPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            start()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.start() }
                }
            }
        default:
            break
        }
    }

    // MARK: - Filtering pipeline
    private func applyFilter(to ciImage: CIImage) -> CIImage {
        let filter = selectedFilter
        switch filter {
        case .none:
            return ciImage
        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = ciImage
            f.intensity = Float(self.intensity)
            return f.outputImage ?? ciImage
        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = ciImage
            return f.outputImage ?? ciImage
        case .invert:
            let f = CIFilter.colorInvert()
            f.inputImage = ciImage
            return f.outputImage ?? ciImage
        case .pixellate:
            let f = CIFilter.pixellate()
            f.inputImage = ciImage
            f.scale = Float(CGFloat(8 + self.intensity * 72))
            return f.outputImage ?? ciImage
        case .blur:
            let f = CIFilter.gaussianBlur()
            f.inputImage = ciImage
            f.radius = Float(Double(1.0 + self.intensity * 20.0))
            return f.outputImage ?? ciImage
        }
    }
}

// MARK: - Sample buffer delegate
extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Базовая ориентация камеры; по необходимости можно подправлять
        ciImage = ciImage.oriented(.right)

        // Применяем фильтр
        let filtered = applyFilter(to: ciImage)

        // Создаём CGImage/UIImage
        guard let cgImage = ciContext.createCGImage(filtered, from: filtered.extent, format: .BGRA8, colorSpace: colorSpace) else { return }

        let uiImage = UIImage(cgImage: cgImage)

        DispatchQueue.main.async {
            self.image = uiImage
        }
    }
}
