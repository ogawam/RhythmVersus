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
#define MULTI_INPUT_TIME 0.1f
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
        error_ = nil;
        currentMatch = nil;
        matchStarted = NO;
        match_callback = [[MatchCallback alloc] init];
        updateSec = 0;
        offenceBullets = [[NSMutableArray alloc] init];
        defenceBullets = [[NSMutableArray alloc] init];
        lifeL = 100;
        lifeR = 100;
        tension = 0;

        touchLogs = [[NSMutableDictionary alloc] init];

        offenceCount = 0;
        defenceSec = 5;
        multiInputSec = 0;

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

        CCSprite* versus = [CCSprite spriteWithFile:@"rvVersus.png"];        
        CGRect vsTexRect = versus.textureRect;
        [versus setPosition:lfPosition];
        [self addChild:versus];

        lifeGaugeL = [CCSprite spriteWithFile:@"rvLifeGaugeL.png"];
        lfPosition.x -= vsTexRect.size.width/2;
        [lifeGaugeL setPosition:lfPosition];
        [lifeGaugeL setAnchorPoint:ccp(1,0.5f)];
        [self addChild:lifeGaugeL];

        lifeGaugeR = [CCSprite spriteWithFile:@"rvLifeGaugeR.png"];
        lfPosition.x += vsTexRect.size.width;
        [lifeGaugeR setPosition:lfPosition];
        [lifeGaugeR setAnchorPoint:ccp(0,0.5f)];
        [self addChild:lifeGaugeR];

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

        CCSprite* tensionFrame = [CCSprite spriteWithFile:@"rvTimeFrame.png"];
        tfTexRect = tensionFrame.textureRect;
        tfPosition = ccp(size.width/2, tfTexRect.size.height * 2);
        [tensionFrame setPosition:tfPosition];
        [self addChild:tensionFrame];

        tensionGauge = [CCSprite spriteWithFile:@"rvTensionGauge.png"];
        tfPosition.x -= tfTexRect.size.width/2;
        [tensionGauge setPosition:tfPosition];
        [tensionGauge setAnchorPoint:ccp(0,0.5f)];

        CGRect tgTexRect = tensionGauge.textureRect;
        tgTexRect.size.width = 0;
        [tensionGauge setTextureRect:tgTexRect];
        [self addChild:tensionGauge];

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
*/
        stateLabel = [CCLabelTTF labelWithString:@"" fontName:@"Arial Rounded MT Bold" fontSize:16];
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
    if(match_callback.recieveTouched) {
        match_callback.recieveTouched = NO;

        for(int i = 0; i < match_callback.recieveData.tableSize; ++i)
            defenceData.touches[defenceData.tableSize + i] = match_callback.recieveData.touches[i];
        defenceData.tableSize += match_callback.recieveData.tableSize;

        lifeR = match_callback.recieveData.life;
        float rate = (lifeR / 100.f);
        CGRect rect = lifeGaugeR.textureRect;
        CGSize size = lifeGaugeR.texture.contentSize;
        rect.size.width = size.width * rate;
        rect.origin.x = size.width * (1 - rate);
        [lifeGaugeR setTextureRect:rect];

        vsPhase = max(vsPhase, match_callback.recieveData.state);
    }

    [stateLabel setString: [NSString stringWithFormat:@"myPhase %d\nvsPhase %d", myPhase, vsPhase]];

    // 相手からの攻撃を生成する
    if(defenceSec < 5 && defenceData.tableSize > 0) {
        while(defenceTouchIndex < defenceData.tableSize) {
            SendTouch touch = defenceData.touches[defenceTouchIndex];

            int damage = 10;
            float reachSec = NORMAL_SPEED;
            enum Type type = BT_Normal;
            enum Mode mode = (enum Mode)touch.mode;

            if(touch.charge > SNIPE_CHARGE_TIME) {
                damage += 40 * (touch.charge / 5);
                reachSec = SNIPE_SPEED;
                type = BT_Snipe;
            }

            if(defenceSec >= touch.sec - reachSec) {
                float scale = 768;
                CGPoint position = ccp(touch.x, touch.y);
                position.x = winSize.width / 2 + position.x * scale;
                position.y = winSize.height / 2 + position.y * scale;

                ShootBullet* bullet = [[ShootBullet alloc] initWithParamDefence:defenceSec justTime:touch.sec shotType:type shotMode:mode touchPoint:position iconLayer:iconLayer];
                [bullet setDamage:damage];
                [defenceBullets addObject:bullet];
                defenceTouchIndex++;

                lifeR -= 2;
                lifeR = max(lifeR, 0);
                float rate = (lifeR / 100.f);
                CGRect rect = lifeGaugeR.textureRect;
                CGSize size = lifeGaugeR.texture.contentSize;
                rect.size.width = size.width * rate;
                rect.origin.x = size.width * (1 - rate);
                [lifeGaugeR setTextureRect:rect];
            }
            else break;
        }
    }

    // 相手からの攻撃を更新する
    for(ShootBullet* bullet in defenceBullets) {
        if([bullet update:defenceSec]) {
            lifeL -= [bullet getDamage];
            if(lifeL < 0)
                lifeL = 0;
            float rate = (lifeL / 100.f);
            CGRect rect = lifeGaugeL.textureRect;
            CGSize size = lifeGaugeL.texture.contentSize;
            rect.size.width = size.width * rate;
            [lifeGaugeL setTextureRect:rect];
            CCLayerColor* layerColor = [CCLayerColor layerWithColor:ccc4(255,0,0,128)];
            [layerColor runAction:[CCSequence actions:
                [CCFadeTo actionWithDuration:0.25f opacity:0],
                [CCCallBlockN actionWithBlock:^(CCNode* node){
                    [self removeChild:node cleanup:YES];
                }],
                nil
            ]];
            [self addChild:layerColor];

            offenceData.state = myPhase;
            offenceData.life = lifeL;
            [self sendDataToAllPlayers: &offenceData sizeInBytes:sizeof(SendData)];
        }
    }

    // 自分からの攻撃を更新する
    for(ShootBullet* bullet in offenceBullets) {
        [bullet update:offenceSec];
    }

    switch(state) {
    case GS_GameStart: 
        if(myPhase == vsPhase && updateSec > 2)
            [self setState:GS_WaitForOffence];
        break;

    case GS_WaitForOffence:
        if(myPhase == vsPhase && updateSec > 1) {
            if(lifeL == 0 || lifeR == 0)
                [self setState:GS_GameEnd];
            else {
                offenceData.life = lifeL;
                defenceData.tableSize = 0;
                defenceTouchIndex = 0;
                shootSec = 0;
                offenceSec = 0;
                [self setState:GS_Offence];
            }
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

                offenceData.state = myPhase;
                offenceData.life = lifeL;
                [self sendDataToAllPlayers: &offenceData sizeInBytes:sizeof(SendData)];
                offenceData.tableSize = 0;
            }
        }
        else {
            defenceSec = -1;

            myPhase++;

            if(!isOnline) {
                for(int i = 0; i < offenceData.tableSize; ++i)
                    defenceData.touches[defenceData.tableSize + i] = offenceData.touches[i];
                defenceData.tableSize += offenceData.tableSize;   
                vsPhase++;
            }

            offenceCount = 0;

            offenceData.state = myPhase;
            offenceData.life = lifeL;
            [self sendDataToAllPlayers: &offenceData sizeInBytes:sizeof(SendData)];
            offenceData.tableSize = 0;

            [self setState:GS_WaitForDefence];
        }

        {
            CGPoint pos;
            pos.x = (winSize.width-768)/2+ 768*rhythmSec/RHYTHM_TIME;
            pos.y = winSize.height/2;
            float rate = shootSec / INTERVAL_TIME;
            ccColor3B color = ccWHITE;

            if(rate > 0) {
                pos.y += winSize.height/4 * (1-sinf(3.14/2 * (1-rate))) * sinf(3.14f * (rhythmSec / 0.05f));
                color.g = color.b = 255 * (1-rate);
            }

            rhythmSec += deltaTime;
            rhythmLines[rhythmLineCount].color = color;
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
        multiInputSec -= deltaTime;
        shootSec -= deltaTime;
        break;

    case GS_WaitForDefence:
        if(myPhase == vsPhase && updateSec > 1) {
            if(tension == 100) {
                tension = 0;
                CGRect rect = tensionGauge.textureRect;
                CGSize size = tensionGauge.texture.contentSize;
                rect.size.width = 0;
                [tensionGauge setTextureRect:rect];                        
            } 

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
            offenceData.tableSize = 0;
            offenceData.state = myPhase;
            offenceData.life = lifeL;
            [self sendDataToAllPlayers: &offenceData sizeInBytes:sizeof(SendData)];
            [self setState:GS_WaitForOffence];
        }
        break;
            
    case GS_GameEnd: 
        if(updateSec > 2)
            [self setState:GS_ModeSelect];
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
        id touchLog = [[TouchLog alloc] initWithParam:[touch locationInView:[touch view]] timestamp:touch.timestamp];
        [touchLogs setObject:touchLog forKey:[[NSString alloc] initWithFormat:@"%d",touch.hash]];
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];

    int touchNum = 0;
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
                if(multiInputSec > 0 || shootSec < 0) {
                    rhythmLines[rhythmLineCount].color = ccRED;

                    enum Mode mode = BM_None;
                    if(tension == 100)
                        mode = BM_Gather;
                    
                    SendTouch sendTouch = {touchPoint.x, touchPoint.y, updateSec, touchSec, mode};
                    offenceData.touches[offenceData.tableSize] = sendTouch;
                    offenceData.state = myPhase;
                    offenceData.tableSize++;

                    float reachSec = NORMAL_SPEED;
                    enum Type type = BT_Normal;
                    if(touchSec > SNIPE_CHARGE_TIME) {
                        reachSec = SNIPE_SPEED;
                        type = BT_Snipe;
                    }

                    [offenceBullets addObject:[[ShootBullet alloc] initWithParamOffence:updateSec justTime:updateSec + reachSec shotType:type shotMode:mode touchPoint:screenPoint iconLayer:iconLayer]];
                    touchNum++;
                }
            }
            else {
                for(ShootBullet* bullet in defenceBullets) {
                    int prise = [bullet touch:screenPoint];
                    if(prise > 0) {
                        tension = min(tension + prise, 100);
                        CGRect rect = tensionGauge.textureRect;
                        CGSize size = tensionGauge.texture.contentSize;
                        rect.size.width = size.width * (tension / 100.f);
                        [tensionGauge setTextureRect:rect];                        
                        break;
                    }
                }
            }
        }
    }

    if(touchNum > 0) {
        if(multiInputSec < 0)
            multiInputSec = MULTI_INPUT_TIME;
        shootSec = max(shootSec, 0) + INTERVAL_TIME * touchNum;
    }
