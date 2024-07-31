//
//  FileTableView.m
//  larchiver
//
//  Created by Lasse Lauwerys on 1/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDFileTableView.h"
#import "LDFileTableViewController.h"

@implementation LDFileTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
    SEL action = [anItem action];
    NSIndexSet* selectedItems = [self getSelectedItemIndexes];
    if ([anItem action] == @selector(moveUp:)) return [self canMoveSelectionUp:selectedItems];
    else if (action == @selector(moveDown:)) return [self canMoveSelectionDown:selectedItems];
    else if (action == @selector(delete:)) return selectedItems.count > 0;
    return [super validateUserInterfaceItem:anItem];
}

- (BOOL)canMoveSelectionUp:(NSIndexSet*)indexes
{
    NSUInteger firstIndex = indexes.firstIndex;
    return firstIndex > 0 && firstIndex != NSNotFound;
}

- (BOOL)canMoveSelectionDown:(NSIndexSet*)indexes
{
    NSUInteger lastIndex = indexes.lastIndex;
    return lastIndex < [self controller].layerFiles.count - 1 && lastIndex != NSNotFound;
}

- (BOOL)canDeleteSelection:(NSIndexSet*)indexes
{
    return indexes.count > 0;
}

- (BOOL)containsClickedRow
{
    return self.clickedRow > 0 && self.clickedRow < [self controller].layerFiles.count;
}

- (void)keyDown:(NSEvent *)theEvent
{
    if ([theEvent keyCode] == 49) [self.controller showQuickLook];
    if (!!([theEvent modifierFlags] & NSCommandKeyMask)) return;
    else [super keyDown:theEvent];
}

- (NSIndexSet*)getSelectedItemIndexes
{
    NSIndexSet *indexes = self.selectedRowIndexes;
    NSUInteger layerCount = [self controller].layerFiles.count;
    if (self.clickedRow != -1 && ![self.selectedRowIndexes containsIndex:self.clickedRow]) indexes = [NSIndexSet indexSetWithIndex:self.clickedRow];
    return [indexes indexesPassingTest:^BOOL(NSUInteger index, BOOL *stop){
        return index < layerCount;
    }];
}

- (NSUInteger)getSelectedItemIndex
{
    return self.clickedRow == NSNotFound ? self.selectedRow : self.clickedRow;
}

- (void)moveUp:(id)sender
{
    [self.controller moveSelectedItemsUp:sender];
}

- (void)moveDown:(id)sender
{
    [self.controller moveSelectedItemsDown:sender];
}

- (void)delete:(id)sender
{
    [self.controller deleteSelectedItems:sender];
}

@end
