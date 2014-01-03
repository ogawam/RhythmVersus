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
        offenceBullets = [[NSMutableArray alloc] init];
        defenceBullets = [[NSMutableArray alloc] init];
        life = 100;

        offenceCount = 0;

        [self setState: GS_ModeSelect];
        
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
		CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id offenceer) {
			
			
			GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
			achivementViewController.achievementDelegate = self;
			
			AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
			
			[[app navController] presentModalViewController:achivementViewController animated:YES];
			
			[achivementViewController release];
		} ];

		// Leaderboard Menu Item using blocks
		CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id offenceer) {
			
			
			GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
			leaderboardViewController.leaderboardDelegate = self;
			
			AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
			
			[[app navController] presentModalViewController:leaderboardViewController animated:YES];
			
			[leaderboardViewController release];
		} ];
*/
		CCMenuItem *itemLogin = [CCMenuItemFont itemWithString:@"Login" block:^(id offenceer) {
            [self authenticateLocalPlayer];
        } ];
        
		CCMenuItem *itemMatch = [CCMenuItemFont itemWithString:@"Match" block:^(id offenceer) {
            [self requestMatch];
        } ];
    
        CCMenuItem *itemClear = [CCMenuItemFont itemWithString:@"Clear" block:^(id offenceer) {
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
    // 相手からの攻撃を受信する
    if(match_callback.recieveTouched) {
        match_callback.recieveTouched = NO;

        for(int i = 0; i < match_callback.recieveData.tableSize; ++i)
            defenceData.touches[i] = match_callback.recieveData.touches[i];
        defenceData.tableSize += match_callback.recieveData.tableSize;

        vsState = match_callback.recieveData.state;
    }

    // 相手からの攻撃を生成する
    if(defenceData.tableSize > 0) {
        while(defenceTouchIndex < defenceData.tableSize) {
            if(defenceSec >= defenceData.touches[defenceTouchIndex].sec - 2) {
                AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
                float scale = 768;
                CGSize winSize = [[CCDirector sharedDirector] winSize];
                CGPoint position = ccp(defenceData.touches[defenceTouchIndex].x, defenceData.touches[defenceTouchIndex].y);
                position.x = winSize.width / 2 + position.x * scale;
                position.y = winSize.height / 2 + position.y * scale;

                [defenceBullets addObject:[[ShootBullet alloc] initWithParamRecieve:defenceData.touches[defenceTouchIndex].sec touchPoint:position iconLayer:iconLayer]];
                defenceTouchIndex++;
            }
            else break;
        }
    }

    // 相手からの攻撃を更新する
    for(ShootBullet* bullet in defenceBullets) {
        if([bullet update:defenceSec]) {
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

    // 自分からの攻撃を更新する
    for(ShootBullet* bullet in offenceBullets) {
        [bullet update:offenceSec];
    }

    switch(state) {
    case GS_GameStart: 
        [self setState:GS_WaitForOffence];
        break;

    case GS_WaitForOffence:
        if(updateSec < 0) {
            [countDown setScale:10 * (1-fmodf(updateSec, 1))];
            [countDown setString:[NSString stringWithFormat:@"%d", 3-(int)updateSec]];
        }
        else {
            offenceData.tableSize = 0;
            defenceData.tableSize = 0;
            defenceTouchIndex = 0;
            shootSec = INTERVAL_TIME;
            offenceSec = 0;
            [self setState:GS_Offence];
        }
        break;

    case GS_Offence:
        if(updateSec < 5) {
            float rate = 1 - (updateSec / 5.f);
            CGRect rect = timeGauge.textureRect;
            CGSize size = timeGauge.texture.contentSize;
            rect.size.width = size.width * rate;
            [timeGauge setTextureRect:rect];

            if(offenceCount < 1 && updateSec > 2.5f) {
                defenceSec = -2.5f;
               [defenceBullets removeAllObjects];
                offenceCount++;

                if(currentMatch == nil) {
                    for(int i = 0; i < offenceData.tableSize; ++i)
                        defenceData.touches[defenceData.tableSize + i] = offenceData.touches[i];
                    defenceData.tableSize += offenceData.tableSize;   
                }

                [self sendDataToAllPlayers: &offenceData sizeInBytes:sizeof(SendData)];
                offenceData.tableSize = 0;
            }
        }
        else {
            defenceSec = 0;

            if(currentMatch == nil) {
                for(int i = 0; i < offenceData.tableSize; ++i)
                    defenceData.touches[defenceData.tableSize + i] = offenceData.touches[i];
                defenceData.tableSize += offenceData.tableSize;   
            }

            offenceCount = 0;

            myState++;
            offenceData.state = myState;
            [self sendDataToAllPlayers: &offenceData sizeInBytes:sizeof(SendData)];
            [stateLabel setString: [NSString stringWithFormat:@"myState %d\nvsState %d", myState, vsState]];

            [self setState:GS_WaitForDefence];
        }
        shootSec -= deltaTime;
        break;

    case GS_WaitForDefence:
       if(updateSec < 0) {
            [countDown setScale:10 * (1-fmodf(updateSec, 1))];
            [countDown setString:[NSString stringWithFormat:@"%d", 3-(int)updateSec]];

            CGRect rect = timeGauge.textureRect;
            CGSize size = timeGauge.texture.contentSize;
            rect.size.width = size.width;
            [timeGauge setTextureRect:rect];
        }
        else {
            [self setState:GS_Defence];
        }
        break;

    case GS_Defence:
        if(updateSec < 5) {
            float rate = 1 - (updateSec / 5.f);
            CGRect rect = timeGauge.textureRect;
            CGSize size = timeGauge.texture.contentSize;
            rect.size.width = size.width * rate;
            [timeGauge setTextureRect:rect];
        }
        else {            
            [self setState:GS_WaitForOffence];
        }
        break;
    }
    updateSec += deltaTime;
    offenceSec += deltaTime;
    defenceSec += deltaTime;
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

        if(valid) {
            if(state == GS_Offence) {
                if(shootSec < 0) {
                    CCSprite* sprite = [CCSprite spriteWithFile:@"Icon-72.png"];
                    AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
                    if(appCtrler.isRetina)
                        [sprite setScale:2];
                    [sprite setPosition:screenPoint];

                    SendTouch sendTouch = {touchPoint.x, touchPoint.y, updateSec};
                    offenceData.touches[offenceData.tableSize] = sendTouch;
                    offenceData.tableSize++;

                    [offenceBullets addObject:[[ShootBullet alloc] initWithParamSend:updateSec touchPoint:screenPoint iconLayer:iconLayer]];
                    touched = true;
                }
            }
            else {
                for(ShootBullet* bullet in defenceBullets) {
                    if([bullet touch:screenPoint])
                        break;
                }
            }
        }
    }
    if(touched)
        shootSec = INTERVAL_TIME;
}

-(void) setState:(enum GameState)state_ {
    CGSize size = [[CCDirector sharedDirector] winSize];
    updateSec = 0;

    switch(state = state_) {
    case GS_ModeSelect: 
        {    
            //
            // Leaderboards and Achievements
            //
            
            // Default font size will be 28 points.
            float scale = (size.width / 768.f);
            [CCMenuItemFont setFontSize:64 * scale];

            CCMenuItem *itemSingle = [CCMenuItemFont itemWithString:@"Single Game" block:^(id offenceer) {
                isOnline = NO;
                [self removeChild: menuModeSelect cleanup:YES];
                [self setState:GS_GameStart];
            } ];
            
            CCMenuItem *itemOnline = [CCMenuItemFont itemWithString:@"Online Game" block:^(id offenceer) {
                isOnline = YES;
                [self requestMatch];

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ブログ" message:@"確認ダイアログですよね？" delegate: self cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
             
                [alert show];
                [alert release];                
            } ];
            
            menuModeSelect = [CCMenu menuWithItems: itemSingle, itemOnline, nil];
            [menuModeSelect setColor:ccBLACK];
            [menuModeSelect alignItemsVerticallyWithPadding:16 * scale];
            [menuModeSelect setPosition:ccp(size.width/2, size.height/2)];
            // Add the menu to the layer
            [self addChild:menuModeSelect z:10];
        }
        break;
    }
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
