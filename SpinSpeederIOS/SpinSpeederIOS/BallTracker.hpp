#ifndef BALL_TRACKER_HPP
#define BALL_TRACKER_HPP

#include <opencv2/core.hpp>
#include <vector>

class BallTracker {
public:
    static bool detectBall(const cv::Mat& frame, cv::Point2f& center, float& radius);
    static std::vector<std::pair<cv::Point2f, float>> detectMultipleBalls(const cv::Mat& frame);
    static double calculateSpeed(const cv::Point2f& currentPosition, double currentTimestamp);
    static double calculateRotation(const cv::Mat& frame, const cv::Point2f& center, float radius);
    static void drawBallDetection(cv::Mat& frame, const cv::Point2f& center, float radius);
    static void drawMultipleBallDetections(cv::Mat& frame, const std::vector<std::pair<cv::Point2f, float>>& balls);
    static std::vector<std::pair<cv::Point2f, float>> filterMovingBalls(const std::vector<std::pair<cv::Point2f, float>>& detectedBalls, double timestamp);
    
private:
    static cv::Point2f lastPosition;
    static double lastTimestamp;
    static std::vector<cv::Point2f> previousPositions;
    static std::vector<double> previousTimestamps;
    
    // 정지물체 필터링을 위한 데이터
    struct StaticObject {
        cv::Point2f position;
        float radius;
        double firstSeen;
        int consecutiveFrames;
        bool isMoving;
    };
    
    static std::vector<StaticObject> staticObjects;
    static double lastFilterTime;
};

#endif 