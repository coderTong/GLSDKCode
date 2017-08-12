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
@end

@implementation CTGLSettingModel


- (instancetype)initWithType:(CT_GLPrimitiveModelType)type
{
    self = [super init];
    
    if (self) {
        
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
    [self setupBuffers];
    if(![self.shaderModel loadShaders])
        return NO;
  
    
    glUseProgram(self.shaderModel.program);
    glUniform1i(uniforms[UNIFORM_Y], 0);
    glUniform1i(uniforms[UNIFORM_UV], 1);
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(createVideoTextureCacheHasErr)]) {
        if ([self.delegate createVideoTextureCacheHasErr]) {
            return NO;
        }
    }
    
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    glGenTextures(1, &_textureID);
    glBindTexture(GL_TEXTURE_2D, _textureID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    
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
    
    float cam_scale = _primitiveModel.cam_scale;
    float near = _primitiveModel.near;
    float far = _primitiveModel.far;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeFrustum(-1.0f /cam_scale, 1.0f/ cam_scale, -1.0f /cam_scale, 1.0f/cam_scale, near, far);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    
    GLKMatrix4 mViewMatrix = GLKMatrix4MakeLookAt(_primitiveModel.eyeX, _primitiveModel.eyeY, _primitiveModel.eyeZ,
                                                  _primitiveModel.centerX, _primitiveModel.centerY, _primitiveModel.centerZ,
                                                  _primitiveModel.upX, _primitiveModel.upY, _primitiveModel.upZ);
    GLKMatrix4 matrix = GLKMatrix4Multiply(modelViewMatrix, mViewMatrix);
    self.modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, matrix);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, self.modelViewProjectionMatrix.m);
    
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
    [_primitiveModel deleteBuffer];
    
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


@end
