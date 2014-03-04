//
//  Game.m
//  AppScaffold
//

#import "Game.h"
#import "Ship.h"
#import "ShipsTray.h"
#import "ShipCommandBar.h"

@interface Game () {
	bool isGrabbed;
	float offsetX;
	float offsetY;
    
    bool shipGrabbed;
    float shipOffsetX;
    float shipOffsetY;
}

- (void)setup;

@end


@implementation Game


- (id)init
{
    if ((self = [super init]))
    {
        _tileSize = 32.0f;
        _tileCount = 32;
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    // release any resources here
    [Media releaseAtlas];
    [Media releaseSound];
}

- (void)setup
{
    
//    [SPAudioEngine start];  // starts up the sound engine
    
    
    _content = [[SPSprite alloc] init];
    _gridContainer = [[SPSprite alloc] init];
    
    [self addChild:_content];
    
    
    [_content addChild:_gridContainer];
    
    // The Application contains a very handy "Media" class which loads your texture atlas
    // and all available sound files automatically. Extend this class as you need it --
    // that way, you will be able to access your textures and sounds throughout your
    // application, without duplicating any resources.
    
//    [Media initSound];      // loads all your sounds    -> see Media.h/Media.m
    
    
    int gameHeight = Sparrow.stage.height;

    SPTexture *waterTexture = [SPTexture textureWithContentsOfFile:@"watertile.jpeg"];
    for (int i = 0; i < 32; i++) {
        for (int j = 0; j < 32; j++) {
            
            SPImage *image = [[SPImage alloc] initWithTexture:waterTexture];
            image.width = _tileSize;
            image.height = _tileSize;
            image.x = i * image.width;
            image.y = j * image.height;
            
            [_gridContainer addChild:image];
        }
    }
    
    _shipJuggler = [[SPJuggler alloc] init];
    [self addEventListener:@selector(advanceJugglers:) atObject:self forType:SP_EVENT_TYPE_ENTER_FRAME];
    
    _shipsTray = [[ShipsTray alloc] initWithGame:self];
    _shipsTray.y = gameHeight - 100.0f;
    _shipsTray.x = 0.0f;
    [self addChild:_shipsTray];

    
    NSArray *ships = [NSArray arrayWithObjects:num(Torpedo), num(Torpedo), num(Torpedo), num(Miner), num(Miner), nil];
    [_shipsTray presentShips:ships];
    
    
    [_gridContainer addEventListener:@selector(scrollGrid:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
}

- (void)scrollGrid:(SPTouchEvent *)event
{
    NSArray *touches = [[event touchesWithTarget:_gridContainer andPhase:SPTouchPhaseMoved] allObjects];
    
    if (touches.count == 1) {
        SPTouch *touch = touches[0];
        SPPoint *movement = [touch movementInSpace:_content.parent];
        
        _content.x += movement.x;
        _content.y += movement.y;

        // Doesn't work, since pivot changes......
//        newY = _content.y + movement.y;
//        int lb = Sparrow.stage.height - _tileCount * _tileSize - 162.0f;
//        NSLog(@"newY: %f", newY);
//        if (newY <= 62 && lb <= newY) {
//            _content.y = newY;
//        }

    } else if (touches.count >= 2) {
        // two fingers touching -> rotate and scale
        SPTouch *touch1 = touches[0];
        SPTouch *touch2 = touches[1];
        
        SPPoint *touch1PrevPos = [touch1 previousLocationInSpace:_content.parent];
        SPPoint *touch1Pos = [touch1 locationInSpace:_content.parent];
        SPPoint *touch2PrevPos = [touch2 previousLocationInSpace:_content.parent];
        SPPoint *touch2Pos = [touch2 locationInSpace:_content.parent];
        
        SPPoint *prevVector = [touch1PrevPos subtractPoint:touch2PrevPos];
        SPPoint *vector = [touch1Pos subtractPoint:touch2Pos];
        
        // update pivot point based on previous center
        SPPoint *touch1PrevLocalPos = [touch1 previousLocationInSpace:_content];
        SPPoint *touch2PrevLocalPos = [touch2 previousLocationInSpace:_content];
        _content.pivotX = (touch1PrevLocalPos.x + touch2PrevLocalPos.x) * 0.5f;
        _content.pivotY = (touch1PrevLocalPos.y + touch2PrevLocalPos.y) * 0.5f;
        
        // update location based on the current center
        _content.x = (touch1Pos.x + touch2Pos.x) * 0.5f;
        _content.y = (touch1Pos.y + touch2Pos.y) * 0.5f;
        
        float sizeDiff = vector.length / prevVector.length;
        _content.scaleX = _content.scaleY = MAX(0.45f, _content.scaleX * sizeDiff);
    }
}

- (void)advanceJugglers:(SPEnterFrameEvent *)event
{
    [_shipJuggler advanceTime:event.passedTime];
}

- (void)doneSettingShips
{
    [self removeChild:_shipsTray];
    _shipsTray = nil;
    
    _shipCommandBar = [[ShipCommandBar alloc] init];
    _shipCommandBar.y = Sparrow.stage.height - 100.0f;
    _shipCommandBar.x = 0.0f;
    [self addChild:_shipCommandBar];
    
}

@end
