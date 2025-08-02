import SwiftUI
import PhotosUI
import AVKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedVideo: URL?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: URL.self) {
                provider.loadObject(ofClass: URL.self) { url, error in
                    DispatchQueue.main.async {
                        if let videoURL = url as? URL {
                            self.parent.selectedVideo = videoURL
                        }
                    }
                }
            }
        }
    }
} 