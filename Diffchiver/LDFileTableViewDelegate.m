//
//  FileTableView.m
//  larchiver
//
//  Created by Lasse Lauwerys on 30/03/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDFileTableViewDelegate.h"


@implementation LDFileTableViewDelegate

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    [self reloadControl];
//    [tableView makeViewWithIdentifier:<#(NSString *)#> owner:<#(id)#>]
    return [tableView.dataSource tableView:tableView objectValueForTableColumn:tableColumn row:row];
//    LDFile *file = [tableView.dataSource tableView:tableView objectValueForTableColumn:tableColumn row:row];
//    NSTextFieldCell *cell = [[NSTextFieldCell alloc] init];
//    [cell setStringValue:@"freet"];
//    return cell;
    
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self reloadControl];
}

/* Reload the segmented control and disable the buttons if the actions can't be performed. */
- (void)reloadControl
{
    NSIndexSet *selectedItems = self.tableView.selectedRowIndexes;
    Boolean enabled = selectedItems.count != 0;
    LDFileTableView *tableView = (id)self.tableView;
    [self.mainMenuDelete setEnabled:enabled];
    [self.tableControl setEnabled: enabled forSegment:1];
    [self.tableControl setEnabled:[tableView canMoveSelectionUp:selectedItems] forSegment:2];
    [self.tableControl setEnabled:[tableView canMoveSelectionDown:selectedItems] forSegment:3];
    [self.tableControl setEnabled: enabled forSegment:4];
    [self.tableControl setEnabled: enabled forSegment:5];
}

- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id<QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    return [(LDFile*)item imageWithSize:contentRect->size asIcon:YES];
}

- (LDFileTableViewController*)controller
{
    return (id)self.tableView.dataSource;
}

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id<QLPreviewItem>)item
{
    NSUInteger row = [[self controller].layerFiles indexOfObject:item];
    if (row != NSNotFound) {
        NSTableCellView *cellView = [[self tableView] viewAtColumn:0 row:row makeIfNecessary:NO];
        return [self.tableView.window convertRectToScreen: [cellView convertRectToBase:cellView.imageView.frame]];
    }
    return NSZeroRect;
}

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    if ([event type] == NSKeyDown)
    {
        [self.tableView keyDown:event];
        [[QLPreviewPanel sharedPreviewPanel] reloadData];
        return YES;
    }
    return NO;
}

@end
