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

#define RHYTHM_TIME 2.f
#define INTERVAL_TIME 0.25f
#define SNIPE_CHARGE_TIME 0.5f

#define NORMAL_SPEED 2.f
#define SNIPE_SPEED 1.f

@implementation TouchLog

@synthesize pos;
@synthesize timestamp;

-(id) initWithParam:(CGPoint)pos_ timestamp:(float)timestamp_
{
    self = [super init];
    if (self != nil) {
        pos = pos_;
        timestamp = timestamp_;
    }
    return self;
}

@end

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize currentMatch;

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

        touchLogs = [[NSMutableDictionary alloc] init];

        offenceCount = 0;
        defenceSec = 5;

        rhythmLineCount = 0;

        for(int i= 0; i < 2; ++i)
            rhythmLines[i] = nil;

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

        scale = 64 * (size.width/768.f);
        countDown = [CCLabelTTF labelWithString:@"" fontName:@"Arial Rounded MT Bold" fontSize:scale];
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
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    // 相手からの攻撃を受信する
    if(match_callback.recieveTouched && defenceSec < 5) {
        match_callback.recieveTouched = NO;

        for(int i = 0; i < match_callback.recieveData.tableSize; ++i)
            defenceData.touches[defenceData.tableSize + i] = match_callback.recieveData.touches[i];
        defenceData.tableSize += match_callback.recieveData.tableSize;

        vsState = match_callback.recieveData.state;
    }

    // 相手からの攻撃を生成する
    if(defenceData.tableSize > 0) {
        while(defenceTouchIndex < defenceData.tableSize) {

            float reachSec = NORMAL_SPEED;
            enum Type type = BT_Normal;

            if(defenceData.touches[defenceTouchIndex].charge > SNIPE_CHARGE_TIME) {
                reachSec = SNIPE_SPEED;
                type = BT_Snipe;
            }

            if(defenceSec >= defenceData.touches[defenceTouchIndex].sec - reachSec) {
                float scale = 768;
                CGPoint position = ccp(defenceData.touches[defenceTouchIndex].x, defenceData.touches[defenceTouchIndex].y);
                position.x = winSize.width / 2 + position.x * scale;
                position.y = winSize.height / 2 + position.y * scale;

                [defenceBullets addObject:[[ShootBullet alloc] initWithParamDefence:defenceSec justTime:defenceData.touches[defenceTouchIndex].sec shotType:type touchPoint:position iconLayer:iconLayer]];
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
            CCLayerColor* layerColor = [CCLayerColor layerWithColor:ccc4(255,0,0,128)];
            [layerColor runAction:[CCSequence actions:
                [CCFadeTo actionWithDuration:0.25f opacity:0],
                [CCCallBlockN actionWithBlock:^(CCNode* node){
                    [self removeChild:node cleanup:YES];
                }],
                nil
            ]];
            [self addChild:layerColor];
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
        if(updateSec < 1) {

            [countDown setScale:1 + 5 * (1-sinf(3.14f * 0.5f * fmin(1, updateSec / 0.5f)))];
            [countDown setString:[NSString stringWithFormat:@"Offence Ready?"]];
        }
        else {
            [countDown setScale:0];
            offenceData.tableSize = 0;
            defenceData.tableSize = 0;
            defenceTouchIndex = 0;
            shootSec = 0;
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
                defenceSec = -3.5f;
                [defenceBullets removeAllObjects];
                offenceCount++;

                if(!isOnline) {
                    for(int i = 0; i < offenceData.tableSize; ++i)
                        defenceData.touches[defenceData.tableSize + i] = offenceData.touches[i];
                    defenceData.tableSize += offenceData.tableSize;   
                }

                [self sendDataToAllPlayers: &offenceData sizeInBytes:sizeof(SendData)];
                offenceData.tableSize = 0;
            }
        }
        else {
            defenceSec = -1;

            if(!isOnline) {
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

        {
            float rate = shootSec / INTERVAL_TIME;
            CGPoint pos;
            pos.x = (winSize.width-768)/2+ 768*rhythmSec/RHYTHM_TIME;
            pos.y = winSize.height/2;
            if(rate > 0) {
                pos.y += winSize.height/4 * (1-sinf(3.14/2 * (1-rate))) * sinf(3.14f * (rhythmSec / 0.05f));
            }
            rhythmLines[rhythmLineCount].color = ccc3(255, 255 * (1-rate), 255 * (1-rate));

            rhythmSec += deltaTime;
            rhythmLines[rhythmLineCount].position = pos;
            if(rhythmSec > RHYTHM_TIME) {
                rhythmSec -= RHYTHM_TIME;
                rhythmLineCount++;
                rhythmLineCount%= 2;
                if(rhythmLines[rhythmLineCount] != nil) {
                    [gameLayer removeChild: rhythmLines[rhythmLineCount] cleanup:YES];
                    rhythmLines[rhythmLineCount] = nil;
                }
                rhythmLines[rhythmLineCount] = [CCMotionStreak streakWithFade:RHYTHM_TIME minSeg:8 width:8 color:ccWHITE textureFilename:@"rvCenterLine.png"];
                rhythmLines[rhythmLineCount].position = ccp((winSize.width-768)/2, winSize.height/2);
                [gameLayer addChild:rhythmLines[rhythmLineCount]];
            }
        }
        shootSec = max((shootSec - deltaTime), 0);
        break;

    case GS_WaitForDefence:
       if(updateSec < 1) {
            [countDown setScale:1 + 5 * (1-sinf(3.14f * 0.5f * fmin(1, updateSec / 0.5f)))];
            [countDown setString:[NSString stringWithFormat:@"Defence Ready?"]];

            CGRect rect = timeGauge.textureRect;
            CGSize size = timeGauge.texture.contentSize;
            rect.size.width = size.width;
            [timeGauge setTextureRect:rect];
        }
        else {
            [countDown setScale:0];
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
            
        default:
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
//    CGSize winSize = [[CCDirector sharedDirector] winSize];

    for (UITouch *touch in touches) {
        NSLog(@"touch.timestamp %d", (int)touch.timestamp);
//        touchBeganTimes[touch.tapCount] = touch.timestamp;
        id touchLog = [[TouchLog alloc] initWithParam:[touch locationInView:[touch view]] timestamp:touch.timestamp];
        [touchLogs setObject:touchLog forKey:[[NSString alloc] initWithFormat:@"%d",touch.hash]];
    }
    NSLog(@"touchLogs count %d", touchLogs.count);
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];

    bool touched = false;
    for (UITouch *touch in touches) {
        CGPoint touchPoint = [touch locationInView:[touch view]];
        TouchLog* touchLog = [touchLogs valueForKey:[[NSString alloc] initWithFormat:@"%d",touch.hash]];

        float touchSec = (touch.timestamp - touchLog.timestamp);
        CGPoint screenPoint;
        touchPoint.x = (touchPoint.x - (winSize.width / 2)) / winSize.width;
        touchPoint.y = ((winSize.height / 2) - touchPoint.y) / winSize.width;

        [touchLogs removeObjectForKey:touch.hash];

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
                if(shootSec <= 0) {
                    rhythmLines[rhythmLineCount].color = ccRED;
                    
                    SendTouch sendTouch = {touchPoint.x, touchPoint.y, updateSec, touchSec};
                    offenceData.touches[offenceData.tableSize] = sendTouch;
                    offenceData.tableSize++;

                    float reachSec = NORMAL_SPEED;
                    enum Type type = BT_Normal;
                    if(touchSec > SNIPE_CHARGE_TIME) {
                        reachSec = SNIPE_SPEED;
                        type = BT_Snipe;
                    }

                    [offenceBullets addObject:[[ShootBullet alloc] initWithParamOffence:updateSec justTime:updateSec + reachSec shotType:type touchPoint:screenPoint iconLayer:iconLayer]];
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
    NSLog(@"touchLogs count %d", touchLogs.count);
}

- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        [touchLogs removeObjectForKey:[[NSString alloc] initWithFormat:@"%d",touch.hash]];
    }
    NSLog(@"touchLogs count %d", touchLogs.count);
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
/*
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ブログ" message:@"確認ダイアログですよね？" delegate: self cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
             
                [alert show];
                [alert release];                
*/
            } ];
            
            menuModeSelect = [CCMenu menuWithItems: itemSingle, itemOnline, nil];
            [menuModeSelect setColor:ccBLACK];
            [menuModeSelect alignItemsVerticallyWithPadding:16 * scale];
            [menuModeSelect setPosition:ccp(size.width/2, size.height/2)];
            // Add the menu to the layer
            [self addChild:menuModeSelect z:10];
        }
        break;

    case GS_Offence:
        rhythmLines[rhythmLineCount] = [CCMotionStreak streakWithFade:RHYTHM_TIME minSeg:8 width:8 color:ccWHITE textureFilename:@"rvCenterLine.png"];
        rhythmLines[rhythmLineCount].position = ccp((size.width-768)/2, size.height/2);
        [gameLayer addChild:rhythmLines[rhythmLineCount]];
        rhythmSec = 0;
        break;

    case GS_WaitForDefence:
        for(int i = 0; i < 2; ++i) {
            if(rhythmLines[i] != nil) {
                [gameLayer removeChild: rhythmLines[i] cleanup:YES];
                rhythmLines[i] = nil;
            }
        }
        rhythmLineCount = 0;
        break;
        default:
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

        [self removeChild: menuModeSelect cleanup:YES];
        [self setState: GS_GameStart];
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
