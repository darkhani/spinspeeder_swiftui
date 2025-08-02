#import <opencv2/opencv.hpp>
#import "BallTracker.hpp"
#import "BallTrackerWrapper.h"

@implementation BallTrackerWrapper

+ (NSDictionary *)processFrame:(void *)frame timestamp:(double)timestamp {
    cv::Mat* mat = static_cast<cv::Mat*>(frame);
    if (!mat || mat->empty()) {
        return @{};
    }
    
    // 여러 개 탁구공 검출
    std::vector<std::pair<cv::Point2f, float>> detectedBalls = BallTracker::detectMultipleBalls(*mat);
    
    if (detectedBalls.empty()) {
        return @{};
    }
    
    // 정지물체 필터링 (움직이는 공만 선택)
    std::vector<std::pair<cv::Point2f, float>> balls = BallTracker::filterMovingBalls(detectedBalls, timestamp);
    
    if (balls.empty()) {
        return @{};
    }
    
    // 첫 번째 공의 정보를 메인으로 사용 (속도 계산용)
    cv::Point2f center = balls[0].first;
    float radius = balls[0].second;
    
    // 속도 계산
    double speed = BallTracker::calculateSpeed(center, timestamp);
    
    // 회전 속도 계산
    double rotation = BallTracker::calculateRotation(*mat, center, radius);
    
    // 여러 개 원형 라인 그리기
    BallTracker::drawMultipleBallDetections(*mat, balls);
    
    // 검출된 공들의 정보를 배열로 반환
    NSMutableArray *ballsArray = [NSMutableArray array];
    for (const auto& ball : balls) {
        [ballsArray addObject:@{
            @"x": @(ball.first.x),
            @"y": @(ball.first.y),
            @"radius": @(ball.second)
        }];
    }
    
    return @{
        @"x": @(center.x),
        @"y": @(center.y),
        @"radius": @(radius),
        @"speed": @(speed),
        @"rotation": @(rotation),
        @"timestamp": @(timestamp),
        @"balls": ballsArray,
        @"ballCount": @(balls.size())
    };
}

+ (void *)createMatFromImage:(UIImage *)image {
    if (!image) return nullptr;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    
    cv::Mat* mat = new cv::Mat((int)height, (int)width, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(
        mat->data,
        width,
        height,
        8,
        mat->step[0],
        colorSpace,
        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault
    );
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // RGBA to BGR 변환 (iOS는 RGBA, OpenCV는 BGR)
    cv::Mat bgrMat;
    cv::cvtColor(*mat, bgrMat, cv::COLOR_RGBA2BGR);
    *mat = bgrMat;
    
    return mat;
}

+ (void)releaseMat:(void *)mat {
    if (mat) {
        cv::Mat* cvMat = static_cast<cv::Mat*>(mat);
        delete cvMat;
    }
}

+ (UIImage *)matToUIImage:(void *)mat {
    cv::Mat* cvMat = static_cast<cv::Mat*>(mat);
    if (!cvMat || cvMat->empty()) {
        return nil;
    }
    
    // BGR to RGB 변환 (OpenCV는 BGR, iOS는 RGB)
    cv::Mat rgbMat;
    cv::cvtColor(*cvMat, rgbMat, cv::COLOR_BGR2RGB);
    
    // Mat을 UIImage로 변환
    NSData *data = [NSData dataWithBytes:rgbMat.data length:rgbMat.elemSize() * rgbMat.total()];
    
    CGColorSpaceRef colorSpace;
    if (rgbMat.channels() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(rgbMat.cols,
                                       rgbMat.rows,
                                       8,
                                       8 * rgbMat.channels(),
                                       rgbMat.step[0],
                                       colorSpace,
                                       kCGBitmapByteOrderDefault | kCGImageAlphaNone,
                                       provider,
                                       NULL,
                                       false,
                                       kCGRenderingIntentDefault);
    
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end 
