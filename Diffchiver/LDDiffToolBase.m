//
//  LDDiffToolBase.m
//  Diffchiver
//
//  Created by Lasse Lauwerys on 19/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDDiffToolBase.h"

@implementation LDDiffToolBase

- (id)init
{
    self = [super init];
    if (self) {
        self.stringEncoding = NSUnicodeStringEncoding;
        self.indexingMethod = LDIndexingMethodOffsetsAndLengths;
        bufferSize = 50000000;
        layerFiles = [NSMutableArray array];
        outputFiles = [NSMutableArray array];
        calculateChecksum = YES;
    }
    return self;
}

- (BOOL)calculateChecksum
{
    return calculateChecksum;
}

- (UInt8)offsetDataSize
{
    const UInt8 offsetDataSizes[3] = { 16, 12, 8 };
    return offsetDataSizes[[self indexingMethod] - 1];
}

- (void)setCalculateChecksum:(BOOL)calculate
{
    calculateChecksum = calculate;
}

- (UInt64)currentOffset
{
    return layer * bufferSize + offset;
}

- (UInt64)maxOffset
{
    UInt64 totalLayerSize = 0;
    if (layerFileSizes)
        for (int i = 0; i < layerCount; ++i)
            totalLayerSize += layerFileSizes[i];
    return (totalLayerSize);
}

- (void)addLayerFile:(LDFile*)layerFile withOutputFile:(LDFile*)outputFile
{
    if (layerFile && outputFile) {
        [layerFiles addObject:layerFile];
        [outputFiles addObject:outputFile];
    }
}

@end
