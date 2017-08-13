//
//  CTEAGLLayer.h
//  GLSDKCode
//
//  Created by codew on 2017/8/11.
//  Copyright © 2017年 codew. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface CTEAGLLayer : CAEAGLLayer
- (instancetype)initWithDrawable:(UIView *)view;

- (void)setupGL;

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;


@end
