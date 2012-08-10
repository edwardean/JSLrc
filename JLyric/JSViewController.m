//
//  JSViewController.m
//  JLyric
//
//  Created by Jey on 8/8/12.
//  Copyright (c) 2012 Jey. All rights reserved.
//

#import "JSViewController.h"
#import "HHAudioManager.h"


@interface JSViewController () {
    CGRect currentRect;
    NSUInteger index;
}

@end

@implementation JSViewController
@synthesize selectedLabel;
@synthesize backScrollView;
@synthesize lrcLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *lrcPath = [[NSBundle mainBundle] pathForResource:@"01.lrc" ofType:nil];
    _lrc = [JSLrcParser lrcValue:lrcPath];
    NSMutableString *s = [NSMutableString string];
    for (id key in [self lrcKeys]) {
        [s appendString:[_lrc.lyric objectForKey:key]];
        [s appendString:@"\n"];
    }
    CGSize size = [s sizeWithFont:self.lrcLabel.font
                constrainedToSize:(CGSize){self.lrcLabel.frame.size.width, NSIntegerMax}
                    lineBreakMode:self.lrcLabel.lineBreakMode];
    self.backScrollView.contentSize = (CGSize){size.width, size.height+460};
    UIEdgeInsets insets = (UIEdgeInsets){230, 0, 230, 0};
    self.backScrollView.scrollIndicatorInsets = insets;
    CGRect rect = (CGRect){{insets.left, insets.top}, {320, size.height}};
    self.lrcLabel.frame = rect;
    self.lrcLabel.text = s;
    [self.lrcLabel addSubview:self.selectedLabel];
    self.selectedLabel.frame = (CGRect){{0, 0}, {320, lrcLabel.font.lineHeight}};
    [[HHAudioManager shared].observer addObject:self];
    index = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[HHAudioManager shared] play:@"01.mp3"];
}

- (void)viewDidUnload
{
    [[HHAudioManager shared].observer removeObject:self];
    [self setLrcLabel:nil];
    [self setBackScrollView:nil];
    [self setSelectedLabel:nil];
    [super viewDidUnload];
}

- (void)dealloc {
    [[HHAudioManager shared].observer removeObject:self];
}

#pragma mark - 
- (void)refreshView {
    id key = [_lrcKeys objectAtIndex:index];
    CGPoint point = self.backScrollView.contentOffset;
    NSString __autoreleasing *s = [_lrc.lyric objectForKey:key];
    CGSize size = [s sizeWithFont:self.lrcLabel.font
                constrainedToSize:(CGSize){self.lrcLabel.frame.size.width, NSIntegerMax}
                    lineBreakMode:self.lrcLabel.lineBreakMode];
    self.selectedLabel.text = nil;
    __block int i = index;
    [UIView animateWithDuration:0.25
                     animations:^{
        self.backScrollView.contentOffset = (CGPoint){0, point.y+size.height};
    } completion:^(BOOL finished) {
        CGRect r = self.selectedLabel.frame;
        self.selectedLabel.frame = (CGRect){{0, i*self.selectedLabel.font.lineHeight}, r.size};
        self.selectedLabel.text = s;
    }];
    index ++;
}

- (void)playbackQueue:(NSString *)fileName totalTimeInterval:(NSTimeInterval)total currentTimeInterval:(NSTimeInterval)timeInterval {
    HHDINFO(@"%lf, %lf", timeInterval, total);
    if (_lrcKeys && [_lrcKeys count] > index) {
        if ([[_lrcKeys objectAtIndex:index] doubleValue] <= timeInterval) {
            [self refreshView];
        }
    }
}

- (void)playbackQueueStopped:(NSString *)fileName interruption:(NSObject *)reason {
    
}

- (NSMutableArray *)lrcKeys {
    if (_lrcKeys==nil) {
        _lrcKeys = [NSMutableArray array];
    }
    if ([_lrcKeys count]<1) {
        NSArray __autoreleasing *ks = [_lrc.lyricKey sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 floatValue]>[obj2 floatValue];
        }];
        if (ks) [_lrcKeys addObjectsFromArray:ks];
    }
    return _lrcKeys;
}

@end
