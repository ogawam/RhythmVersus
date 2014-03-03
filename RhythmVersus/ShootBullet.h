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
    int damage;

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

    enum Mode {
        BM_None,
        BM_Gather,
    } mode;
}

-(id) initWithParamDefence:(float)beginTime_ justTime:(float)justTime_ shotType:(enum Type)type_ shotMode:(enum Mode)mode_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_;
-(id) initWithParamOffence:(float)beginTime_ justTime:(float)justTime_ shotType:(enum Type)type_ shotMode:(enum Mode)mode_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_;
-(BOOL) update:(float)time;
-(void) setDamage:(int)damage_;
-(int) getDamage;
-(int) touch:(CGPoint)touchPos_;
-(BOOL) isDestoyed;
-(enum Type) getType;

@end
