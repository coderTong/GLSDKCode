//
//  CTMediaPlayer.m
//  GLSDKCode
//
//  Created by codew on 2017/8/11.
//  Copyright © 2017年 codew. All rights reserved.
//

#import "CTMediaPlayer.h"
#import <AVFoundation/AVFoundation.h>

#define ONE_FRAME_DURATION 0.033

NSString * const kTracksKey = @"tracks";
NSString * const kPlayableKey = @"playable";
NSString * const kRateKey = @"rate";
NSString * const kCurrentItemKey = @"currentItem";
NSString * const kStatusKey = @"status";

static void *AVPlayerDemoPlaybackViewControllerRateObservationContext = &AVPlayerDemoPlaybackViewControllerRateObservationContext;
static void *AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext = &AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext;
static void *AVPlayerDemoPlaybackViewControllerStatusObservationContext = &AVPlayerDemoPlaybackViewControllerStatusObservationContext;
static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;


@interface CTMediaPlayer ()
@property (strong, nonatomic) NSURL *videoURL;

@property (strong, nonatomic) AVPlayerItemVideoOutput* videoOutput;
@property (strong, nonatomic) AVPlayer* player;
@property (strong, nonatomic) AVPlayerItem* playerItem;
@property (strong, nonatomic) id timeObserver;
@property (assign, nonatomic) CGFloat mRestoreAfterScrubbingRate;
@property (assign, nonatomic) BOOL seekToZeroBeforePlay;
@end


@implementation CTMediaPlayer
- (instancetype)initWithRenderView:(UIView *)renderView mediaUrl:(NSURL *)mediaUrl
{
    self = [super init];
    if (self) {
        [self setVideoURL:mediaUrl];
    }
    return self;
}

- (void)play
{
    
}


- (void)setupVideoPlaybackForURL:(NSURL*)url {
    NSDictionary *pixelBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffAttributes];
    
    self.player = [[AVPlayer alloc] init];
    
    // Do not take mute button into account
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                                          error:&error];
    if (!success) {
        NSLog(@"Could not use AVAudioSessionCategoryPlayback", nil);
    }
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[[asset URL] path]]) {
        //NSLog(@"file does not exist");
    }
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        
        dispatch_async( dispatch_get_main_queue(),
                       ^{
                           /* Make sure that the value of each key has loaded successfully. */
                           for (NSString *thisKey in requestedKeys) {
                               NSError *error = nil;
                               AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
                               if (keyStatus == AVKeyValueStatusFailed) {
                                   
                                   
                                   return;
                               }
                           }
                           
                           NSError* error = nil;
                           AVKeyValueStatus status = [asset statusOfValueForKey:kTracksKey error:&error];
                           if (status == AVKeyValueStatusLoaded) {
                               self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                               [self.playerItem addOutput:self.videoOutput];
                               [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                               [self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];                                                                                             
                               
                               self.seekToZeroBeforePlay = NO;
                               
                               [self.playerItem addObserver:self
                                                 forKeyPath:kStatusKey
                                                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                    context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
                               
                               [self.player addObserver:self
                                             forKeyPath:kCurrentItemKey
                                                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                context:AVPlayerDemoPlaybackViewControllerCurrentItemObservationContext];
                               
                               [self.player addObserver:self
                                             forKeyPath:kRateKey
                                                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                context:AVPlayerDemoPlaybackViewControllerRateObservationContext];
                               
                               
                               
                               
                           } else {
                               NSLog(@"%@ Failed to load the tracks.", self);
                           }
                       });
    }];
}


- (void)removePlayerTimeObserver {
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}
@end
