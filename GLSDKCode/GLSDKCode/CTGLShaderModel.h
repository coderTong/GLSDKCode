//
//  CTGLShaderModel.h
//  GLSDKCode
//
//  Created by codew on 2017/8/12.
//  Copyright © 2017年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>


enum
{
    UNIFORM_Y = 0,
    UNIFORM_UV = 1,
    UNIFORM_COLOR_CONVERSION_MATRIX = 2,
    UNIFORM_MODELVIEWPROJECTION_MATRIX = 3
};

@interface CTGLShaderModel : NSObject

@property GLuint program;
@property (assign, nonatomic) GLuint vertexTexCoordAttributeIndex;
@property (nonatomic, strong) NSMutableArray *attributes;

@property (nonatomic, strong) NSMutableArray * uniforms;

- (BOOL)loadShaders;
@end
