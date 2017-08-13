//
//  CTGLSettingModel.m
//  GLSDKCode
//
//  Created by codew on 2017/8/12.
//  Copyright © 2017年 codew. All rights reserved.
//

#import "CTGLSettingModel.h"
#import "CTGLShaderModel.h"
#import "CTGLPrimitiveModel.h"
static const GLfloat kColorConversion601[] = {
    1.164,  1.164,  1.164,
    0.0,    -0.392, 2.017,
    1.596,  -0.813, 0.0,
    
};
// Uniform index.

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
    
};

@interface CTGLSettingModel ()
{
    GLuint _frameBufferHandle;
    GLuint _colorBufferHandle;
    GLuint _depthbufferHandle;
    
    GLint _backingWidth;
    GLint _backingHeight;

    const GLfloat *_preferredConversion;
    CGImageRef _cgImageRef;
    GLuint _textureID;

}

@property (nonatomic, strong) CTGLShaderModel * shaderModel;
@property (nonatomic, strong) CTGLPrimitiveModel * primitiveModel;
@property (assign, nonatomic) GLKMatrix4 modelViewProjectionMatrix;

@property (nonatomic, assign) CT_GLPrimitiveModelType primitiveModelType;


@end

@implementation CTGLSettingModel


- (instancetype)initWithType:(CT_GLPrimitiveModelType)type delegate:(id<CTGLSettingModelDelegate>)delegate
{
    self = [super init];
    
    if (self) {
        _primitiveModelType = type;
        _preferredConversion = kColorConversion709;
        _delegate = delegate;
        [self.primitiveModel enableItem];
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_context];
    }
    
    return self;
}



#pragma mark - set get

- (CTGLShaderModel *)shaderModel
{
    if (!_shaderModel) {
        _shaderModel = [[CTGLShaderModel alloc]init];
    }
    return _shaderModel;
}

- (CTGLPrimitiveModel *)primitiveModel
{
    if (!_primitiveModel) {
        _primitiveModel = [[CTGLPrimitiveModel alloc]initWithType:_primitiveModelType];
    }
    return _primitiveModel;
}


# pragma mark - OpenGL setup
// 转屏会再来处理buffer
- (void)setupBuffers
{
    // 1.1创建帧缓存 Framebuffer可以包含多个Renderbuffer对象
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    // 创建深度缓存
    glGenRenderbuffers(1, &_depthbufferHandle);
    
    //     1.2创建渲染缓存 (Renderbuffer有三种:  color Renderbuffer, depth Renderbuffer, stencil Renderbuffer.)
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(renderbufferStorage)]) {
        [self.delegate renderbufferStorage];
    }
    
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);

    glBindRenderbuffer(GL_RENDERBUFFER, _depthbufferHandle);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthbufferHandle);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _backingWidth, _backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (BOOL)setupGL
{
    // 1. 设置buffers
    // 2. 加载着色器
    [self setupBuffers];
    if(![self.shaderModel loadShaders])
        return NO;
  
    
    glUseProgram(self.shaderModel.program);
    glUniform1i([self.shaderModel.uniforms[UNIFORM_Y] intValue], 0);
    glUniform1i([self.shaderModel.uniforms[UNIFORM_UV] intValue], 1);
    glUniformMatrix3fv([self.shaderModel.uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] intValue], 1, GL_FALSE, _preferredConversion);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(createVideoTextureCacheHasErr)]) {
        if ([self.delegate createVideoTextureCacheHasErr]) {
            return NO;
        }
    }
    
    glUniformMatrix3fv([self.shaderModel.uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] intValue], 1, GL_FALSE, _preferredConversion);
    glGenTextures(1, &_textureID);
    glBindTexture(GL_TEXTURE_2D, _textureID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 3. 绘制图元
    [self primitiveModel];
    
    return YES;
}


- (void)tearDownBuffers
{
    if (_frameBufferHandle) {
        //delete framebuffer
        glDeleteFramebuffers(1, &_frameBufferHandle);
        _frameBufferHandle = 0;
    }
    if (_colorBufferHandle) {
        //delete color render buffer
        glDeleteRenderbuffers(1, &_colorBufferHandle);
        _colorBufferHandle = 0;
    }
    if (_depthbufferHandle) {
        //delete color render buffer
        glDeleteRenderbuffers(1, &_depthbufferHandle);
        _depthbufferHandle = 0;
    }
    
}


- (void)updateRectangle
{
    
    float cam_scale = self.primitiveModel.cam_scale;
    float near = self.primitiveModel.near;
    float far = self.primitiveModel.far;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeFrustum(-1.0f /cam_scale, 1.0f/ cam_scale, -1.0f /cam_scale, 1.0f/cam_scale, near, far);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    
    GLKMatrix4 mViewMatrix = GLKMatrix4MakeLookAt(self.primitiveModel.eyeX, self.primitiveModel.eyeY, self.primitiveModel.eyeZ,
                                                  self.primitiveModel.centerX, self.primitiveModel.centerY, self.primitiveModel.centerZ,
                                                  self.primitiveModel.upX, self.primitiveModel.upY, self.primitiveModel.upZ);
    GLKMatrix4 matrix = GLKMatrix4Multiply(modelViewMatrix, mViewMatrix);
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, matrix);
    glUniformMatrix4fv([self.shaderModel.uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] intValue], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
    
}




- (void)updateDrawElement
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthbufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    // Set the view port to the entire view.
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glClearDepthf(1.0f);
    
    
    glDrawElements(GL_TRIANGLES, (int)self.primitiveModel.numIndices, GL_UNSIGNED_SHORT, 0);
    [self.primitiveModel deleteBuffer];
    
}


- (void)updatePreferredConversionWith:(CVPixelBufferRef)pixelBuffer
{
    // Use the color attachment of the pixel buffer to determine the appropriate color conversion matrix.
    CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    //        NSLog(@"color matrix: %@",colorAttachments);
    if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
        _preferredConversion = kColorConversion601;
    }
    else {
        _preferredConversion = kColorConversion709;
    }
    
}

- (void)updateVertexBuffer
{
    glUseProgram(self.shaderModel.program);
    glUniformMatrix3fv([self.shaderModel.uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] intValue], 1, GL_FALSE, _preferredConversion);
    
    [self.primitiveModel enableItem];
    glEnableVertexAttribArray(self.shaderModel.vertexTexCoordAttributeIndex);
    glVertexAttribPointer(self.shaderModel.vertexTexCoordAttributeIndex, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
    
    if (self.primitiveModel.primitiveModelType == CT_GLKVCItemTypeRectangle){// 圆
        [self updateRectangle];
    }
    
    [self updateDrawElement];
}
@end
