//
//  CTGLPrimitiveModel.h
//  GLSDKCode
//
//  Created by codew on 2017/8/12.
//  Copyright © 2017年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef NS_OPTIONS(NSUInteger, CT_GLPrimitiveModelType) {
    CT_GLKVCItemTypeRectangle = 0 // 矩形
};

@interface CTGLPrimitiveModel : NSObject

@property (assign, nonatomic) GLuint vertexIndicesBufferID;
@property (assign, nonatomic) GLuint vertexBufferID;
@property (assign, nonatomic) GLuint vertexTexCoordID;
@property (assign, nonatomic) long  numIndices;
@property (assign, nonatomic) long  numVerticesTextCoord;

@property (assign, nonatomic) GLushort *indices;
@property (assign, nonatomic) GLfloat *vTextCoord;
@property (assign, nonatomic) GLfloat *vVertices;

@property (assign, nonatomic) float cam_scale;
@property (assign, nonatomic) float near; //
@property (assign, nonatomic) float far;//

@property (assign, nonatomic) float centerX;
@property (assign, nonatomic) float centerY;
@property (assign, nonatomic) float centerZ;
@property (assign, nonatomic) float upX;
@property (assign, nonatomic) float upY;
@property (assign, nonatomic) float upZ;

@property (assign, nonatomic) GLfloat eyeX;
@property (assign, nonatomic) GLfloat eyeZ;
@property (assign, nonatomic) GLfloat eyeY;

@property (assign, nonatomic) CT_GLPrimitiveModelType primitiveModelType;


- (instancetype)initWithType:(CT_GLPrimitiveModelType)primitiveModelType;
- (void)updateMatrix4MakeFrustumParameterWithType:(CT_GLPrimitiveModelType)primitiveModelType;
- (void)deleteBuffer;
- (void)enableItem;
@end
