//
//  Tile.m
//  Scaffold
//
//  Created by David Cottrell on 2014-03-05.
//
//

#import "Tile.h"
#import "Game.h"
#import "Mine.h"
#import "Ship.h"
#import "ShipSegment.h"

@interface Tile ()

@property (nonatomic, weak) Game * game;
@property (nonatomic, strong) SPQuad *selectableOverlay;

@property (nonatomic, strong) Mine *mine;

@property (nonatomic, strong) SPQuad *collisionOverlay;

@property (nonatomic, strong) SPQuad *sunkOverlay;

@property (nonatomic, assign) BOOL fogOfWarVisibility;

@property (nonatomic, strong) SPSprite *content;

@property (nonatomic, strong) SPImage *backgroundImage;

@property (nonatomic, strong) SPImage *reefImage;

@end

@implementation Tile


static SPTexture *waterTexture = nil;
static SPTexture *reefTexture = nil;
static SPTexture *visTexture = nil;

- (id)initWithGame:(Game *)game row:(int)r column:(int)c
{
    if (!waterTexture) {
        waterTexture = [SPTexture textureWithContentsOfFile:@"watertile.jpeg"];
    }
	if (!reefTexture){
        reefTexture = [SPTexture textureWithContentsOfFile:@"reef.png"];
	}
	if (!visTexture){
        visTexture= [SPTexture textureWithContentsOfFile:@"visible.png"];
	}
    
    self = [super init];
    if (self) {
        _game = game;
        _row = r;
        _col = c;
        _fogOfWarVisibility = NO;
        
        _backgroundImage = [[SPImage alloc] initWithTexture:waterTexture];
        _backgroundImage.width = _game.tileSize;
        _backgroundImage.height = _game.tileSize;
        [self addChild:_backgroundImage];
        
        _reefImage = [[SPImage alloc] initWithTexture:reefTexture];
        _reefImage.width = _game.tileSize;
        _reefImage.height = _game.tileSize;
        _reefImage.x = 0;
        _reefImage.y = 0;
        [self addChild:_reefImage];
        [_reefImage setVisible:NO];
        _reef = NO;
        
        _content = [[SPSprite alloc] init];
        _content.width = _game.tileSize;
        _content.height = _game.tileSize;
        [self addChild:_content];
        [_content setVisible:_fogOfWarVisibility];
                
        _collisionOverlay = [[SPQuad alloc] initWithWidth:_game.tileSize - 7.0f height:_game.tileSize - 7.0f color:0xff0000];
        [_content addChild:_collisionOverlay];
        [_collisionOverlay setVisible:YES];
        
        _selectableOverlay = [[SPQuad alloc] initWithWidth:_game.tileSize height:_game.tileSize color:0x00FF00];
        [self addChild:_selectableOverlay];
        _selectableOverlay.alpha = 0.5f;
        [_selectableOverlay setVisible:NO];
        _sunk = NO;
    }
    return self;
}
- (void)cleanTile
{
    _myShipSegment = nil;
    _myShip = nil;
    _sunk = NO;
    [self setReef:NO];
    _backgroundImage.alpha = 1.0f;
    [self displayCannonHit:NO];
    [self fogOfWar:NO];
}

- (void)setSelectable:(BOOL)selectable
{
    if (_myShipSegment) {
        [_selectableOverlay setVisible:NO];
        [_myShipSegment setSelectable:selectable];
    } else {
        [_selectableOverlay setVisible:selectable];
    }
}

- (void)performMineAction
{
    _mine = [[Mine alloc] initWithTile:self];
    _hasMine = YES;
    [self addChild:_mine];
}

- (void)displayCannonHit:(BOOL)display
{
    [_collisionOverlay setVisible:display];
    if (display) {
        [self fogOfWar:YES];
    }
    if (_myShipSegment) {
        [_myShipSegment displayCannonHit:display];
    }
}

- (void)performCannonAction
{
    [_content setVisible:YES];
    if (_myShipSegment) {
        [_myShipSegment hitByCannon];
    }
  [self notifyEvent];
}

- (void)performHeavyCannonAction
{
    [_content setVisible:YES];
    if (_myShipSegment) {
        [_myShipSegment hitByHeavyCannon];
    }
    [self notifyEvent];
}

- (void)notifyEvent
{
  [self displayCannonHit:YES];
  [_game notifyCannonCollision:self];
}

- (void)setSunk
{
    NSLog(@"Set sunk!");
    _backgroundImage.alpha = 0.5f;
    _sunk = YES;
}

- (void)setReef:(BOOL)reef
{
    if (reef == _reef) {
        return;
    }
    _reef = reef;
    [_reefImage setVisible:reef];
}

- (void)fogOfWar:(BOOL)visible
{
    if (_myShipSegment) {
        [_myShipSegment setFogOfWar:visible];
    }
    [_content setVisible:visible];
    
    if (!_reef) {
        if (visible) {
            _backgroundImage.texture = visTexture;
        } else {
            _backgroundImage.texture = waterTexture;
        }
    }
    
    _fogOfWarVisibility = visible;
}

@end
