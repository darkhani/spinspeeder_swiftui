import SwiftUI

struct TrackingCameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // 업데이트가 필요할 때 호출됨
    }
}

struct TrackingCameraView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingCameraView()
    }
} 