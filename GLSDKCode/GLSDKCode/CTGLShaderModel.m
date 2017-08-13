//
//  CTGLShaderModel.m
//  GLSDKCode
//
//  Created by codew on 2017/8/12.
//  Copyright © 2017年 codew. All rights reserved.
//

#import "CTGLShaderModel.h"


@implementation CTGLShaderModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _attributes = [NSMutableArray array];
        _uniforms = [NSMutableArray array];
    }
    return self;
}

/*
 加载着色器程序
 */
- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSURL *vertShaderURL, *fragShaderURL;
    
    // Create the shader program. 创建着色器程序
    self.program = glCreateProgram();
    
    // Create and compile the vertex shader.
    vertShaderURL = [[NSBundle mainBundle] URLForResource:@"shader" withExtension:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER filePathURL:vertShaderURL]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderURL = [[NSBundle mainBundle] URLForResource:@"shader" withExtension:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER filePathURL:fragShaderURL]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.// 将顶点着色器对象关联到,着色器程序上
    glAttachShader(self.program, vertShader);
    // Attach fragment shader to program.// 将片元着色器对象关联到着色器程序上
    glAttachShader(self.program, fragShader);
    
    
    // 去shader里面拿 "attribute vec4 position;"这种属性的句柄
    [self addAttribute:@"position"];
    [self addAttribute:@"texCoord"];
    
    
    // Link the program.
    if (![self linkProgram:self.program]) {
        NSLog(@"Failed to link program: %d", self.program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (self.program) {
            glDeleteProgram(self.program);
            self.program = 0;
        }
        
        return NO;
    }
    
    self.vertexTexCoordAttributeIndex = [self attributeIndex:@"texCoord"];
    
    _uniforms[UNIFORM_Y] =@([self uniformIndex:@"SamplerY"]);;
    _uniforms[UNIFORM_UV] =@([self uniformIndex:@"SamplerUV"]);
    _uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = @([self uniformIndex:@"colorConversionMatrix"]);
    _uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = @([self uniformIndex:@"modelViewProjectionMatrix"]);
    
    
 
    
    
    return YES;
}

- (void)addAttribute:(NSString *)attributeName {
    if (![self.attributes containsObject:attributeName]) {
        [self.attributes addObject:attributeName];
        glBindAttribLocation(self.program,
                             (GLuint)[self.attributes indexOfObject:attributeName],
                             [attributeName UTF8String]);
    }
}

- (GLuint)attributeIndex:(NSString *)attributeName {
    return (GLuint)[self.attributes indexOfObject:attributeName];
}

- (GLuint)uniformIndex:(NSString *)uniformName {
    GLuint handle = glGetUniformLocation(self.program, [uniformName UTF8String]);
    return handle;
}


- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type filePathURL:(NSURL *)url
{
    NSError *error;
    NSString *sourceString = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (sourceString == nil) {
        NSLog(@"Failed to load vertex shader: %@ %@", sourceString, [error localizedDescription]);
        return NO;
    }
    
    GLint status;
    const GLchar *source;
    source = (GLchar *)[sourceString UTF8String];// 着色器源码
    // 创建着色器对象, 返回零就是错误
    *shader = glCreateShader(type);
    // 将着色器源码关联到着色器对象上
    glShaderSource(*shader, 1, &source, NULL);
    // 编译着色器源码
    glCompileShader(*shader);
    /*
     下面都是查看编译着色器源码的结果,如果是DEBUG我们会打印编译结果
     */
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    /*
     链接着色器对象生成可执行着色器程序
     将所有必要的着色器对象关联到着色器程序之后, 就链接对象来生成可执行程序了.
     */
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    /*
     查询链接着色器对象的结果
     */
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    glValidateProgram(prog);
    /*
     // 查询链接着色器对象的结果
     GL_LINK_STATUS
     glGetProgramiv(self.program, GL_LINK_STATUS, &status);
     GL_TRUE链接成功
     ps:编译成功后,我们就可以指定着色器程序来处理顶点和片元数据了.
     */
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    return YES;
}



@end
