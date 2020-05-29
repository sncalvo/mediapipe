#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class Landmark;
@class NormalizedRect;
@class HandTracker;

@protocol TrackerDelegate <NSObject>
- (void)handTracker: (HandTracker*)handTracker didOutputLandmarks: (NSArray<Landmark *> *)landmarks;
- (void)handTracker: (HandTracker*)handTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
- (void)handTracker: (HandTracker*)handTracker didOutputHandRect:(NormalizedRect*)normalizedRect;
@end

@interface HandTracker : NSObject
- (instancetype)init;
- (void)startGraph;
- (void)stopGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer;
@property (weak, nonatomic) id <TrackerDelegate> delegate;
@end

@interface NormalizedRect : NSObject
// Location of the center of the rectangle in image coordinates.
// The (0.0, 0.0) point is at the (top, left) corner.
@property(nonatomic, readonly) float xCenter;
@property(nonatomic, readonly) float yCenter;

@property(nonatomic, readonly) float width;
@property(nonatomic, readonly) float height;

@property(nonatomic, readonly) float rotation;
@end

@interface Landmark: NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end
