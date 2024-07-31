//
//  FileTableView.h
//  larchiver
//
//  Created by Lasse Lauwerys on 30/03/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LDFileTableView.h"
#import "LDFileTableViewController.h"

@class LDFileTableView;

@interface LDFileTableViewDelegate : NSObject <NSTableViewDelegate, QLPreviewPanelDelegate>

@property IBOutlet NSSegmentedControl *tableControl;
@property IBOutlet LDFileTableView *tableView;

@property IBOutlet NSMenuItem *mainMenuDelete;

- (void)reloadControl;

@end
