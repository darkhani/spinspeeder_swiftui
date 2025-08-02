import UIKit
import AVFoundation
import CoreMotion
import SwiftUI

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let motionManager = CMMotionManager()
    
    // UI 요소들
    private let ballInfoLabel = UILabel()
    private let speedLabel = UILabel()
    private let rotationLabel = UILabel()
    private let statusLabel = UILabel()
    private let backButton = UIButton()
    private let processedImageView = UIImageView()
    
    // 결과 추적 데이터
    private var maxSpeed: Double = 0.0
    private var maxRotation: Double = 0.0
    private var totalBallsDetected: Int = 0
    private var trackingStartTime: Date = Date()
    
    // 추적 결과 저장
    private var trackingResults: [String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        setupMotionManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("카메라 설정 실패")
            return
        }
        
        session.beginConfiguration()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        // 프리뷰 레이어 설정
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        // 카메라 방향 설정 (세로 고정)
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        view.layer.addSublayer(previewLayer)
        
        // 처리된 이미지 뷰 설정
        processedImageView.contentMode = .scaleAspectFill
        processedImageView.frame = view.bounds
        processedImageView.isHidden = true
        view.addSubview(processedImageView)
    }
    
    private func setupUI() {
        // 배경 오버레이
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        // 돌아가기 버튼 설정
        setupBackButton()
        
        // 정보 표시 레이블들
        ballInfoLabel.text = "탁구공 검출 대기 중..."
        ballInfoLabel.textColor = .white
        ballInfoLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        ballInfoLabel.textAlignment = .center
        ballInfoLabel.numberOfLines = 0
        ballInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ballInfoLabel)
        
        speedLabel.text = "속도: --"
        speedLabel.textColor = .white
        speedLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        speedLabel.textAlignment = .center
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLabel)
        
        rotationLabel.text = "회전: --"
        rotationLabel.textColor = .white
        rotationLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        rotationLabel.textAlignment = .center
        rotationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rotationLabel)
        
        statusLabel.text = "상태: 준비"
        statusLabel.textColor = .green
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            ballInfoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ballInfoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            ballInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            ballInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            speedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            speedLabel.topAnchor.constraint(equalTo: ballInfoLabel.bottomAnchor, constant: 20),
            
            rotationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rotationLabel.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 10),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // 돌아가기 버튼 제약조건
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupBackButton() {
        backButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backButton.layer.cornerRadius = 22
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
    }
    
    @objc private func backButtonTapped() {
        showResultsPopup()
    }
    
    private func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                if let motion = motion {
                    // 디바이스 모션 데이터로 카메라 흔들림 보정 가능
                    // print("디바이스 모션: \(motion.attitude)")
                }
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        // OpenCV Mat 생성
        let cvMat = BallTrackerWrapper.createMat(from: uiImage)
        
        // 탁구공 추적 처리
        let result = BallTrackerWrapper.processFrame(cvMat, timestamp: timestamp)
        
        // 처리된 이미지 가져오기
        let processedImage = BallTrackerWrapper.mat(toUIImage: cvMat)
        
        // 메모리 해제
        BallTrackerWrapper.releaseMat(cvMat)
        
        // UI 업데이트 (메인 스레드에서)
        DispatchQueue.main.async { [weak self] in
            if let resultDict = result as? [String: Any] {
                self?.updateUI(with: resultDict, processedImage: processedImage)
            }
        }
    }
    
    private func updateUI(with result: [String: Any], processedImage: UIImage?) {
        if result.isEmpty {
            ballInfoLabel.text = "탁구공을 찾을 수 없습니다"
            speedLabel.text = "속도: --"
            rotationLabel.text = "회전: --"
            statusLabel.text = "상태: 검색 중"
            statusLabel.textColor = .yellow
            processedImageView.isHidden = true
            return
        }
        
        let x = result["x"] as? Double ?? 0
        let y = result["y"] as? Double ?? 0
        let radius = result["radius"] as? Double ?? 0
        let speed = result["speed"] as? Double ?? 0
        let rotation = result["rotation"] as? Double ?? 0
        let ballCount = result["ballCount"] as? Int ?? 0
        
        // 여러 개 공 정보 표시 (정지물체 제외)
        if ballCount > 1 {
            ballInfoLabel.text = String(format: "움직이는 탁구공 %d개!\n주요 공: (%.0f, %.0f) R:%.0fpx", ballCount, x, y, radius)
        } else {
            ballInfoLabel.text = String(format: "움직이는 탁구공: (%.0f, %.0f)\n반지름: %.0fpx", x, y, radius)
        }
        
        // 검출된 공 개수 업데이트 (중복 제거)
        if ballCount > totalBallsDetected {
            totalBallsDetected = ballCount
        }
        
        // 속도 단위 변환 (픽셀/초 → m/s 추정)
        let estimatedSpeed = speed * 0.01 // 대략적인 변환
        speedLabel.text = String(format: "속도: %.2f m/s", estimatedSpeed)
        
        rotationLabel.text = String(format: "회전: %.2f rad/s", rotation)
        
        statusLabel.text = "상태: 추적 중"
        statusLabel.textColor = .green
        
        // 처리된 이미지 표시
        if let processedImage = processedImage {
            processedImageView.image = processedImage
            processedImageView.isHidden = false
        }
        
        // 추적 결과 저장
        trackingResults = result
        
        // 최대값 업데이트
        if speed > maxSpeed {
            maxSpeed = speed
        }
        if rotation > maxRotation {
            maxRotation = rotation
        }
    }
    
    private func showResultsPopup() {
        let trackingDuration = Date().timeIntervalSince(trackingStartTime)
        
        let resultsView = ResultsPopupView(
            maxSpeed: maxSpeed,
            maxRotation: maxRotation,
            totalBallsDetected: totalBallsDetected,
            trackingDuration: trackingDuration,
            onConfirm: { [weak self] in
                // 결과 화면을 닫고 메인 화면으로 돌아감
                self?.dismiss(animated: true)
            },
            onCancel: { [weak self] in
                // 결과 화면을 닫고 카메라 화면으로 돌아감
                self?.dismiss(animated: true)
            }
        )
        
        let hostingController = UIHostingController(rootView: resultsView)
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        
        present(hostingController, animated: true) { [weak self] in
            // 결과 화면이 표시된 후 카메라 화면을 닫음
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.dismiss(animated: false)
            }
        }
    }
    
    private func createResultsMessage() -> String {
        let trackingDuration = Date().timeIntervalSince(trackingStartTime)
        let durationString = String(format: "%.1f", trackingDuration)
        
        let maxSpeedMPS = maxSpeed * 0.01 // 픽셀/초를 m/s로 변환
        let maxRotationRPS = maxRotation // rad/s
        
        var message = "추적 시간: \(durationString)초\n\n"
        message += "최대 이동 속도: \(String(format: "%.2f", maxSpeedMPS)) m/s\n"
        message += "최대 회전 속도: \(String(format: "%.2f", maxRotationRPS)) rad/s\n"
        message += "검출된 공 개수: \(totalBallsDetected)개"
        
        return message
    }
} 
