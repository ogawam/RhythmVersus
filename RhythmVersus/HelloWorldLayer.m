//
//  HelloWorldLayer.m
//  RhythmVersus
//
//  Created by 小川 穣 on 2013/11/30.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "ShootBullet.h"

#pragma mark - HelloWorldLayer

#define INTERVAL_TIME 0

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
		
        gameCenterAvailable = NO;
        error = nil;
        currentMatch = nil;
        matchStarted = NO;
        match_callback = [[MatchCallback alloc] init];
        updateSec = 0;
        phase = 0;
        bullets = [[NSMutableArray alloc] init];
        life = 100;
        
		// ask director for the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
		
        gameLayer = [CCLayer node];
        AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
        float scale = (size.width / 768.f);
        [gameLayer setScale:scale];
        [self addChild:gameLayer];

        CCSprite* lifeFrame = [CCSprite spriteWithFile:@"rvTimeFrame.png"];
        CGRect lfTexRect = lifeFrame.textureRect;
        CGPoint lfPosition = ccp(size.width/2, size.height-lfTexRect.size.height);
        [lifeFrame setPosition:lfPosition];
        [self addChild:lifeFrame];

        lifeGauge = [CCSprite spriteWithFile:@"rvLifeGauge.png"];
        lfPosition.x -= lfTexRect.size.width/2;
        [lifeGauge setPosition:lfPosition];
        [lifeGauge setAnchorPoint:ccp(0,0.5f)];
        [self addChild:lifeGauge];

        CCSprite* timeFrame = [CCSprite spriteWithFile:@"rvTimeFrame.png"];
        CGRect tfTexRect = timeFrame.textureRect;
        CGPoint tfPosition = ccp(size.width/2, size.height-tfTexRect.size.height*2.25f);
        [timeFrame setPosition:tfPosition];
        [self addChild:timeFrame];

        timeGauge = [CCSprite spriteWithFile:@"rvTimeGauge.png"];
        tfPosition.x -= tfTexRect.size.width/2;
        [timeGauge setPosition:tfPosition];
        [timeGauge setAnchorPoint:ccp(0,0.5f)];
        [self addChild:timeGauge];

        CCSprite *sprite = [CCSprite spriteWithFile:@"rhythmversus.png"];
        [sprite setPosition:ccp(size.width/2,size.height/2)];
        if(appCtrler.isRetina)
            [sprite setScale:2];
        [gameLayer addChild:sprite];

        countDown = [CCLabelTTF labelWithString:[NSString stringWithFormat:@""] fontName:@"Arial Rounded MT Bold" fontSize:16];
        [countDown setPosition:ccp(size.width/2,size.height/2)];
        [countDown setColor:ccBLACK];
        [gameLayer addChild: countDown];
		//
		// Leaderboards and Achievements
		//
		
		// Default font size will be 28 points.
		[CCMenuItemFont setFontSize:28];
/*		
		// Achievement Menu Item using blocks
		CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id sender) {
			
			
			GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
			achivementViewController.achievementDelegate = self;
			
			AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
			
			[[app navController] presentModalViewController:achivementViewController animated:YES];
			
			[achivementViewController release];
		} ];

		// Leaderboard Menu Item using blocks
		CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
			
			
			GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
			leaderboardViewController.leaderboardDelegate = self;
			
			AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
			
			[[app navController] presentModalViewController:leaderboardViewController animated:YES];
			
			[leaderboardViewController release];
		} ];
*/
		CCMenuItem *itemLogin = [CCMenuItemFont itemWithString:@"Login" block:^(id sender) {
            [self authenticateLocalPlayer];
        } ];
        
		CCMenuItem *itemMatch = [CCMenuItemFont itemWithString:@"Match" block:^(id sender) {
            [self requestMatch];
        } ];
    
        CCMenuItem *itemClear = [CCMenuItemFont itemWithString:@"Clear" block:^(id sender) {
            [iconLayer removeAllChildrenWithCleanup:YES];
        } ];
		
		CCMenu *menu = [CCMenu menuWithItems: itemLogin, itemMatch, itemClear, nil];

		[menu alignItemsHorizontallyWithPadding:8];
		[menu setPosition:ccp( size.width/2, 64)];
		
		// Add the menu to the layer
		[self addChild:menu];

        stateLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"myState %d\nvsState %d", myState, vsState] fontName:@"Arial Rounded MT Bold" fontSize:16];
        [stateLabel setPosition:ccp(size.width / 2,16)];
        [stateLabel setAnchorPoint:ccp(0,0)];
        [self addChild:stateLabel];

        iconLayer = [CCLayer node];
        [gameLayer addChild:iconLayer];
        
        gameCenterAvailable = [self isGameCenterAvailable];
        self.isTouchEnabled = YES;

        [self authenticateLocalPlayer];

        [self schedule:@selector(update:)];        
 	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

