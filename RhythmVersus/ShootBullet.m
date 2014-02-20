//
//  ShootBullet.m
//  RhythmVersus
//
//  Created by 小川 穣 on 2013/11/30.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//


// Import the interfaces
#import "ShootBullet.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#pragma mark - ShootBullet

#define TARGET_DISP_TIME 1

// ShootBullet implementation
@implementation ShootBullet

-(id) initWithParamDefence:(float)beginTime_ justTime:(float)justTime_ shotType:(enum Type)type_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_
{
    self = [super init];
    if (self != nil) {        
        type = type_;
        beginTime = beginTime_;
        justTime = justTime_;
        justPos = justPos_;
        parentLayer = parentLayer_;
        effects = [[NSMutableArray alloc] init];

        CGSize winSize = [[CCDirector sharedDirector] winSize];
        switch(type) {
        case BT_Normal:
            spriteNum = 2;
            break;
        case BT_Snipe:
            spriteNum = 1;
            break;
        }
        for(int i = 0; i < spriteNum; ++i) {
            switch(type) {
            case BT_Normal:
                if(i == 0)
                    bulletSprites[i] = [CCSprite spriteWithFile:@"rvBulletNormalBody.png"];
                else bulletSprites[i] = [CCSprite spriteWithFile:@"rvBulletNormalWind.png"];
                break;
            case BT_Snipe:
                bulletSprites[i] = [CCSprite spriteWithFile:@"rvBulletNormalWind.png"];
                break;
            }
            [bulletSprites[i] setScale:0];
            [bulletSprites[i] setColor:ccRED];
            [bulletSprites[i] setPosition:ccp(winSize.width/2, winSize.height/2 + 768 / 4)];
            [parentLayer addChild:bulletSprites[i]];
        }

        AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
        float scale = (appCtrler.isRetina) ? 2:1;
        scaleBegin = scale * 0.75f;
        scaleEnd = scale * 1.25f;

        for(int i = 0; i < 2; ++i) {
            targetSprites[i] = [CCSprite spriteWithFile:@"rvShotNormal.png"];
            [targetSprites[i] setPosition:justPos];
            [targetSprites[i] setOpacity:0];
            [targetSprites[i] setColor:ccBLACK];
            [targetSprites[i] setRotation:30 * i];
            [parentLayer addChild:targetSprites[i]];
        }
        state = BS_Defence;
    }
    return self;    
}

-(id) initWithParamOffence:(float)beginTime_ justTime:(float)justTime_ shotType:(enum Type)type_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_
{
    self = [super init];
    if (self != nil) {
        type = type_;
        beginTime = beginTime_;
        justTime = justTime_;
        justPos = justPos_;
        parentLayer = parentLayer_;
        effects = [[NSMutableArray alloc] init];

        switch(type) {
        case BT_Normal:
            spriteNum = 2;
            break;
        case BT_Snipe:
            spriteNum = 1;
            break;
        }
//        CGSize winSize = [[CCDirector sharedDirector] winSize];
        for(int i = 0; i < spriteNum; ++i) {
            switch(type) {
            case BT_Normal:
                if(i == 0)
                    bulletSprites[i] = [CCSprite spriteWithFile:@"rvBulletNormalBody.png"];
                else bulletSprites[i] = [CCSprite spriteWithFile:@"rvBulletNormalWind.png"];
                break;
            case BT_Snipe:
                bulletSprites[i] = [CCSprite spriteWithFile:@"rvBulletNormalWind.png"];
                break;
            }
            AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
            float scale = (appCtrler.isRetina) ? 2:1;
            [bulletSprites[i] setFlipX:YES];
            [bulletSprites[i] setScale:scale];
            [bulletSprites[i] setColor:ccGREEN];
            [bulletSprites[i] setPosition:justPos];
            [parentLayer addChild:bulletSprites[i]];
        }
        state = BS_Offence;
    }
    return self;    
}

