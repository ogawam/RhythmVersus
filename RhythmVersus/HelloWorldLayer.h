//
//  HelloWorldLayer.h
//  RhythmVersus
//
//  Created by 小川 穣 on 2013/11/30.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

#define SendTableMax 128

typedef struct {
    float x;
    float y;
    float sec;
    float charge;
} SendTouch;

typedef struct {
	SendTouch touches[SendTableMax];
	int tableSize;
    int state;
} SendData;

@interface TouchLog: NSObject {
}
-(id) initWithParam:(CGPoint)pos_ timestamp:(float)timestamp_;
@property (assign) CGPoint pos;
@property (assign) float timestamp;
@end

// MatchCallback
@interface MatchCallback : NSObject <GKMatchDelegate> {
	SendData recieveData;
	bool recieveTouched;
    bool matchStarted;
}

@property (assign) SendData recieveData;
@property (assign) bool recieveTouched;

//match
- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state;
- (void)match:(GKMatch *)match connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error;
- (void)match:(GKMatch *)match didFailWithError:(NSError *)error;
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID;

@end

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    BOOL gameCenterAvailable;
    NSError *error;
    GKMatch *currentMatch;
    MatchCallback *match_callback;
    BOOL matchStarted;
    CCLayer *iconLayer;
    CCLayer *gameLayer;
    CCLayer *backLayer;
    CCLabelTTF *stateLabel;
    CCLabelTTF *countDown;
    CCSprite* timeGauge;
    CCSprite* lifeGauge;
    int myState;
    int vsState;
    int life;
    int defenceTouchIndex;
    float shootSec;
    float updateSec;
    float rhythmSec;
    float offenceSec;
    float defenceSec;
    int offenceCount;
    SendData offenceData;
    SendData defenceData;
    NSMutableArray *offenceBullets;
    NSMutableArray *defenceBullets;

    NSMutableDictionary *touchLogs;

    CCMenu* menuModeSelect;

    CCMotionStreak* rhythmLines[2];
    int rhythmLineCount;

    BOOL isOnline;

    enum GameState {
        GS_ModeSelect,
        GS_GameStart,
        GS_WaitForOffence,
        GS_Offence,
        GS_WaitForDefence,
        GS_Defence,
        GS_GameEnd,
        GS_Result,
        GS_Max
    } state;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@property (nonatomic, retain) GKMatch *currentMatch;

@end
