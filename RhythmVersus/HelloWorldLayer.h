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

#define SendTableMax 32

typedef struct {
    float x;
    float y;
    float sec;
} SendTouch;

typedef struct {
	SendTouch touches[SendTableMax];
	int tableSize;
    int state;
} SendData;

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
    CCLabelTTF *stateLabel;
    CCLabelTTF *countDown;
    CCSprite* timeGauge;
    int myState;
    int vsState;
    int phase;
    int recieveTouchIndex;
    float updateSec;
    SendData sendData;
    SendData recieveData;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@property (nonatomic, retain) GKMatch *currentMatch;

@end
