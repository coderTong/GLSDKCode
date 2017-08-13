//
//  CTMediaPlayer.h
//  GLSDKCode
//
//  Created by codew on 2017/8/11.
//  Copyright © 2017年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface CTMediaPlayer : NSObject
- (instancetype)initWithRenderView:(UIView *)renderView mediaUrl:(NSURL *)mediaUrl;

- (void)play;

@end