- (void) update:(float)deltaTime
{
    for(ShootBullet* bullet in bullets) {
        if([bullet update:updateSec]) {
            life -= 10;
            if(life < 0)
                life = 100;
            float rate = (life / 100.f);
            CGRect rect = lifeGauge.textureRect;
            CGSize size = lifeGauge.texture.contentSize;
            rect.size.width = size.width * rate;
            [lifeGauge setTextureRect:rect];
        }
    }

    if(phase == 0) {
        if(updateSec < 3) {
            [countDown setScale:10 * (1-fmodf(updateSec, 1))];
            [countDown setString:[NSString stringWithFormat:@"%d", 3-(int)updateSec]];
        }
        else {
            phase++;
            sendData.tableSize = 0;
            recieveData.tableSize = 0;
            shootSec = INTERVAL_TIME;
            updateSec = 0;
        }
        updateSec += deltaTime;
    }
    else if(phase == 1) {
        if(updateSec < 5) {
            float rate = 1 - (updateSec / 5.f);
            CGRect rect = timeGauge.textureRect;
            CGSize size = timeGauge.texture.contentSize;
            rect.size.width = size.width * rate;
            [timeGauge setTextureRect:rect];
        }
        else {
            phase++;

            myState++;
            sendData.state = myState;
            [self sendDataToAllPlayers: &sendData sizeInBytes:sizeof(SendData)];

            for(ShootBullet* bullet in bullets)
                [bullet destroy];
            [bullets removeAllObjects];
            [iconLayer removeAllChildrenWithCleanup:YES];
            
            [stateLabel setString: [NSString stringWithFormat:@"myState %d\nvsState %d", myState, vsState]];

            updateSec = 0;
        }
        updateSec += deltaTime;
        shootSec -= deltaTime;
    }
    else if(phase == 2) {
        if(currentMatch == nil) {
            vsState = recieveData.state;
            phase++;
        }
        else if(match_callback.recieveTouched) {
            match_callback.recieveTouched = NO;
            recieveData = match_callback.recieveData;
            vsState = recieveData.state;
            phase++;
        }
    }
    else if(phase == 3) {
        if(updateSec < 3) {
            [countDown setScale:10 * (1-fmodf(updateSec, 1))];
            [countDown setString:[NSString stringWithFormat:@"%d", 3-(int)updateSec]];
        }
        else {
            phase++;
            recieveTouchIndex = 0;
            updateSec = 0;
        }
        updateSec += deltaTime;
    }
    else if(phase == 4) {
        if(updateSec < 5) {
            float rate = 1 - (updateSec / 5.f);
            CGRect rect = timeGauge.textureRect;
            CGSize size = timeGauge.texture.contentSize;
            rect.size.width = size.width * rate;
            [timeGauge setTextureRect:rect];

            while(recieveTouchIndex < recieveData.tableSize) {
                if(updateSec >= recieveData.touches[recieveTouchIndex].sec - 2) {
                    AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
                    float scale = 768;
                    CGSize winSize = [[CCDirector sharedDirector] winSize];
                    CGPoint position = ccp(recieveData.touches[recieveTouchIndex].x, recieveData.touches[recieveTouchIndex].y);
                    position.x = winSize.width / 2 + position.x * scale;
                    position.y = winSize.height / 2 + position.y * scale;

                    [bullets addObject:[[ShootBullet alloc] initWithParamRecieve:recieveData.touches[recieveTouchIndex].sec touchPoint:position iconLayer:iconLayer]];
                    recieveTouchIndex++;
                }
                else {
                    break;
                }
            }
        }
        else {
            for(ShootBullet* bullet in bullets)
                [bullet destroy];
            [bullets removeAllObjects];
            [iconLayer removeAllChildrenWithCleanup:YES];
            phase = 0;
            updateSec = 0;
        }
        updateSec += deltaTime;
    }
}
/*
-(void) registerWithTouchDispatcher
{
    CCDirector *director = [CCDirector sharedDirector];
    [[director touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}
*/
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];

    bool touched = false;
    for (UITouch *touch in touches) {
        CGPoint touchPoint = [touch locationInView:[touch view]];
        CGPoint screenPoint;
        touchPoint.x = (touchPoint.x - (winSize.width / 2)) / winSize.width;
        touchPoint.y = ((winSize.height / 2) - touchPoint.y) / winSize.width;

        BOOL valid = NO;
        if(touchPoint.x < 0.5f && touchPoint.x > -0.5f 
        && touchPoint.y < 0.5f && touchPoint.y > -0.5f )
        {
            float scale = 768;
            screenPoint.x = winSize.width / 2 + touchPoint.x * scale;
            screenPoint.y = winSize.height / 2 + touchPoint.y * scale;
            valid = YES;
        }

        if(phase == 1) {
            if(valid && shootSec < 0) {
                CCSprite* sprite = [CCSprite spriteWithFile:@"Icon-72.png"];
                AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
                if(appCtrler.isRetina)
                    [sprite setScale:2];
                [sprite setPosition:screenPoint];
//                [iconLayer addChild:sprite];

                SendTouch sendTouch = {touchPoint.x, touchPoint.y, updateSec};
                sendData.touches[sendData.tableSize] = sendTouch;
                sendData.tableSize++;

                [bullets addObject:[[ShootBullet alloc] initWithParamSend:updateSec touchPoint:screenPoint iconLayer:iconLayer]];
                recieveTouchIndex++;

                if(currentMatch == nil) {
                    recieveData.touches[recieveData.tableSize] = sendTouch;
                    recieveData.tableSize++;
                }
                touched = true;
            }
        }
        else if(phase == 4) {
            if(valid) {
                for(ShootBullet* bullet in bullets) {
                    if([bullet touch:screenPoint])
                        break;
                }
            }
        }
    }
    if(touched)
        shootSec = INTERVAL_TIME;
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

