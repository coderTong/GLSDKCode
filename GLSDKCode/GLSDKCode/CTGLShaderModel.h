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
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    UNIFORM_MODELVIEWPROJECTION_MATRIX
};
static GLint uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX + 1];

@interface CTGLShaderModel : NSObject

@property GLuint program;
@property (assign, nonatomic) GLuint vertexTexCoordAttributeIndex;
@property (nonatomic, strong) NSMutableArray *attributes;

- (BOOL)loadShaders;

@end
