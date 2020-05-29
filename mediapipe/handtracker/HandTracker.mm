#import "HandTracker.h"
#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPLayerRenderer.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/formats/rect.pb.h"

static NSString* const kGraphName = @"hand_tracking_mobile_gpu";
static const char* kInputStream = "input_video";
static const char* kOutputStream = "output_video";
static const char* kLandmarksOutputStream = "hand_landmarks";
static const char* kHandRectOutputStream = "hand_rect";
static const char* kHandednessOutputStream = "handedness";
static const char* kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";

@interface HandTracker() <MPPGraphDelegate>
@property(nonatomic) MPPGraph* mediapipeGraph;
@end

@interface Landmark()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
@end

@interface NormalizedRect()
- (instancetype) initWithCenterX:(float)centerX
                         centerY:(float)centerY
                           width:(float)width
                          height:(float)height
                        rotation:(float)rotation;
@end

@implementation HandTracker {}

#pragma mark - Cleanup methods

- (void)dealloc {
  self.mediapipeGraph.delegate = nil;
  [self.mediapipeGraph cancel];
  // Ignore errors since we're cleaning up.
  [self.mediapipeGraph closeAllInputStreamsWithError:nil];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self.mediapipeGraph waitUntilDoneWithError:nil];
  });
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph*)loadGraphFromResource:(NSString*)resource {
  // Load the graph config resource.
  NSError* configLoadError = nil;
  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  if (!resource || resource.length == 0) {
    return nil;
  }
  NSURL* graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
  NSData* data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
  if (!data) {
    NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
    return nil;
  }
  
  // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
  mediapipe::CalculatorGraphConfig config;
  config.ParseFromArray(data.bytes, data.length);
  
  // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
  MPPGraph* newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
  [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypePixelBuffer];
  [newGraph addFrameOutputStream:kLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
  [newGraph addFrameOutputStream:kHandRectOutputStream outputPacketType:MPPPacketTypeRaw];

  return newGraph;
}

- (instancetype)init
{
  self = [super init];

  self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName];
  self.mediapipeGraph.delegate = self;
  self.mediapipeGraph.maxFramesInFlight = 2;

  return self;
}

- (void)startGraph {
  NSError* error;

  if (![self.mediapipeGraph startWithError:&error]) {
    NSLog(@"Failed to start graph: %@", error);
  }
}

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string&)streamName {
  if (streamName == kOutputStream) {
    [_delegate handTracker: self didOutputPixelBuffer: pixelBuffer];
  }
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
       didOutputPacket:(const ::mediapipe::Packet&)packet
            fromStream:(const std::string&)streamName {
  
  if (packet.IsEmpty()) { return; }
  
  if (streamName == kLandmarksOutputStream) {
    const auto& landmarks = packet.Get<::mediapipe::NormalizedLandmarkList>();
    
    NSMutableArray<Landmark *> *result = [NSMutableArray array];
    for (int i = 0; i < landmarks.landmark_size(); ++i) {
      Landmark *landmark = [[Landmark alloc] initWithX:landmarks.landmark(i).x()
                                                     y:landmarks.landmark(i).y()
                                                     z:landmarks.landmark(i).z()];
      [result addObject:landmark];
    }

    [_delegate handTracker: self didOutputLandmarks: result];
  } else if (streamName == kHandRectOutputStream) {
    const auto& rect = packet.Get<::mediapipe::NormalizedRect>();
    
    NormalizedRect *normalizedRect = [[NormalizedRect alloc] initWithCenterX:rect.x_center() centerY:rect.y_center() width:rect.width() height:rect.height() rotation:rect.rotation()];
    
    [_delegate handTracker: self didOutputHandRect: normalizedRect];
  }
}

- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer {
  [self.mediapipeGraph sendPixelBuffer:imageBuffer
                            intoStream:kInputStream
                            packetType:MPPPacketTypePixelBuffer];
}

@end

@implementation NormalizedRect

- (instancetype) initWithCenterX:(float)xCenter
                         centerY:(float)yCenter
                           width:(float)width
                          height:(float)height
                        rotation:(float)rotation{
  self = [super init];
  if(self){
    _xCenter = xCenter;
    _yCenter = yCenter;
    _width = width;
    _height = height;
    _rotation = rotation;
  }
  
  return self;
}

@end

@implementation Landmark

- (instancetype)initWithX:(float)x y:(float)y z:(float)z
{
  self = [super init];
  if (self) {
    _x = x;
    _y = y;
    _z = z;
  }
  return self;
}

@end
