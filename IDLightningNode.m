//
//  CCLIghtningNode.m
//  Lightning
//
//  Created by Pavel Muratov on 14.04.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "IDLightningNode.h"
#import "GlowNode.h"

#define RAND_FLOAT(min, max) ((((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * (max - min)) + min)
static const float M_PI_8 = M_PI_4 / 2;

@interface Segment : NSObject

@property (nonatomic) CGPoint start;
@property (nonatomic) CGPoint end;
@property (nonatomic) uint branchLevel;

+(id)segmentWithStartPoint:(CGPoint)start endPoint:(CGPoint)end branchLevel:(uint)level;
-(id)initWithStartPoint:(CGPoint)start endPoint:(CGPoint)end branchLevel:(uint)level;

-(float)length;

@end

@implementation Segment

+(id)segmentWithStartPoint:(CGPoint)start endPoint:(CGPoint)end branchLevel:(uint)level
{
    return [[self alloc] initWithStartPoint:start endPoint:end branchLevel:level];
}

-(id)initWithStartPoint:(CGPoint)start endPoint:(CGPoint)end branchLevel:(uint)level
{
    if(self = [super init])
    {
        self.start = start;
        self.end = end;
        self.branchLevel = level;
    }
    return self;
}

-(CGPoint)direction
{
    return ccpSub(self.end, self.start);
}

-(float)length
{
    CGPoint p = [self direction];
    return sqrtf(p.x * p.x + p.y * p.y);
}

-(CGPoint)normalizedVector
{
    float length = [self length];
    CGPoint norm = ccpSub(self.end, self.start);
    
    if (length != 0) {
        norm.x /= length;
        norm.y /= length;
    }
    
    return norm;
}

@end

@implementation IDLightningNode
{
    NSMutableArray *_renderTextures;
    NSMutableArray *_bolts;
    NSMutableArray *_boltsDrawNodes;
    NSMutableArray *_offsets;
    
    GlowNode *_glowRect;
    
    BOOL _animationAllowed;
    NSTimer *_animationTimer;
}

-(id)init
{
    if (self = [super init])
    {
        _glowRect = (GlowNode *)[CCBReader load:@"GlowNode"];
        [self addChild:_glowRect];
        
        _renderTextures = [NSMutableArray array];
        for (int i = 0; i < 2; ++i)
        {
            CCRenderTexture *renderTexture = [CCRenderTexture renderTextureWithWidth:[CCDirector sharedDirector].viewSize.width height:[CCDirector sharedDirector].viewSize.height];
            renderTexture.positionInPoints = ccp([CCDirector sharedDirector].viewSize.width / 2, [CCDirector sharedDirector].viewSize.height / 2);
            renderTexture.sprite.blendMode = [CCBlendMode blendModeWithOptions:@{
                                                                                 CCBlendFuncSrcColor: @(GL_ONE),
                                                                                 CCBlendFuncDstColor: @(GL_ONE),
                                                                                 }];
            [_renderTextures addObject:renderTexture];
            [self addChild:renderTexture];
        }
        
        _offsets = [NSMutableArray array];
        _bolts = [NSMutableArray arrayWithObjects:[NSMutableArray arrayWithCapacity:100],  [NSMutableArray arrayWithCapacity:100], nil];
        _boltsDrawNodes = [NSMutableArray arrayWithObjects:[CCDrawNode node], [CCDrawNode node], nil];
        
        _animationAllowed = YES;
    }
    return self;
}

