//
//  HHAudioManager.m
//  HHBusiness
//
//  Created by Jey on 12-7-4.
//  Copyright (c) 2012年 Jey. All rights reserved.
//
//    http://www.apache.org/licenses/LICENSE-2.0

#import "HHAudioManager.h"

@interface HHAudioManager ()

@end

@implementation HHAudioManager 
@synthesize player = _player;
@synthesize observer = _observer;
@synthesize filePath = _filePath;

void interruptionListener(    void *    inClientData,
                          UInt32    inInterruptionState);
void propListener(    void *                  inClientData,
                  AudioSessionPropertyID    inID,
                  UInt32                  inDataSize,
                  const void *            inData);

SINGLETON_IMPLEMENTATION(HHAudioManager)

static bool runRecord = NO;
- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        _player = new AQPlayer();
        _observer = [[NSMutableSet alloc] init];
        
        OSStatus error = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
        if (error) printf("ERROR INITIALIZING AUDIO SESSION! %ld\n", error);
        else {
            UInt32 category = kAudioSessionCategory_PlayAndRecord;    
            error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
            if (error) printf("couldn't set audio category!");
            
            CFStringRef newRoute;
            UInt32 size;
            size = sizeof(CFStringRef);
            error = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
            if (error) printf("couldn't set audio category!");
            
            UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
            if ([@"HeadsetInOut" isEqual:(NSString *)newRoute]) {
                audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
            }
            error = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof (audioRouteOverride), &audioRouteOverride);
            if (error) printf("couldn't set audio speaker!");
            
            error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
            if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %ld\n", error);
            UInt32 inputAvailable = 0;
            size = sizeof(inputAvailable);
            
            // we do not want to allow recording if input is not available
            error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
            if (error) printf("ERROR GETTING INPUT AVAILABILITY! %ld\n", error);
            
            error = AudioSessionSetActive(true); 
            if (error) printf("AudioSessionSetActive (true) failed");
        }
        runRecord = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueStopped:) name:kPlaybackQueueStopped object:nil];
        _filePath = nil;
    }
    return self;
}

- (void)dealloc {
    AudioSessionSetActive(false);
    HHRELEASE(_observer);
    HHRELEASE(_filePath);
    delete _player;
    [super dealloc];
}

#pragma mark AudioSession listeners
void interruptionListener(    void *    inClientData,
                          UInt32    inInterruptionState)
{
    HHAudioManager *THIS = (HHAudioManager*)inClientData;
    if (inInterruptionState == kAudioSessionBeginInterruption) {
        if (THIS->_player->IsRunning()) {
            NSString *file = (NSString *)THIS->_player->GetFilePath();
            NSString *name = @"";
            if (file) {
                name = [[[file lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kPlaybackQueueStopped object:[[name copy] autorelease]];
        }
    }
}

void propListener(    void *                  inClientData,
                  AudioSessionPropertyID    inID,
                  UInt32                  inDataSize,
                  const void *            inData)
{
    HHAudioManager *THIS = (HHAudioManager *)inClientData;
    if (inID == kAudioSessionProperty_AudioRouteChange) {
        CFDictionaryRef routeDictionary = (CFDictionaryRef)inData;          
        //CFShow(routeDictionary);
        CFNumberRef reason = (CFNumberRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
        SInt32 reasonVal;
        CFNumberGetValue(reason, kCFNumberSInt32Type, &reasonVal);
        if (reasonVal != kAudioSessionRouteChangeReason_CategoryChange) {     
            CFStringRef newRoute;
            UInt32 size; size = sizeof(CFStringRef);
            AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
            if ([@"ReceiverAndMicrophone" isEqual:(NSString *)newRoute]) {
                UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker; 
                OSStatus error = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof (audioRouteOverride), &audioRouteOverride);
                if (error) printf("couldn't set audio speaker!");
                if (THIS->_player->IsRunning()) {
                    [THIS stopPlayQueue];
                }
            }
        }
    }
}


#pragma mark - Helper
- (void)playbackQueueStopped:(NSNotification *)note {
    for (id<HHAudioProtocol> o in _observer) {
        [o playbackQueueStopped:[note object] interruption:nil];
    }
}

- (NSString *)playingFileName {
    NSString *name = @"";
    if ([self isPlaying]) {
        NSString *file = (NSString *)_player->GetFilePath();
        if (file) {
            name = [[[file lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0];
        }
    }
    return name;
}

- (void)stopPlayQueue {
    _player->StopQueue();
}

- (void)playByPath:(NSString *)path {
    NSAssert(NO, @"还没有实现该方法...");
}

- (BOOL)isPlaying {
    return _player->IsRunning();
}

- (BOOL)play:(NSString *)fileName {
    if ([self isPlaying]) {
        [self stopPlayQueue];
    }
//    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    _player->DisposeQueue(true);
    NSString *file = nil;
    if (self.filePath != nil) {
        file = [self.filePath stringByAppendingPathComponent:fileName];
    } else {
        file = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    }
    bool v = _player->CreateQueueForFile((CFStringRef)file);
    if (v) {
        _player->StartQueue(false);
        if ([_observer count] > 0) {
            [NSTimer scheduledTimerWithTimeInterval:0.25
                                             target:self
                                           selector:@selector(playingTimer:)
                                           userInfo:nil
                                            repeats:YES];
        }
    }
    return v;
}

- (void)willResignActive:(NSNotification *)notification {
    AudioSessionSetActive(false);
    runRecord = NO;
}

- (void)didBecomeActive:(NSNotification *)notification {
    AudioSessionSetActive(true);
    runRecord = YES;
}

- (void)playingTimer:(NSTimer *)timer {
    if (![self isPlaying]) {
        [timer invalidate];
    }
    for (id<HHAudioProtocol> o in _observer) {
        if ([o respondsToSelector:@selector(playbackQueue:totalTimeInterval:currentTimeInterval:)]) {
            [o playbackQueue:[self playingFileName]
           totalTimeInterval:(_player->TotalDuration())
         currentTimeInterval:(_player->CurrentTime())];
        }
    }
}
@end
