//
//  ShootBullet.h
//  RhythmVersus
//
//  Created by 小川 穣 on 2013/11/30.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// ShootBullet
@interface ShootBullet : NSObject
{
    float justTime;
    float guardTime;
    float DamageTime;
    float updateTime;

    float scaleBegin;
    float scaleEnd;

    CGPoint justPos;
    CCLayer* parentLayer;

    CCSprite* sprite[2];
    CCSprite* target[2];

    enum State {
        Send,
        Recieve,
        Guard,
        Damage,
        Max
    } state;
}

-(id) initWithParamRecieve:(float)justTime_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_;
-(id) initWithParamSend:(float)justTime_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_;
-(BOOL) update:(float)time;
-(BOOL) touch:(CGPoint)touchPos_;

@end
