//
//  HHAudioManager.h
//  HHBusiness
//
//  Created by Jey on 12-7-4.
//  Copyright (c) 2012年 Jey. All rights reserved.
//
//    http://www.apache.org/licenses/LICENSE-2.0

#import <Foundation/Foundation.h>
#import "AQPlayer.h"

@interface HHAudioManager : NSObject {
    AQPlayer *_player;
    NSMutableSet *_observer;
}

SINGLETON_INTERFACE(HHAudioManager)

@property (readonly) AQPlayer *player;
@property (readonly) NSMutableSet *observer;
@property (nonatomic, retain) NSString *filePath;

- (NSString *)playingFileName;
- (BOOL)isPlaying;
- (void)stopPlayQueue;
- (BOOL)play:(NSString *)fileName;
- (void)playByPath:(NSString *)path;

@end

@protocol HHAudioProtocol <NSObject>
- (void)playbackQueueStopped:(NSString *)fileName interruption:(NSObject *)reason;// 停止的原因. 正常播放完毕为nil
- (void)playbackQueue:(NSString *)fileName totalTimeInterval:(NSTimeInterval)total currentTimeInterval:(NSTimeInterval)timeInterval;
@end
