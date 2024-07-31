//
//  DiffchiverTests.h
//  DiffchiverTests
//
//  Created by Lasse Lauwerys on 10/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "LDDiffTool.h"
#import "LDUndiffTool.h"

@interface DiffchiverTests : SenTestCase
{
    LDDiffTool *diffTool;
    LDUndiffTool *undiffTool;
}

@end
