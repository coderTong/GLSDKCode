//
//  CTGLSettingModel.h
//  GLSDKCode
//
//  Created by codew on 2017/8/12.
//  Copyright © 2017年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTGLPrimitiveModel.h"

@protocol CTGLSettingModelDelegate <NSObject>

@optional
- (BOOL)createVideoTextureCacheHasErr;
@end

@interface CTGLSettingModel : NSObject

@property (nonatomic, weak) id <CTGLSettingModelDelegate> delegate;

- (instancetype)initWithType:(CT_GLPrimitiveModelType)type;

- (BOOL)setupGL;
@end
