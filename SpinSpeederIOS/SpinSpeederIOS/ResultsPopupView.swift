import SwiftUI

struct ResultsPopupView: View {
    let maxSpeed: Double
    let maxRotation: Double
    let totalBallsDetected: Int
    let trackingDuration: Double
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 전체 화면 배경
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // 팝업 컨테이너
            VStack(spacing: 0) {
                // 헤더
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("탁구공 추적 결과")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 30)
                .padding(.bottom, 20)
                
                // 결과 내용
                VStack(spacing: 16) {
                    ResultRow(
                        icon: "clock.fill",
                        title: "추적 시간",
                        value: String(format: "%.1f초", trackingDuration),
                        color: .blue
                    )
                    
                    ResultRow(
                        icon: "speedometer",
                        title: "최대 이동 속도",
                        value: String(format: "%.2f m/s", maxSpeed * 0.01),
                        color: .green
                    )
                    
                    ResultRow(
                        icon: "rotate.3d",
                        title: "최대 회전 속도",
                        value: String(format: "%.2f rad/s", maxRotation),
                        color: .purple
                    )
                    
                    ResultRow(
                        icon: "circle.grid.3x3.fill",
                        title: "검출된 공 개수",
                        value: "\(totalBallsDetected)개",
                        color: .red
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // 버튼들
                HStack(spacing: 15) {
                    Button(action: onCancel) {
                        Text("다시 추적")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    
                    Button(action: onConfirm) {
                        Text("확인")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }
}

struct ResultRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    ResultsPopupView(
        maxSpeed: 150.0,
        maxRotation: 25.5,
        totalBallsDetected: 3,
        trackingDuration: 45.2,
        onConfirm: {},
        onCancel: {}
    )
} 
