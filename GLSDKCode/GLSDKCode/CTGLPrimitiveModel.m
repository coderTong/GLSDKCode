//
//  CTGLPrimitiveModel.m
//  GLSDKCode
//
//  Created by codew on 2017/8/12.
//  Copyright © 2017年 codew. All rights reserved.
//

#import "CTGLPrimitiveModel.h"

@implementation CTGLPrimitiveModel


#pragma mark - 矩形
void rectangle(long *numVertices, long *numIndices,GLfloat **vVertices,GLfloat **vTextCoord, GLushort **indices)
{
    
    int numVerticesTemp = 4;
    int numTextCoordTemp = 4;
    
    int numIndicesTemp = 6;
    
    *numVertices = numVerticesTemp;
    *numIndices = numIndicesTemp;
    
    NSLog(@"顶点数-------%zd", numVerticesTemp);
    
    
    if (vVertices != NULL) {
        *vVertices = (GLfloat*) malloc(sizeof(GLfloat) * numVerticesTemp * 3);
    }
    if (vTextCoord != NULL) {
        *vTextCoord = (GLfloat*) malloc(sizeof(GLfloat) * numTextCoordTemp * 2);
    }
    if (indices != NULL) {
        *indices = (GLushort *) malloc(sizeof(GLushort) * numIndicesTemp);
    }
    
    
    
    
    (*vVertices)[0] = -1.0;
    (*vVertices)[1] = -1.0;
    (*vVertices)[2] = 0.0;
    
    (*vVertices)[3] = 1.0;
    (*vVertices)[4] = -1.0;
    (*vVertices)[5] = 0.0;
    
    (*vVertices)[6] = 1.0;
    (*vVertices)[7] = 1.0;
    (*vVertices)[8] = 0.0;
    
    (*vVertices)[9] = -1.0;
    (*vVertices)[10] = 1.0;
    (*vVertices)[11] = 0.0;
    
    (*vTextCoord)[0] = 0.0;
    (*vTextCoord)[1] = 1.0;
    
    (*vTextCoord)[2] = 1.0;
    (*vTextCoord)[3] = 1.0;
    
    (*vTextCoord)[4] = 1.0;
    (*vTextCoord)[5] = 0.0;
    
    (*vTextCoord)[6] = 0.0;
    (*vTextCoord)[7] = 0.0;
    
    (*indices)[0] = 0;
    (*indices)[1] = 1;
    (*indices)[2] = 2;
    
    (*indices)[3] = 2;
    (*indices)[4] = 3;
    (*indices)[5] = 0;
    
}
- (instancetype)initWithType:(CT_GLPrimitiveModelType)primitiveModelType
{
    self = [super init];
    if (self) {
        [self updateMatrix4MakeFrustumParameterWithType:primitiveModelType];
    }
    return self;
}



- (void)updateMatrix4MakeFrustumParameterWithType:(CT_GLPrimitiveModelType)primitiveModelType
{
    self.primitiveModelType = primitiveModelType;
}

#pragma mark - Set Get

- (void)setPrimitiveModelType:(CT_GLPrimitiveModelType)primitiveModelType
{
    _primitiveModelType = primitiveModelType;
    if (_primitiveModelType == CT_GLKVCItemTypeRectangle){
        _cam_scale = 2.0;
        _near = 1.0;
        _far = 4.0;
        
        [self resettingEyePointOrigin];
        
        _centerX = 0;
        _centerY = 0;
        _centerZ = 0;
        _upX = 0;
        _upY = 1;
        _upZ = 0;
        rectangle(&_numVerticesTextCoord, &_numIndices, &_vVertices, &_vTextCoord, &_indices);
        
    }
}


#pragma mark - private Method
- (void)resettingEyePointOrigin
{
    if (_primitiveModelType == CT_GLKVCItemTypeRectangle) {
        _eyeX = 0;
        _eyeY = 0;
        _eyeZ = 2;
    }
}


- (void)enableItem
{
    //Indices
    glGenBuffers(1, &_vertexIndicesBufferID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.vertexIndicesBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.numIndices*sizeof(GLushort), _indices, GL_STATIC_DRAW);
    
    // Vertex
    //
    //为缓存提供数据7步骤之 一~五
    // 步骤之一: 创建唯一标识符
    glGenBuffers(1, &_vertexBufferID);
    // 步骤之二: 绑定,  告诉ES 为接下来的运算使用一个缓存
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBufferID);
    // 步骤之三: 复制数据到缓存中
    glBufferData(GL_ARRAY_BUFFER, _numVerticesTextCoord*3*sizeof(GLfloat), _vVertices, GL_STATIC_DRAW);
    // 步骤之四:  启动 启动顶点渲染操作
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // 步骤之五:  设置指针,数据大小,    告诉ES数据在哪里, 怎么解释每个顶点保存的数据
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    
    // Texture Coordinates
    glGenBuffers(1, &_vertexTexCoordID);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexTexCoordID);
    glBufferData(GL_ARRAY_BUFFER, _numVerticesTextCoord*2*sizeof(GLfloat), _vTextCoord, GL_DYNAMIC_DRAW);
    
}

- (void)deleteBuffer
{
    glDeleteBuffers (1,
                     &_vertexBufferID);
    _vertexBufferID = 0;
    
    glDeleteBuffers (1,
                     &_vertexTexCoordID);
    _vertexTexCoordID = 0;
    
    glDeleteBuffers (1,
                     &_vertexIndicesBufferID);
    _vertexIndicesBufferID = 0;
}

@end
