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

-(id) initWithParamRecieve:(float)justTime_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_
{
    self = [super init];
    if (self != nil) {
        justTime = justTime_;
        justPos = justPos_;
        parentLayer = parentLayer_;

        CGSize winSize = [[CCDirector sharedDirector] winSize];
        for(int i = 0; i < 2; ++i) {
            if(i == 0)
                sprite[i] = [CCSprite spriteWithFile:@"rvBulletNormalBody.png"];
            else sprite[i] = [CCSprite spriteWithFile:@"rvBulletNormalWind.png"];
            [sprite[i] setScale:0];
            [sprite[i] setColor:ccRED];
            [sprite[i] setPosition:ccp(winSize.width/2, winSize.height/2 + 768 / 4)];
            [parentLayer addChild:sprite[i]];
        }

        AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
        float scale = (appCtrler.isRetina) ? 2:1;
        scaleBegin = scale * 0.75f;
        scaleEnd = scale * 1.25f;

        for(int i = 0; i < 2; ++i) {
            target[i] = [CCSprite spriteWithFile:@"rvShotNormal.png"];
            [target[i] setPosition:justPos];
            [target[i] setOpacity:0];
            [target[i] setColor:ccBLACK];
            [target[i] setRotation:30 * i];
            [parentLayer addChild:target[i]];
        }
        state = Recieve;
    }
    return self;    
}

-(id) initWithParamSend:(float)justTime_ touchPoint:(CGPoint)justPos_ iconLayer:(CCLayer*)parentLayer_
{
    self = [super init];
    if (self != nil) {
        justTime = justTime_;
        justPos = justPos_;
        parentLayer = parentLayer_;

        CGSize winSize = [[CCDirector sharedDirector] winSize];
        for(int i = 0; i < 2; ++i) {
            if(i == 0)
                sprite[i] = [CCSprite spriteWithFile:@"rvBulletNormalBody.png"];
            else sprite[i] = [CCSprite spriteWithFile:@"rvBulletNormalWind.png"];
            AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
            float scale = (appCtrler.isRetina) ? 2:1;
            [sprite[i] setFlipX:YES];
            [sprite[i] setScale:scale];
            [sprite[i] setColor:ccGREEN];
            [sprite[i] setPosition:justPos];
            [parentLayer addChild:sprite[i]];
        }
        state = Send;
    }
    return self;    
}

-(BOOL) update:(float)time {

    updateTime = time;
    CGSize winSize = [[CCDirector sharedDirector] winSize];

    switch(state) {
    case Send:
        for(int i = 0; i < 2; ++i) {
            CGPoint pos = ccp(winSize.width/2,winSize.height/2 + 768 / 4);
            float posRate = i == 1 ? time: time - 0.01666f * 3;
            posRate = 1 - sinf((3.14f/2)+(3.14f/2) * ((posRate - (justTime + 2)) / 2));
            posRate = posRate * posRate;
            pos.x += (justPos.x - pos.x) * posRate;
            pos.y += (justPos.y - pos.y) * posRate;

            AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
            float scale = (appCtrler.isRetina) ? 2:1;
            [sprite[i] setScale:scale * posRate];
            [sprite[i] setRotation:360 * 2 * posRate];
            [sprite[i] setPosition:pos];

            if(time - justTime > 2) {
                [self destroy];
            }
        }
        break;

    case Recieve:
        for(int i = 0; i < 2; ++i) {
            CGPoint pos = ccp(winSize.width/2,winSize.height/2 + 768 / 4);
            float posRate = i == 1 ? time: time - 0.01666f * 3;
            posRate = 1-sinf((3.14f/2)+(3.14f/2) * ((posRate - (justTime - 2)) / 2));
            posRate = posRate * posRate;
            pos.x += (justPos.x - pos.x) * posRate;
            pos.y += (justPos.y - pos.y) * posRate;

            AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
            float scale = (appCtrler.isRetina) ? 2:1;
            [sprite[i] setScale:scale * posRate];
            [sprite[i] setRotation:-360 * 2 * posRate];
            [sprite[i] setPosition:pos];
        }
        
        if(time > justTime - (TARGET_DISP_TIME * 0.5f) 
        && time < justTime + (TARGET_DISP_TIME * 0.5f)) 
        {
            float rate = (time - (justTime - TARGET_DISP_TIME * 0.5f)) / TARGET_DISP_TIME;
            float sinRate = sinf(3.14f * rate);
            AppController *appCtrler = (AppController*) [[UIApplication sharedApplication] delegate];
            for(int i = 0; i < 2; ++i) {
                float scale = 0;                
                if(i == 0)
                    scale = scaleBegin + (scaleEnd - scaleBegin) * rate;
                else scale = scaleEnd + (scaleBegin - scaleEnd) * rate;
                [target[i] setRotation:30 * i + 180 * sinRate];
                [target[i] setOpacity:255 * sinRate];
                [target[i] setScale:scale];
            }
        }
        else {
            for(int i = 0; i < 2; ++i) {
                [target[i] setOpacity:0];
            }
        }

        if(time - justTime > TARGET_DISP_TIME * 0.5f) {
            state = Damage;
        }
        break;

    case Guard:
        if(time - guardTime < 1) {
            float rate = (time - guardTime) / 1;
            for(int i = 0; i < 2; ++i)
                [sprite[i] setOpacity: 1 - rate];
        }
        else {
            [self destroy];
        }
        break;

    case Damage:
        [self destroy];
        return YES;
        break;        
    }
    return NO;
}

-(BOOL) touch:(CGPoint)touchPos_ {
    if(state == Recieve) {
        CGPoint vec = ccpSub(touchPos_, justPos);
        float j2u = updateTime - justTime;
        if(fabs(j2u) < (TARGET_DISP_TIME * 0.5f)
        && abs(vec.x) < 96 && abs(vec.y) < 96) 
        {
            NSLog(@"updateTime %f justTime %f", updateTime, justTime);
            for(int i = 0; i < 2; ++i) {
                [target[i] setColor:ccRED];
                [target[i] setOpacity:255];
            }
            guardTime = updateTime;
            state = Guard;
            return YES;
        }
    }
    return NO;
}

-(void) destroy {
    for(int i = 0; i < 2; ++i) {
        if(target[i] != nil) {
            [parentLayer removeChild:target[i] cleanup:YES];
            target[i] = nil;
        }
        if(sprite[i] != nil) {
            [parentLayer removeChild:sprite[i] cleanup:YES];
            sprite[i] = nil;
        }
    }
    state = Max;
}

-(BOOL) isDestoyed {
    return (state == Max);
}

@end
