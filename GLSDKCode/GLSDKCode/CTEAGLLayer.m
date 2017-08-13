//
//  CTEAGLLayer.m
//  GLSDKCode
//
//  Created by codew on 2017/8/11.
//  Copyright © 2017年 codew. All rights reserved.
//

#import "CTEAGLLayer.h"
#import <mach/mach_time.h>
#import <GLKit/GLKit.h>
#import "CTGLSettingModel.h"

@import OpenGLES;

@interface CTEAGLLayer ()<CTGLSettingModelDelegate>
{
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
}
@property (nonatomic,assign) float layerRatio;
@property GLuint program;
@property GLuint timeStampProgram;

@property (nonatomic, strong) CTGLSettingModel * glSettingModel;
@end

@implementation CTEAGLLayer



- (instancetype)initWithDrawable:(UIView *)view
{
    self = [super init];
    if (self) {
        self.opaque = TRUE;
        self.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking :[NSNumber numberWithBool:YES],
                                     kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
        self.contentsScale = [[UIScreen mainScreen] scale];
        [view.layer addSublayer:self];
        _layerRatio = 1.0;
    }
    
    return self;
}

#pragma mark - GET/SET ---Lazy load

- (CTGLSettingModel *)glSettingModel
{
    if (!_glSettingModel) {
        _glSettingModel = [[CTGLSettingModel alloc] initWithType:CT_GLKVCItemTypeRectangle delegate:self];
    }
    return _glSettingModel;
}

#pragma mark - publicMethod

- (void)renderbufferStorage
{
    [self.glSettingModel.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self];
}




- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (pixelBuffer == NULL) {
        return;
    }
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    [self refreshTextureWith:pixelBuffer];
    [self.glSettingModel updatePreferredConversionWith:pixelBuffer];
    [self.glSettingModel updateVertexBuffer];
    [self.glSettingModel.context presentRenderbuffer:GL_RENDERBUFFER];
    
    glDisable(GL_BLEND);
    CFRelease(pixelBuffer);
    [EAGLContext setCurrentContext:self.glSettingModel.context];
}



#pragma mark CTGLSettingModelDelegate
- (BOOL)createVideoTextureCacheHasErr
{
    if (!_videoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glSettingModel.context, NULL, &_videoTextureCache);
        if (err != noErr) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
            return YES;
        }
    }
    return YES;
}

#pragma mark - Method
- (void)setupGL
{    
    [self.glSettingModel setupGL];
}

- (void)refreshTextureWith:(CVPixelBufferRef)pixelBuffer
{
    // 不在主线程时需要这句
    CVReturn err;
    int frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        return;
    }
    
    [self cleanUpTextures];
    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture optimally from CVPixelBufferRef.
    // Create Y and UV textures from the pixel buffer. These textures will be drawn on the frame buffer Y-plane.
    glActiveTexture(GL_TEXTURE0);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       frameWidth,
                                                       frameHeight,
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_lumaTexture);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    // UV-plane.
    glActiveTexture(GL_TEXTURE1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       frameWidth/2,
                                                       frameHeight/2,
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &_chromaTexture);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
   
}

- (void)cleanUpTextures
{
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}


@end
