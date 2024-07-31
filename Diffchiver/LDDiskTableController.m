//
//  LDDiskTableController.m
//  Diffchiver
//
//  Created by Lasse Lauwerys on 21/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDDiskTableController.h"

@implementation LDDiskTableController

- (id)init
{
    self = [super init];
    if (self) {
        disks = [NSMutableArray array];
    }
    return self;
}

- (void)addDisk:(NSString *)path
{
    [disks addObject:path];
//    [self ]
}

- (NSString *)getSelectedDisk
{
    return [disks objectAtIndex:[[self diskTable] selectedRow]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [disks count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [disks objectAtIndex:row];
}

@end