- (BOOL)isGameCenterAvailable
{
    // Test for Game Center availability
    Class gameKitLocalPlayerClass = NSClassFromString(@"GKLocalPlayer");
    BOOL localPlayerAvailable = (gameKitLocalPlayerClass != nil);
    
    // Test if device is running iOS 4.1 or higher
    NSString *requireSysVer = @"4.1";
    NSString *currentSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL isOSVer41 = ([currentSysVer compare:requireSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return localPlayerAvailable && isOSVer41;
}

- (void)authenticateLocalPlayer
{
    if (gameCenterAvailable) {
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        if (!localPlayer.authenticated)
        {
            localPlayer.authenticateHandler = ^(UIViewController* ui, NSError* _error )
            {
                self->error = _error;
                
                if (_error == nil) {
                    // ゲーム招待を処理するためのハンドラを設定する
                    [self initMatchInviteHandler];
                }
            };
        }
    }
}

- (void)initMatchInviteHandler
{
    if (gameCenterAvailable) {
        [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
            // 既存のマッチングを破棄する
            if (self->currentMatch != nil) {
                [self->currentMatch release];
                self->currentMatch = nil;
            }
            
            if (acceptedInvite) {
                // ゲーム招待を利用してマッチメイク画面を開く
                [self showMatchmakerWithInvite:acceptedInvite];
            } else if (playersToInvite) {
                // 招待するユーザを指定してマッチメイク要求を作成する
                GKMatchRequest *request = [[[GKMatchRequest alloc] init] autorelease];
                request.minPlayers = 2;
                request.maxPlayers = 2;
                request.playersToInvite = playersToInvite;
                
                [self showMatchmakerWithRequest:request];
            }
        };
    }
}

- (void)showMatchmakerWithRequest:(GKMatchRequest *)request
{
    GKMatchmakerViewController *viewController = [[[GKMatchmakerViewController alloc] initWithMatchRequest:request] autorelease];
    viewController.matchmakerDelegate = (id)self;
    [[CCDirector sharedDirector] presentViewController: viewController animated:YES completion: nil];
}

- (void)showMatchmakerWithInvite:(GKInvite *)invite
{
    GKMatchmakerViewController *viewController = [[[GKMatchmakerViewController alloc] initWithInvite:invite] autorelease];
    viewController.matchmakerDelegate = (id)self;
    [[CCDirector sharedDirector] presentViewController: viewController animated:YES completion: nil];
}

- (void)requestMatch
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    if (localPlayer.authenticated) {
        // 対戦相手を決める
        GKMatchRequest *request = [[[GKMatchRequest alloc] init] autorelease];
        request.minPlayers = 2;
        request.maxPlayers = 2;
        life = 100;
        CGRect rect = lifeGauge.textureRect;
        CGSize size = lifeGauge.texture.contentSize;
        rect.size.width = size.width;
        [lifeGauge setTextureRect:rect];
        matchStarted = NO;
        [self showMatchmakerWithRequest:request];
    }
}

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [[CCDirector sharedDirector] dismissModalViewControllerAnimated:YES];
    // implement any specific code in your application here.
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [[CCDirector sharedDirector] dismissModalViewControllerAnimated:YES];
    // Display the error to the user.
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    [[CCDirector sharedDirector] dismissModalViewControllerAnimated:YES];
    [match retain];
    self->currentMatch = match;
    match.delegate=self->match_callback;
    NSLog(@"currentMatch address %@", self->currentMatch);
    
    // 全ユーザが揃ったかどうか
    if (!matchStarted && match.expectedPlayerCount == 0) {
        matchStarted = YES;
        // ゲーム開始の処理
        phase = 0;
        myState = 0;
        vsState = 0;
    }
}

- (void)sendDataToAllPlayers:(void *)data sizeInBytes:(NSUInteger)sizeInBytes
{
    if (gameCenterAvailable) {
        NSError *_error = nil;
        NSData *packetData = [NSData dataWithBytes:data length:sizeInBytes];
        [self->currentMatch sendDataToAllPlayers:packetData withDataMode:GKMatchSendDataUnreliable error:&_error];
        self->error = _error;
        if(self->error != nil) {
            NSLog(@"self->error");
        }
    }
}
@end

// MatchCallback implementation
@implementation MatchCallback

@synthesize recieveData;
@synthesize recieveTouched;

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    // データを受け取ってアプリで利用する
    [data getBytes:&recieveData length:sizeof(SendData)];
    recieveTouched = true;
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}
@end