//    NSLog(@"touchLogs count %d", touchLogs.count);
}

- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        [touchLogs removeObjectForKey:[[NSString alloc] initWithFormat:@"%d",touch.hash]];
    }
//    NSLog(@"touchLogs count %d", touchLogs.count);
}

-(void) setState:(enum GameState)state_ {
    AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
    float scaleBase = appCtrler.isRetina ? 2: 1;

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
                [self requestMatch];
/*
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ブログ" message:@"確認ダイアログですよね？" delegate: self cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
             
                [alert show];
                [alert release];                
*/
            } ];
            
            CCMenuItem *itemRematch = [CCMenuItemFont itemWithString:@"Rematch" block:^(id offenceer) {
                if(isOnline) {
                    offenceData.tableSize = 0;
                    offenceData.state = 0;
                    offenceData.life = 100;
                    myPhase = 0;
                    vsPhase = -1;
                    [self sendDataToAllPlayers: &offenceData sizeInBytes:sizeof(SendData)];
                    [self removeChild: menuModeSelect cleanup:YES];
                    [self setState:GS_GameStart];                    
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"確認" message:@"オンライン対戦後に選択して下さい" delegate: self cancelButtonTitle:@"" otherButtonTitles:@"OK", nil];
                 
                    [alert show];
                    [alert release];                
                }
            } ];

            CCMenuItem *itemAutoMatch = [CCMenuItemFont itemWithString:@"AutoMatch" block:^(id offenceer) {
                [self findProgrammaticMatch: self];
            } ];

            CCMenuItem *itemAutoMatchCancel = [CCMenuItemFont itemWithString:@"AutoMatchCancel" block:^(id offenceer) {
                [[GKMatchmaker sharedMatchmaker] cancel];
            } ];

            menuModeSelect = [CCMenu menuWithItems: itemSingle, itemOnline, itemRematch, itemAutoMatch, itemAutoMatchCancel, nil];
            [menuModeSelect setColor:ccBLACK];
            [menuModeSelect alignItemsVerticallyWithPadding:16 * scale];
            [menuModeSelect setPosition:ccp(size.width/2, size.height/2)];
            // Add the menu to the layer
            [self addChild:menuModeSelect z:10];
        }
        break;

    case GS_GameStart:
        {
            lifeL = 100;
            CGRect rect = lifeGaugeL.textureRect;
            CGSize size = lifeGaugeL.texture.contentSize;
            rect.size.width = size.width;
            [lifeGaugeL setTextureRect:rect];

            lifeR = 100;
            rect = lifeGaugeR.textureRect;
            size = lifeGaugeR.texture.contentSize;
            rect.size.width = size.width;
            rect.origin.x = 0;
            [lifeGaugeR setTextureRect:rect];

            tension = 0;
            rect = tensionGauge.textureRect;
            size = tensionGauge.texture.contentSize;
            rect.size.width = size.width * (tension / 100.f);
            [tensionGauge setTextureRect:rect];                        
        }

        [countDown setString:[NSString stringWithFormat:@"Sound your Beats!"]];
        [countDown setScale:scaleBase];
        [countDown setOpacity: 255];
        [countDown stopAllActions];
        [countDown runAction:
            [CCSpawn actions:
                [CCEaseOut actionWithAction: 
                    [CCScaleTo actionWithDuration:2.f scale: scaleBase * 2 ] rate:2 
                ],
                [CCFadeTo actionWithDuration:2.f opacity: 0],
                nil
            ]
        ];
        break;

    case GS_WaitForOffence:
        {
            CGRect rect = timeGauge.textureRect;
            CGSize size = timeGauge.texture.contentSize;
            rect.size.width = size.width;
            [timeGauge setTextureRect:rect];
        }
        [countDown setString:[NSString stringWithFormat:@"Offence Ready?"]];
        [countDown setScale:scaleBase * 3];
        [countDown setOpacity: 255];
        [countDown stopAllActions];
        [countDown runAction:
            [CCSequence actions:
                [CCEaseOut actionWithAction: 
                    [CCScaleTo actionWithDuration:0.75f scale: scaleBase ] rate:2 
                ],
                [CCFadeTo actionWithDuration:0.25f opacity: 0],
                nil
            ]
        ];
        break;    

    case GS_Offence:
        rhythmLines[rhythmLineCount] = [CCMotionStreak streakWithFade:RHYTHM_TIME minSeg:8 width:8 color:ccWHITE textureFilename:@"rvCenterLine.png"];
        rhythmLines[rhythmLineCount].position = ccp((size.width-768)/2, size.height/2);
        [gameLayer addChild:rhythmLines[rhythmLineCount]];
        rhythmSec = 0;
        break;

    case GS_WaitForDefence:
        {
            CGRect rect = timeGauge.textureRect;
            CGSize size = timeGauge.texture.contentSize;
            rect.size.width = size.width;
            [timeGauge setTextureRect:rect];
        }

        [countDown setString:[NSString stringWithFormat:@"Defence Ready?"]];
        [countDown setScale:scaleBase * 3];
        [countDown setOpacity: 255];
        [countDown stopAllActions];
        [countDown runAction:
            [CCSequence actions:
                [CCEaseOut actionWithAction: 
                    [CCScaleTo actionWithDuration:0.75f scale: scaleBase ] rate:2 
                ],
                [CCFadeTo actionWithDuration:0.25f opacity: 0],
                nil
            ]
        ];

        for(int i = 0; i < 2; ++i) {
            if(rhythmLines[i] != nil) {
                [gameLayer removeChild: rhythmLines[i] cleanup:YES];
                rhythmLines[i] = nil;
            }
        }
        rhythmLineCount = 0;
        break;

    case GS_GameEnd:
        if(lifeL == 0)
            if(lifeR == 0)
                [countDown setString:[NSString stringWithFormat:@"Draw"]];
            else [countDown setString:[NSString stringWithFormat:@"Lose"]];
        else [countDown setString:[NSString stringWithFormat:@"Win"]];

        [countDown setScale:scaleBase];
        [countDown setOpacity: 255];
        [countDown stopAllActions];
        [countDown runAction:
            [CCSpawn actions:
                [CCEaseOut actionWithAction: 
                    [CCScaleTo actionWithDuration:2.f scale: scaleBase * 2 ] rate:2 
                ],
                [CCFadeTo actionWithDuration:2.f opacity: 0],
                nil
            ]
        ];        
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
                self->error_ = _error;
                
                if (_error == nil) {
                    // ゲーム招待を処理するためのハンドラを設定する
                    [self initMatchInviteHandler];
                    
                    [self findProgrammaticMatch:self];
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

- (IBAction)findProgrammaticMatch: (id) sender
{
    GKMatchRequest *request = [[[GKMatchRequest alloc] init] autorelease];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    [[GKMatchmaker sharedMatchmaker] findMatchForRequest:request
        withCompletionHandler:^(GKMatch *match, NSError *error) {
            if (error != nil)
            {
             // エラー処理
            }
            else if (match != nil)
            {
                // matchを保持させる
                [match retain];
                self->currentMatch = match; // 保持用のプロパティを使用して対戦を保持する
                match.delegate = self->match_callback;

                if (!matchStarted && match.expectedPlayerCount == 0)　{
                    matchStarted = YES;
                    isOnline = YES;

                    // ゲーム開始の処理
                    myPhase = 0;
                    vsPhase = 0;

                    [self removeChild: menuModeSelect cleanup:YES];
                    [self setState: GS_GameStart];

                     // 対戦開始に当たって必要な、ゲーム固有のコードをここに記述する
                }
            }
        }
    ];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    // ダイアログをアニメーション(YES)で閉じる
    [[CCDirector sharedDirector] dismissModalViewControllerAnimated:YES];

    // matchを保持させる
    [match retain];
    self->currentMatch = match;
    match.delegate = self->match_callback;

    // 全ユーザが揃ったかどうか
    if (!matchStarted && match.expectedPlayerCount == 0) {
        matchStarted = YES;
        isOnline = YES;
        // ゲーム開始の処理
        myPhase = 0;
        vsPhase = 0;

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
        self->error_ = _error;
        if(self->error_ != nil) {
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
