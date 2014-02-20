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
    float beginTime;
    float justTime;
    float guardTime;
    float DamageTime;
    float updateTime;

    float scaleBegin;
    float scaleEnd;

    CGPoint justPos;
    CCLayer* parentLayer;

    int spriteNum;

    CCSprite* bulletSprites[2];
    CCSprite* targetSprites[2];

    NSMutableArray *effects;

    enum State {
        BS_Offence,
        BS_Defence,
        BS_Guard,
        BS_Damage,
        BS_Max
    } state;

    enum Type {
        BT_Normal,
        BT_Snipe
    } type;
}

-(id) initWithParamDefence:(float)beginTime_ justTime:(float)justTime_ shotType:(enum Type)type_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_;
-(id) initWithParamOffence:(float)beginTime_ justTime:(float)justTime_ shotType:(enum Type)type_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_;
-(BOOL) update:(float)time;
-(BOOL) touch:(CGPoint)touchPos_;
-(BOOL) isDestoyed;

@end
