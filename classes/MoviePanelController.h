//
//  MoviePanelController.h
//  VideoMonkey
//
//  Created by Chris Marrin on 11/12/08.
//  Copyright 2008 Chris Marrin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTMovieView.h>


@interface MoviePanelController : NSObject {
@private
    IBOutlet QTMovieView* m_movieView;
}

@end
