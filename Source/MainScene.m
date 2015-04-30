#import "MainScene.h"
#import "IDLightningNode.h"

@implementation MainScene
{
    NSMutableArray *_positions;
    IDLightningNode *_lightning;
}

-(void)didLoadFromCCB
{
    _positions = [NSMutableArray arrayWithCapacity:2];
    for (int i = 0; i < 2; ++i) {
        [_positions addObject:[NSValue valueWithCGPoint:CGPointMake([CCDirector sharedDirector].viewSize.width / 2, 0)]];
    }
    _lightning = [IDLightningNode node];
    [self addChild:_lightning];
    
    self.userInteractionEnabled = YES;
    [CCDirector sharedDirector].displayStats = YES;    
}

-(void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    _positions[0] = [NSValue valueWithCGPoint:[touch locationInWorld]];
    [_lightning animateWithPositions:_positions duration:5.f period:0.5 color:[CCColor colorWithRed:0 green:1 blue:1]];
}

@end
