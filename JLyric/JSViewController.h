//
//  JSViewController.h
//  JLyric
//
//  Created by Jey on 8/8/12.
//  Copyright (c) 2012 Jey. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "JSLrcParser.h"

@interface JSViewController : UIViewController {
    NSMutableArray __strong *_lrcKeys;
    JSLrc __strong *_lrc;
}

@property (strong, nonatomic) IBOutlet UILabel *selectedLabel;
@property (strong, nonatomic) IBOutlet UIScrollView *backScrollView;
@property (strong, nonatomic) IBOutlet UILabel *lrcLabel;
@end
