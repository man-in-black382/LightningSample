//
//  GlowNode.m
//  
//
//  Created by Pavel Muratov on 16.04.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "GlowNode.h"

@implementation GlowNode
{
    CCSprite *_bottomPart;
    CCSprite *_middlePart;
    CCSprite *_topPart;
}

// Using max blending
-(void)draw:(CCRenderer *)renderer transform:(const GLKMatrix4 *)transform
{
    [renderer enqueueBlock:^{
        glBlendEquationSeparate( GL_MAX_EXT, GL_MAX_EXT );
    } globalSortOrder:0 debugLabel:nil threadSafe:YES];
    [super draw:renderer transform:transform];
}

-(void)setColor:(CCColor *)color
{
    _bottomPart.color = color;
    _middlePart.color = color;
    _topPart.color = color;
    [super setColor:color];
}

@end
