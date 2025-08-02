//
//  ContentView.swift
//  SpinSpeederIOS
//
//  Created by INTAEK HAN on 8/2/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingCamera = false
    @State private var showingSettings = false
    @State private var showingVideoPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 앱 로고/아이콘
                Image(systemName: "circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .overlay(
                        Image(systemName: "circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .offset(x: -5, y: -5)
                    )
                    .padding()
                
                // 앱 제목
                Text("Spin Speeder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // 앱 설명
                Text("탁구공의 이동 속도와 회전 속도를\n실시간으로 측정하세요")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                // 카메라 시작 버튼
                Button(action: {
                    showingCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("실시간 카메라 추적")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                
                // MP4 불러오기 버튼
                Button(action: {
                    showingVideoPicker = true
                }) {
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.title2)
                        Text("MP4 파일 불러오기")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                
                // 설정 버튼
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                        Text("설정")
                            .font(.title3)
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 사용법 안내
                VStack(alignment: .leading, spacing: 10) {
                    Text("사용법:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(alignment: .top, spacing: 10) {
                        Text("1.")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("탁구공을 카메라 화면 중앙에 위치시킵니다")
                    }
                    
                    HStack(alignment: .top, spacing: 10) {
                        Text("2.")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("공을 움직이거나 회전시키면 실시간으로 측정됩니다")
                    }
                    
                    HStack(alignment: .top, spacing: 10) {
                        Text("3.")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("조명이 충분하고 배경이 단순할 때 정확도가 높습니다")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding()
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            TrackingCameraView()
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("카메라 설정") {
                    HStack {
                        Text("해상도")
                        Spacer()
                        Text("1080p")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("프레임 레이트")
                        Spacer()
                        Text("30 FPS")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("추적 설정") {
                    HStack {
                        Text("탁구공 색상")
                        Spacer()
                        Text("자동 감지")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("최소 크기")
                        Spacer()
                        Text("10px")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("정보") {
                    HStack {
                        Text("앱 버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("OpenCV 버전")
                        Spacer()
                        Text("4.8.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VideoPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVideo: URL?
    @State private var showingVideoPlayer = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 비디오 선택 안내
                VStack(spacing: 15) {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("사진첩에서 동영상을 선택하세요")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("탁구공이 포함된 동영상을 선택하면\n자동으로 분석을 시작합니다")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Spacer()
                
                // 사진첩에서 선택 버튼
                Button(action: {
                    showingImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("사진첩에서 선택")
                        .font(.title2)
                        .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                
                // 샘플 비디오 버튼 (개발용)
                Button(action: {
                    // 샘플 비디오 로드 (실제로는 샘플 파일이 필요)
                    showingVideoPlayer = true
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text("샘플 비디오로 테스트")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("동영상 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedVideo: $selectedVideo, isPresented: $showingImagePicker)
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            VideoPlayerView(videoURL: selectedVideo)
        }
        .onChange(of: selectedVideo) { newValue in
            if newValue != nil {
                showingVideoPlayer = true
            }
        }
    }
}

struct VideoPlayerView: View {
    let videoURL: URL?
    @Environment(\.dismiss) private var dismiss
    @State private var isAnalyzing = false
    @State private var analysisResults: [String: Any] = [:]
    
    var body: some View {
        NavigationView {
            VStack {
                // 비디오 플레이어 영역 (실제로는 AVPlayer 사용)
                ZStack {
                    Rectangle()
                        .fill(Color.black)
                        .aspectRatio(16/9, contentMode: .fit)
                    
                    VStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("비디오 재생 중...")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                }
                .padding()
                
                // 분석 결과 표시
                if isAnalyzing {
                    VStack(spacing: 15) {
                        ProgressView("탁구공 분석 중...")
                            .progressViewStyle(CircularProgressViewStyle())
                        
                        Text("프레임을 분석하여 탁구공의 속도와 회전을 측정합니다")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !analysisResults.isEmpty {
                    VStack(spacing: 15) {
                        Text("분석 결과")
                            .font(.headline)
                        
                        HStack {
                            VStack {
                                Text("최대 속도")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(analysisResults["maxSpeed"] as? String ?? "0") m/s")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("평균 속도")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(analysisResults["avgSpeed"] as? String ?? "0") m/s")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("회전 속도")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(analysisResults["rotation"] as? String ?? "0") rad/s")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                }
                
                Spacer()
                
                // 분석 시작 버튼
                Button(action: {
                    startAnalysis()
                }) {
                    HStack {
                        Image(systemName: isAnalyzing ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        Text(isAnalyzing ? "분석 중지" : "분석 시작")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAnalyzing ? Color.red : Color.blue)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .disabled(analysisResults.isEmpty && !isAnalyzing)
            }
            .navigationTitle("비디오 분석")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startAnalysis() {
        if isAnalyzing {
            isAnalyzing = false
        } else {
            isAnalyzing = true
            
            // 시뮬레이션된 분석 (실제로는 OpenCV로 비디오 분석)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isAnalyzing = false
                analysisResults = [
                    "maxSpeed": "15.2",
                    "avgSpeed": "12.8",
                    "rotation": "45.6"
                ]
            }
        }
    }
}

#Preview {
    ContentView()
}
