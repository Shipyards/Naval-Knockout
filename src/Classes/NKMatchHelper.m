//
//  NKMatchHelper.m
//  GKAuthentication
//
//  Created by ivanfer on 2014-03-08.
//
//

#import "NKMatchHelper.h"
#import "MenuViewController.h"


@interface NKMatchHelper ()


@end

@implementation NKMatchHelper

#pragma mark Init_MatchHelper


static NKMatchHelper *sharedHelper = nil;



+ (NKMatchHelper *) sharedInstance {
    if (!sharedHelper){
        sharedHelper = [[NKMatchHelper alloc] init];
    }
    return sharedHelper;
}

- (BOOL)isGameCenterAvailable {
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

- (id)init {
    if ((self = [super init])) {
        _gameCenterAvailable = [self isGameCenterAvailable];
        if (_gameCenterAvailable) {
            NSNotificationCenter *nc =
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
        }
    }
    return self;
}

- (void)authenticationChanged {
    
    if ([GKLocalPlayer localPlayer].isAuthenticated &&
        !_userAuthenticated) {
        NSLog(@"Authentication changed: player authenticated.");
        _userAuthenticated = TRUE;
    } else if (![GKLocalPlayer localPlayer].isAuthenticated &&
               _userAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        _userAuthenticated = FALSE;
    }
    
}

- (void)authenticateLocalPlayer
{
    __weak GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        if (viewController) {
            [_menuViewController presentViewController:viewController animated:YES completion:^{
                [localPlayer registerListener:self];
                NSLog(@"Authenticated. Registering Turn Based Events listener");
            }];
        } else if (localPlayer.authenticated) {
            [localPlayer registerListener:self];
            NSLog(@"User Already Authenticated. Registering Turn Based Events listener");
        } else {
            NSLog(@"Unable to Authenticate with Game Center: %@", [error localizedDescription]);
        }
    };
}

#pragma mark GKTurnBasedMatchmakerViewControllerDelegate


- (void)findMatchWithMinPlayers:(int)minPlayers
					 maxPlayers:(int)maxPlayers
				 viewController:(MenuViewController *)viewController {
    if (!_gameCenterAvailable) return;
    
    _menuViewController = viewController;
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *mmvc =
    [[GKTurnBasedMatchmakerViewController alloc]
     initWithMatchRequest:request];
    mmvc.turnBasedMatchmakerDelegate = self;
    mmvc.showExistingMatches = YES;
    
    [_menuViewController presentViewController:mmvc animated:YES completion:nil];
}


-(void)turnBasedMatchmakerViewControllerWasCancelled:
(GKTurnBasedMatchmakerViewController *)viewController {
    [_menuViewController
     dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"has cancelled");
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [_menuViewController
     dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

-(void)turnBasedMatchmakerViewController:
(GKTurnBasedMatchmakerViewController *)viewController
					  playerQuitForMatch:(GKTurnBasedMatch *)match {
    NSLog(@"playerquitforMatch, %@, %@",
          match, match.currentParticipant);
}

-(void)turnBasedMatchmakerViewController:
(GKTurnBasedMatchmakerViewController *)viewController
							didFindMatch:(GKTurnBasedMatch *)match {
    self.currentMatch = match;
    NSLog(@"Current match data: %@", match.matchData);
    
    [_menuViewController dismissViewControllerAnimated:YES completion:nil]; // MAYBE
    [_menuViewController.view removeFromSuperview];
    [_menuViewController removeFromParentViewController];
    
    GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
    if (firstParticipant.lastTurnDate == NULL) {
        // It's a new game!
        
        [_delegate enterNewGame:match];
    } else {
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
            // It's your turn!
            [_delegate takeTurn:match];
        } else {
            // It's not your turn, just display the game state.
            [_delegate layoutMatch:match];
        }
    }
    
}


#pragma mark GKLocalPlayerListener

-(void)handleInviteFromGameCenter:(NSArray *)playersToInvite {
    NSLog(@"Handling invite from friend");
    [_menuViewController dismissModalViewControllerAnimated:YES];
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.playersToInvite = playersToInvite;
    request.maxPlayers = 2;
    request.minPlayers = 2;
    GKTurnBasedMatchmakerViewController *viewController =
    [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    viewController.showExistingMatches = NO;
    viewController.turnBasedMatchmakerDelegate = self;
    [_menuViewController presentModalViewController:viewController animated:YES];
}

- (void)handleTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive {
    NSLog(@"Turn has happened");
    if ([match.matchID isEqualToString:_currentMatch.matchID]) {
        self.currentMatch = match;
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
            // it's the current match and it's our turn now
            [_delegate takeTurn:match];
            
        } else {
            // it's the current match, but it's someone else's turn
            [_delegate layoutMatch:match];
        }
    } else {
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
            // it's not the current match and it's our turn now
            [_delegate sendNotice:@"It's your turn for another match" forMatch:match];
        } else {
            // it's the not current match, and it's someone else's turn
        }
    }
}

-(void)handleMatchEnded:(GKTurnBasedMatch *)match {
    NSLog(@"Game has ended");
    if ([match.matchID isEqualToString:_currentMatch.matchID]) {
        [_delegate recieveEndGame:match];
    } else {
        [_delegate sendNotice:@"Another Game Ended!" forMatch:match];
    }
}


- (void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite
{
    NSLog(@"In didAcceptInvite");
}

- (void)player:(GKPlayer *)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite
{
    NSLog(@"didRequestMatchWithPlayers");
}

- (void)player:(GKPlayer *)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive
{
    // Need to upload with htis match object.
    NSLog(@"In receivedTurnEvent active: %hhd", didBecomeActive);
    if ([self.currentMatch.matchID isEqualToString:match.matchID]) {
        self.currentMatch = match;
        [_delegate takeTurn:match];
    } else if (didBecomeActive) {
        self.currentMatch = match;
        [_delegate takeTurn:match];
    }
    
}

@end