-(void)generateBoltWithPositions:(NSArray *)positions index:(uint)index
{
    CGPoint startPosition = ((NSValue *)positions[0]).CGPointValue;
    CGPoint endPosition = ((NSValue *)positions[positions.count - 1]).CGPointValue;
    float distance = ccpDistance(endPosition, startPosition);
    float offset = distance / (5 * positions.count);
    int numberOfIterations;
    
    [_bolts[index] removeAllObjects];
    
    // Create main bolt
    for (int i = 0; i < positions.count - 1; ++i)
    {
        CGPoint p0 = ((NSValue *)positions[i]).CGPointValue;
        CGPoint p1 = ((NSValue *)positions[i + 1]).CGPointValue;
        
        Segment *seg = [Segment segmentWithStartPoint:p0 endPoint:p1 branchLevel:1];
        [_bolts[index] addObject:seg];
        
        // Occasionally create branches
        if ((arc4random_uniform(positions.count) < 1) && (i < positions.count - 2))
        {
            CGPoint direction = ccpSub(seg.end, seg.start);
            CGPoint splitEnd = ccpAdd(ccpMult(ccpRotateByAngle(direction, CGPointZero, RAND_FLOAT(-M_PI_8, M_PI_8)), 0.7), seg.end);
            [_bolts[index] addObject:[Segment segmentWithStartPoint:seg.end endPoint:splitEnd branchLevel:seg.branchLevel + 1]];
        }
    }

    NSMutableArray *temp = [NSMutableArray array];
    
    // Create secondary bolts
    
    // Need to calculate number of iterations somehow.
    // For now, it's hardcoded to 5.
    for (int i = 0; i < 5; ++i) {
        for (Segment *seg in _bolts[index])
        {
            CGPoint midPoint = ccp((seg.start.x + seg.end.x) / 2, (seg.start.y + seg.end.y) / 2);
            
            CGPoint normal = ccpMult([seg normalizedVector], RAND_FLOAT(-offset, offset));
            midPoint = ccpAdd(midPoint, ccp(-normal.y, normal.x));
            
            Segment *seg1 = [Segment segmentWithStartPoint:seg.start endPoint:midPoint branchLevel:seg.branchLevel];
            Segment *seg2 = [Segment segmentWithStartPoint:midPoint endPoint:seg.end branchLevel:seg.branchLevel];
            
            [temp addObject: seg1];
            [temp addObject: seg2];
            
            // Occasionally create branches
            if ((arc4random_uniform(2) < 1) && i < 4)
            {
                CGPoint direction = ccpSub(midPoint, seg.start);
                CGPoint splitEnd = ccpAdd(ccpMult(ccpRotateByAngle(direction, CGPointZero, RAND_FLOAT(-M_PI_8, M_PI_8)), 0.7), midPoint);
                [temp addObject:[Segment segmentWithStartPoint:midPoint endPoint:splitEnd branchLevel:seg.branchLevel + 1]];
            }
        }
        [_bolts[index] removeAllObjects];
        [_bolts[index] addObjectsFromArray:temp];
        [temp removeAllObjects];
        offset /= 2;
    }
    return;
}

-(void)drawBoltWithIndex:(uint)index
{
    _glowRect.color = self.color;
    
    [_boltsDrawNodes[index] clear];
    for (Segment *seg in _bolts[index])
    {
        [_boltsDrawNodes[index] drawSegmentFrom:seg.start to:seg.end radius: 1.f / ((float)seg.branchLevel) color:self.color];
        
        _glowRect.positionInPoints = seg.start;
        CGPoint direction = [seg direction];
        float angle = (-atan2f(direction.y, direction.x) * 180.f / M_PI) + 90;
        _glowRect.rotation = angle;
        _glowRect.scaleY = ([seg length] / _glowRect.contentSize.height);
        _glowRect.scaleX = 1.5 / (seg.branchLevel * 2);
        [_glowRect visit];
    }
    [_boltsDrawNodes[index] visit];
    _glowRect.positionInPoints = ccp(-100, -100);
}

////////////////////////////////////////////////
#pragma mark - Animation
////////////////////////////////////////////////

-(void)animateWithPositions:(NSArray *)positions duration:(float)duration period:(float)period color:(CCColor *)color
{
    self.color = color;
    if (!_animationTimer)
        _animationTimer = [NSTimer scheduledTimerWithTimeInterval:duration
                                                           target:self
                                                         selector:@selector(stopAnimation)
                                                         userInfo:nil
                                                          repeats:NO];
    else [self stopAnimation];
    _animationAllowed = YES;
    
    if (positions.count >= 2) {
        [self animationLoop:positions period:period color:color];
    }
}

-(void)animationLoop:(NSArray *)positions period:(float)period color:(CCColor *)color
{
    if (_animationAllowed)
    {
        CCActionSequence *sequence;
        NSArray *actions = [NSArray arrayWithObjects:
                            [CCActionCallBlock actionWithBlock:^{
            [((CCRenderTexture *)_renderTextures[0]) runAction:[CCActionTween actionWithDuration:period / 2 key:@"opacity" from:1.0 to:0.0]];
            [self generateBoltWithPositions:positions index:0];
        }],
                            [CCActionDelay actionWithDuration:period / 4],
                            [CCActionCallBlock actionWithBlock:^{
            [((CCRenderTexture *)_renderTextures[1]) runAction:[CCActionTween actionWithDuration:period / 2 key:@"opacity" from:1.0 to:0.0]];
            [self generateBoltWithPositions:positions index:1];
        }],
                            [CCActionDelay actionWithDuration:period / 4],
                            [CCActionCallBlock actionWithBlock:^{
            [self animationLoop:positions period:period color:color];
        }], nil];
        sequence = [CCActionSequence actionWithArray:actions];
        [self runAction:sequence];
    }
}

-(void)stopAnimation
{
    _animationAllowed = NO;
    [_animationTimer invalidate];
    _animationTimer = nil;
    [self stopAllActions];
}

-(void)update:(CCTime)delta
{
    if (_animationAllowed) {
        int i = 0;
        for (CCRenderTexture *rt in _renderTextures)
        {
            rt.sprite.opacity = rt.opacity;
            [rt beginWithClear:0.0 g:0.0 b:0.0 a:0.0];
            [self drawBoltWithIndex:i];
            [rt end];
            ++i;
        }
    }
}

@end
