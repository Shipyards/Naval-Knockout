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

@interface Tile ()

@property (nonatomic, weak) Game * game;
@property (nonatomic, strong) SPQuad *selectableOverlay;

@property (nonatomic, strong) Mine *mine;

@property (nonatomic, strong) SPQuad *collisionOverlay;

@property (nonatomic, strong) SPQuad *damagedOverlay;
@property (nonatomic, strong) SPQuad *sunkOverlay;

@property (nonatomic, assign) BOOL fogOfWarVisibility;

@property (nonatomic, strong) SPSprite *content;


@end

@implementation Tile

static SPTexture *waterTexture = nil;
static SPTexture *reefTexture = nil;
static SPTexture *visTexture = nil;
static NSDictionary *reefPositions = nil;

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
	[self initReef];
    self = [super init];
    if (self) {
        _game = game;
        _row = r;
        _col = c;
        _fogOfWarVisibility = NO;
	  // is this a reef?
	  SPImage *image;
	  if( [[reefPositions objectForKey:num(r)] containsObject:num(c)] ){
		_reef = YES;
		image = [[SPImage alloc] initWithTexture:reefTexture];
	  }
      else{
		image = [[SPImage alloc] initWithTexture:waterTexture];
	  }
        image.width = _game.tileSize;
        image.height = _game.tileSize;
        [self addChild:image];
        
        _content = [[SPSprite alloc] init];
        _content.width = _game.tileSize;
        _content.height = _game.tileSize;
        [self addChild:_content];
        [_content setVisible:_fogOfWarVisibility];
        
        _damagedOverlay = [[SPQuad alloc] initWithWidth:_game.tileSize height:_game.tileSize color:0xffff00];
        [_content addChild:_damagedOverlay];
        [_damagedOverlay setVisible:NO];
        
        _sunkOverlay = [[SPQuad alloc] initWithWidth:_game.tileSize height:_game.tileSize color:0x000000];
        [_content addChild:_sunkOverlay];
        [_sunkOverlay setVisible:NO];
        
        _collisionOverlay = [[SPQuad alloc] initWithWidth:_game.tileSize - 7.0f height:_game.tileSize - 7.0f color:0xff0000];
        [_content addChild:_collisionOverlay];
        [_collisionOverlay setVisible:YES];
        
        _selectableOverlay = [[SPQuad alloc] initWithWidth:_game.tileSize height:_game.tileSize color:0x00FF00];
        [self addChild:_selectableOverlay];
        [_selectableOverlay setVisible:NO];
    }
    return self;
}

- (void)setSelectable:(BOOL)selectable
{
    [_selectableOverlay setVisible:selectable];
}

- (void)performMineAction
{
    _mine = [[Mine alloc] initWithTile:self];
    _hasMine = YES;
    [self addChild:_mine];
}

- (void)displayCannonHit:(BOOL)display
{
//    [_collisionOverlay setVisible:display];
}

- (void)performCannonAction
{
    [_content setVisible:YES];
    if (_myShip) {
        NSLog(@"Hit at row: %d, col: %d with ship: %@", _row, _col, _myShip);
        [_myShip hitByCannon];
    }
    [self displayCannonHit:YES];
    [_game notifyCannonCollision:self];
}


- (void)initReef
{
  if (!reefPositions){
	reefPositions = @{num(6):@[num(10),num(11)], // reef space occupies rows 3 - 26, cols 10-19
					  num(7):@[num(12),num(13)],
					  num(8):@[num(10),num(11),num(12)],
					  num(9):@[num(20)],
					  num(10):@[num(19),num(18)],
					  num(11):@[num(17),num(16)],
					  num(12):@[num(13),num(14),num(15),num(16)],
					  num(14):@[num(14),num(15),num(16)],
					  num(16):@[num(11)],
					  num(17):@[num(10)],
					  num(24):@[num(19),num(10),num(12)],
					  };
  }
}

- (void)setDamaged
{
    [_damagedOverlay setVisible:YES];
}
- (void)setDestroyed
{
    [_sunkOverlay setVisible:YES];
}
- (void)setClear
{
    if (_sunkOverlay) {
        [_sunkOverlay setVisible:NO];
    }
    if (_damagedOverlay) {
        [_damagedOverlay setVisible:NO];
    }
}


- (void)fogOfWar:(BOOL)visible
{
    if (_myShip) {
        NSLog(@"Ship should be invisible");
        [_myShip setVisible:visible];
    }
    [_content setVisible:visible];
    _fogOfWarVisibility = visible;
}


// Yellow: 0xffff00

@end
