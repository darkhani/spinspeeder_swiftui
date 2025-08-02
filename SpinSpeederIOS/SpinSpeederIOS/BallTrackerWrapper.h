#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BallTrackerWrapper : NSObject

+ (NSDictionary *)processFrame:(void *)frame timestamp:(double)timestamp;
+ (void *)createMatFromImage:(UIImage *)image;
+ (void)releaseMat:(void *)mat;
+ (UIImage *)matToUIImage:(void *)mat;

@end

NS_ASSUME_NONNULL_END 