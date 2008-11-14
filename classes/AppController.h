//
//  AppController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
@private
	IBOutlet NSMutableArray *m_files;
    IBOutlet NSArrayController *m_arrayController;
}

@end
