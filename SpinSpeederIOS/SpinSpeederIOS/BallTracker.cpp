#include "BallTracker.hpp"
#include <opencv2/opencv.hpp>
#include <cmath>
#include <algorithm>

using namespace cv;
using namespace std;

// 정적 변수 초기화
Point2f BallTracker::lastPosition(-1, -1);
double BallTracker::lastTimestamp = -1;
vector<Point2f> BallTracker::previousPositions;
vector<double> BallTracker::previousTimestamps;
vector<BallTracker::StaticObject> BallTracker::staticObjects;
double BallTracker::lastFilterTime = -1;

bool BallTracker::detectBall(const Mat& frame, Point2f& center, float& radius) {
    Mat hsv, mask;
    cvtColor(frame, hsv, COLOR_BGR2HSV);
    
    // 탁구공 색상 범위 설정 (주황색/흰색)
    Mat mask_orange, mask_white, combined_mask;
    
    // 주황색 범위
    Scalar lower_orange(5, 100, 100);
    Scalar upper_orange(25, 255, 255);
    inRange(hsv, lower_orange, upper_orange, mask_orange);
    
    // 흰색 범위 (탁구공이 흰색일 경우)
    Scalar lower_white(0, 0, 200);
    Scalar upper_white(180, 30, 255);
    inRange(hsv, lower_white, upper_white, mask_white);
    
    // 두 마스크 결합
    bitwise_or(mask_orange, mask_white, combined_mask);
    
    // 노이즈 제거
    Mat kernel = getStructuringElement(MORPH_ELLIPSE, Size(5, 5));
    morphologyEx(combined_mask, combined_mask, MORPH_OPEN, kernel);
    morphologyEx(combined_mask, combined_mask, MORPH_CLOSE, kernel);
    
    vector<vector<Point>> contours;
    findContours(combined_mask, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    
    float maxRadius = 0;
    Point2f bestCenter;
    bool found = false;

    for (const auto& contour : contours) {
        float area = contourArea(contour);
        if (area < 100) continue; // 너무 작은 객체 제외
        
        float r;
        Point2f c;
        minEnclosingCircle(contour, c, r);
        
        // 원형도 검사
        double perimeter = arcLength(contour, true);
        double circularity = 4 * M_PI * area / (perimeter * perimeter);
        
        // 탁구공 크기 제한 (10px ~ 40px)
        if (r >= 10 && r <= 40 && circularity > 0.6) {
            if (r > maxRadius) {
                maxRadius = r;
                bestCenter = c;
                found = true;
            }
        }
    }

    if (found) {
        center = bestCenter;
        radius = maxRadius;
        return true;
    }

    return false;
}

std::vector<std::pair<Point2f, float>> BallTracker::detectMultipleBalls(const Mat& frame) {
    std::vector<std::pair<Point2f, float>> detectedBalls;
    
    Mat hsv, mask_orange, mask_white, combined_mask;
    cvtColor(frame, hsv, COLOR_BGR2HSV);
    
    // 주황색 탁구공 검출 (HSV 범위)
    Scalar lower_orange(5, 100, 100);
    Scalar upper_orange(25, 255, 255);
    inRange(hsv, lower_orange, upper_orange, mask_orange);
    
    // 흰색 탁구공 검출
    Scalar lower_white(0, 0, 200);
    Scalar upper_white(180, 30, 255);
    inRange(hsv, lower_white, upper_white, mask_white);
    
    // 두 마스크 결합
    bitwise_or(mask_orange, mask_white, combined_mask);
    
    // 노이즈 제거
    Mat kernel = getStructuringElement(MORPH_ELLIPSE, Size(5, 5));
    morphologyEx(combined_mask, combined_mask, MORPH_OPEN, kernel);
    morphologyEx(combined_mask, combined_mask, MORPH_CLOSE, kernel);
    
    vector<vector<Point>> contours;
    findContours(combined_mask, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    
    for (const auto& contour : contours) {
        float area = contourArea(contour);
        if (area < 100) continue; // 너무 작은 객체 제외
        
        float r;
        Point2f c;
        minEnclosingCircle(contour, c, r);
        
        // 원형도 검사
        double perimeter = arcLength(contour, true);
        double circularity = 4 * M_PI * area / (perimeter * perimeter);
        
        // 탁구공 크기 제한 (10px ~ 40px)
        if (r >= 10 && r <= 40 && circularity > 0.6) {
            detectedBalls.push_back(std::make_pair(c, r));
        }
    }
    
    return detectedBalls;
}

std::vector<std::pair<Point2f, float>> BallTracker::filterMovingBalls(const vector<pair<Point2f, float>>& detectedBalls, double timestamp) {
    std::vector<std::pair<Point2f, float>> movingBalls;
    
    // 시간 간격이 너무 짧으면 필터링 건너뛰기
    if (lastFilterTime > 0 && (timestamp - lastFilterTime) < 0.1) {
        return detectedBalls;
    }
    
    // 현재 검출된 공들과 기존 정지물체 비교
    for (const auto& ball : detectedBalls) {
        Point2f currentPos = ball.first;
        float currentRadius = ball.second;
        bool isStaticObject = false;
        
        // 기존 정지물체와 비교
        for (auto& staticObj : staticObjects) {
            double distance = cv::norm(currentPos - staticObj.position);
            double radiusDiff = abs(currentRadius - staticObj.radius);
            
            // 같은 위치에 있는지 확인 (5픽셀 이내, 반지름 차이 3픽셀 이내)
            if (distance < 5.0 && radiusDiff < 3.0) {
                staticObj.consecutiveFrames++;
                staticObj.isMoving = false;
                isStaticObject = true;
                break;
            }
        }
        
        // 새로운 객체인 경우 정지물체 목록에 추가
        if (!isStaticObject) {
            StaticObject newStaticObj;
            newStaticObj.position = currentPos;
            newStaticObj.radius = currentRadius;
            newStaticObj.firstSeen = timestamp;
            newStaticObj.consecutiveFrames = 1;
            newStaticObj.isMoving = true;
            staticObjects.push_back(newStaticObj);
        }
    }
    
    // 정지물체 목록 정리 (오래된 객체 제거, 움직이는 객체만 유지)
    std::vector<StaticObject> updatedStaticObjects;
    for (const auto& staticObj : staticObjects) {
        // 3초 이상 같은 위치에 있으면 정지물체로 판단
        if (staticObj.consecutiveFrames > 30 && !staticObj.isMoving) {
            // 정지물체는 제외
            continue;
        }
        
        // 10초 이상 된 객체는 제거
        if ((timestamp - staticObj.firstSeen) > 10.0) {
            continue;
        }
        
        updatedStaticObjects.push_back(staticObj);
    }
    staticObjects = updatedStaticObjects;
    
    // 움직이는 공만 반환
    for (const auto& ball : detectedBalls) {
        Point2f currentPos = ball.first;
        float currentRadius = ball.second;
        bool isMoving = true;
        
        // 정지물체 목록에서 확인
        for (const auto& staticObj : staticObjects) {
            double distance = cv::norm(currentPos - staticObj.position);
            double radiusDiff = abs(currentRadius - staticObj.radius);
            
            if (distance < 5.0 && radiusDiff < 3.0 && !staticObj.isMoving) {
                isMoving = false;
                break;
            }
        }
        
        if (isMoving) {
            movingBalls.push_back(ball);
        }
    }
    
    lastFilterTime = timestamp;
    return movingBalls;
}

double BallTracker::calculateSpeed(const Point2f& currentPosition, double currentTimestamp) {
    if (lastTimestamp < 0) {
        lastPosition = currentPosition;
        lastTimestamp = currentTimestamp;
        return 0.0;
    }

    double dx = currentPosition.x - lastPosition.x;
    double dy = currentPosition.y - lastPosition.y;
    double distance = sqrt(dx * dx + dy * dy);
    double deltaTime = currentTimestamp - lastTimestamp;

    if (deltaTime <= 0) return 0.0;

    lastPosition = currentPosition;
    lastTimestamp = currentTimestamp;

    return distance / deltaTime; // 픽셀/초
}

double BallTracker::calculateRotation(const Mat& frame, const Point2f& center, float radius) {
    if (radius <= 0) return 0.0;
    
    // 공 주변 영역 추출
    int x = max(0, (int)(center.x - radius));
    int y = max(0, (int)(center.y - radius));
    int width = min(frame.cols - x, (int)(2 * radius));
    int height = min(frame.rows - y, (int)(2 * radius));
    
    if (width <= 0 || height <= 0) return 0.0;
    
    Mat roi = frame(Rect(x, y, width, height));
    Mat gray;
    cvtColor(roi, gray, COLOR_BGR2GRAY);
    
    // 엣지 검출
    Mat edges;
    Canny(gray, edges, 50, 150);
    
    // Hough Circle 검출으로 회전 패턴 분석
    vector<Vec3f> circles;
    HoughCircles(gray, circles, HOUGH_GRADIENT, 1, gray.rows/8, 100, 30, 0, 0);
    
    if (circles.empty()) return 0.0;
    
    // 회전 각도 계산 (간단한 구현)
    // 실제로는 더 정교한 알고리즘이 필요
    double rotation = 0.0;
    
    // 이전 프레임과의 비교를 위한 저장
    previousPositions.push_back(center);
    previousTimestamps.push_back(lastTimestamp);
    
    // 최근 5개 프레임만 유지
    if (previousPositions.size() > 5) {
        previousPositions.erase(previousPositions.begin());
        previousTimestamps.erase(previousTimestamps.begin());
    }
    
    return rotation;
}

void BallTracker::drawBallDetection(Mat& frame, const Point2f& center, float radius) {
    if (radius <= 0) return;
    
    // 녹색 원형 라인 그리기
    Scalar greenColor(0, 255, 0); // BGR 형식 (녹색)
    int thickness = 3;
    
    // 외부 원 그리기
    circle(frame, center, radius, greenColor, thickness);
    
    // 중심점 표시
    circle(frame, center, 5, greenColor, -1); // 채워진 원
    
    // 반지름 선 그리기 (선택사항)
    Point2f radiusEnd(center.x + radius, center.y);
    line(frame, center, radiusEnd, greenColor, 2);
    
    // 텍스트 정보 표시
    string info = "Ball: " + to_string((int)radius) + "px";
    putText(frame, info, Point(center.x - 30, center.y - radius - 10), 
            FONT_HERSHEY_SIMPLEX, 0.6, greenColor, 2);
}

void BallTracker::drawMultipleBallDetections(Mat& frame, const vector<pair<Point2f, float>>& balls) {
    for (size_t i = 0; i < balls.size(); i++) {
        const auto& ball = balls[i];
        Point2f center = ball.first;
        float radius = ball.second;
        
        if (radius <= 0) continue;
        
        // 각 공마다 다른 색상 사용
        Scalar colors[] = {
            Scalar(0, 255, 0),   // 녹색
            Scalar(255, 0, 0),   // 파란색
            Scalar(0, 0, 255),   // 빨간색
            Scalar(255, 255, 0), // 청록색
            Scalar(255, 0, 255), // 마젠타
            Scalar(0, 255, 255)  // 노란색
        };
        
        Scalar color = colors[i % 6];
        int thickness = 3;
        
        // 외부 원 그리기
        circle(frame, center, radius, color, thickness);
        
        // 중심점 표시
        circle(frame, center, 5, color, -1); // 채워진 원
        
        // 번호 표시
        string number = to_string(i + 1);
        putText(frame, number, Point(center.x - 5, center.y + 5), 
                FONT_HERSHEY_SIMPLEX, 0.5, color, 2);
        
        // 반지름 정보 표시
        string info = "R:" + to_string((int)radius) + "px";
        putText(frame, info, Point(center.x - 20, center.y - radius - 10), 
                FONT_HERSHEY_SIMPLEX, 0.4, color, 1);
    }
    
    // 정지물체 표시 (디버깅용 - 회색으로 표시)
    for (const auto& staticObj : staticObjects) {
        if (!staticObj.isMoving && staticObj.consecutiveFrames > 10) {
            Scalar staticColor(128, 128, 128); // 회색
            circle(frame, staticObj.position, staticObj.radius, staticColor, 2);
            circle(frame, staticObj.position, 3, staticColor, -1);
            
            // 정지물체 표시
            string staticText = "Static";
            putText(frame, staticText, Point(staticObj.position.x - 20, staticObj.position.y - staticObj.radius - 5), 
                    FONT_HERSHEY_SIMPLEX, 0.3, staticColor, 1);
        }
    }
}