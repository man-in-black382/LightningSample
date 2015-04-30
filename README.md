Cocos2D lightning
==================

An original article which describes the algorithm: http://drilian.com/2009/02/25/lightning-bolts/

If you open this project in SpriteBuilder, you'll see GlowNode.ccb. Open and study it. 
I'm using this node as glow texture. Corresponding class in XCode is "GlowNode".

IDLightningNode class does the main job. 

Not much of a discription here, it still has problems, which i intend to fix, but not now. 

Problems
-----------

1. Some bug with animation speed. Sometimes it is faster than it should be.
2. Number of iterations is hardcoded and i still need to find correct formula to calculate it.
   It works OK when lightning is large, but make it small and you'll see the problem.
   
How to use it
-----------   

This is the simple part :)
Create and add the lightning node to your scene:
```
_lightning = [IDLightningNode node];
[self addChild:_lightning];
```

Create an array of positions (at least 2 positions) and pass it to animate method:
```
[_lightning animateWithPositions:_positions duration:5.f period:0.5 color:[CCColor colorWithRed:0 green:1 blue:1]];
```

For more details see the sample project.

Screenshots
-----------

For the sake of performance in simulator, water node is small
![Alt text](/Screenshots/Lightning.png?raw=true "Screenshot")