-(BOOL) update:(float)time {

    CGSize winSize = [[CCDirector sharedDirector] winSize];

    switch(state) {
    case BS_Offence:
        for(int i = 0; i < spriteNum; ++i) {
            CGPoint pos = ccp(winSize.width/2,winSize.height/2 + 768 / 4);
            float posRate = i == 1 ? time: time - 0.01666f * 3;
            posRate = 1 - sinf((3.14f/2)+(3.14f/2) * ((posRate - justTime) / (justTime - beginTime)));
            posRate = posRate * posRate;
            pos.x += (justPos.x - pos.x) * posRate;
            pos.y += (justPos.y - pos.y) * posRate;

            AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
            float scale = (appCtrler.isRetina) ? 2:1;
            [bulletSprites[i] setScale:scale * posRate];
            [bulletSprites[i] setRotation:360 * 2 * posRate];
            [bulletSprites[i] setPosition:pos];

            if(time - justTime > 0) {
                [self destroy];
            }
        }
        if(type == BT_Snipe) {
            if(fmod(time, 0.1f) < fmod(updateTime, 0.1f)) {
                CCSprite* sprite = [CCSprite spriteWithFile:@"rvBulletNormalWind.png"];
                [sprite setPosition: bulletSprites[0].position];
                [sprite setScale: bulletSprites[0].scale];
                [sprite setColor: bulletSprites[0].color];
                [sprite runAction: 
                    [CCSpawn actions:
                        [CCEaseOut actionWithAction:[CCScaleBy actionWithDuration:0.5f scale:2] rate: 3],
                        [CCEaseOut actionWithAction:[CCFadeOut actionWithDuration:0.5f] rate: 3],
                        nil
                    ]
                ];
                [parentLayer addChild: sprite];
                [effects addObject:sprite]; 
            }
        }
        break;

    case BS_Defence:
        for(int i = 0; i < spriteNum; ++i) {
            CGPoint pos = ccp(winSize.width/2,winSize.height/2 + 768 / 4);
            float posRate = i == 1 ? time: time - 0.01666f * 3;
            posRate = 1-sinf((3.14f/2)+(3.14f/2) * ((posRate - beginTime) /  (justTime - beginTime)));
            posRate = posRate * posRate;
            pos.x += (justPos.x - pos.x) * posRate;
            pos.y += (justPos.y - pos.y) * posRate;

            AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
            float scale = (appCtrler.isRetina) ? 2:1;
            [bulletSprites[i] setScale:scale * posRate];
            [bulletSprites[i] setRotation:-360 * 2 * posRate];
            [bulletSprites[i] setPosition:pos];
        }
        
        if(time > justTime - (TARGET_DISP_TIME * 0.5f) 
        && time < justTime + (TARGET_DISP_TIME * 0.5f)) 
        {
            float rate = (time - (justTime - TARGET_DISP_TIME * 0.5f)) / TARGET_DISP_TIME;
            float sinRate = sinf(3.14f * rate);
//            AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
            for(int i = 0; i < 2; ++i) {
                float scale = 0;                
                if(i == 0)
                    scale = scaleBegin + (scaleEnd - scaleBegin) * rate;
                else scale = scaleEnd + (scaleBegin - scaleEnd) * rate;
                [targetSprites[i] setRotation:30 * i + 180 * sinRate];
                [targetSprites[i] setOpacity:255 * sinRate];
                [targetSprites[i] setScale:scale];
            }
        }
        else {
            for(int i = 0; i < 2; ++i) {
                [targetSprites[i] setOpacity:0];
            }
        }

        if(type == BT_Snipe) {
            if(fmod(time, 0.1f) < fmod(updateTime, 0.1f)) {
                CCSprite* sprite = [CCSprite spriteWithFile:@"rvBulletNormalWind.png"];
                [sprite setPosition: bulletSprites[0].position];
                [sprite setScale: bulletSprites[0].scale];
                [sprite setColor: bulletSprites[0].color];
                [sprite runAction: 
                    [CCSpawn actions:
                        [CCEaseOut actionWithAction:[CCScaleBy actionWithDuration:0.5f scale:2] rate: 3],
                        [CCEaseOut actionWithAction:[CCFadeOut actionWithDuration:0.5f] rate: 3],
                        nil
                    ]
                ];
                [parentLayer addChild: sprite];
                [effects addObject:sprite]; 
            }
        }
        if(time - justTime > TARGET_DISP_TIME * 0.5f) {
            state = BS_Damage;
        }
        break;

    case BS_Guard:
        if(time - guardTime < 1) {
            float rate = (time - guardTime) / 1;
            for(int i = 0; i < spriteNum; ++i)
                [bulletSprites[i] setOpacity: 1 - rate];
        }
        else {
            [self destroy];
        }
        break;

    case BS_Damage:
        [self destroy];
        return YES;
        break;
            
    default:
        break;
    }

    updateTime = time;
    return NO;
}

-(BOOL) touch:(CGPoint)touchPos_ {
    if(state == BS_Defence) {
        CGPoint vec = ccpSub(touchPos_, justPos);
        float j2u = updateTime - justTime;
        if(fabs(j2u) < (TARGET_DISP_TIME * 0.5f)
        && abs(vec.x) < 96 && abs(vec.y) < 96) 
        {
            NSLog(@"updateTime %f justTime %f", updateTime, justTime);
            for(int i = 0; i < 2; ++i) {
                [targetSprites[i] setColor:ccRED];
                [targetSprites[i] setOpacity:255];
            }
            guardTime = updateTime;
            state = BS_Guard;
            return YES;
        }
    }
    return NO;
}

-(void) destroy {
    for(int i = 0; i < 2; ++i) {
        if(targetSprites[i] != nil) {
            [parentLayer removeChild:targetSprites[i] cleanup:YES];
            targetSprites[i] = nil;
        }
        if(i < spriteNum) {
            if(bulletSprites[i] != nil) {
                [parentLayer removeChild:bulletSprites[i] cleanup:YES];
                bulletSprites[i] = nil;
            }
        }
    }
    for(CCSprite* sprite in effects) {
        [parentLayer removeChild:sprite cleanup:YES];
    }
    [effects removeAllObjects];
    state = BS_Max;
}

-(BOOL) isDestoyed {
    return (state == BS_Max);
}

@end
