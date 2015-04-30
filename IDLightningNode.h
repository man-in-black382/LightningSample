//
//  CCLightningNode2.h
//  Presidents
//
//  Created by Pavel Muratov on 16.04.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface IDLightningNode : CCNode

-(void)animateWithPositions:(NSArray *)positions duration:(float)duration period:(float)period color:(CCColor *)color;

@end
