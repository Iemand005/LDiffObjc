//
//  LDDiskTableController.h
//  Diffchiver
//
//  Created by Lasse Lauwerys on 21/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LDDiskTableController : NSObject <NSTableViewDataSource>
{
    NSMutableArray *disks;
}

@property IBOutlet NSTableView *diskTable;

- (void)addDisk:(NSString *)path;
- (NSString *)getSelectedDisk;

@end
