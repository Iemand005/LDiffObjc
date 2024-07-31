//
//  FileTableView.h
//  larchiver
//
//  Created by Lasse Lauwerys on 1/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LDFileTableViewController.h"

@class LDFileTableViewController;

@interface LDFileTableView : NSTableView

@property (nonatomic, readonly) NSInteger selectedItemIndex;
@property (nonatomic, readonly) NSIndexSet *selectedItemIndexes;
@property IBOutlet LDFileTableViewController *controller;

- (BOOL)canMoveSelectionUp:(NSIndexSet*)indexes;
- (BOOL)canMoveSelectionDown:(NSIndexSet*)indexes;

-(NSIndexSet*)getSelectedItemIndexes;

@end
