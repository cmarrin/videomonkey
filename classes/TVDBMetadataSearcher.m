//
//  TVDBMetadataSearcher.m
//  VideoMonkey
//
//  Created by Chris Marrin on 4/13/09.
//  Copyright 2009 Apple. All rights reserved.
//

#import "TVDBMetadataSearcher.h"
#import "XMLDocument.h"

@implementation TVDBMetadataSearcher

-(BOOL) searchForShow:(NSString*) searchString
{
    [m_foundShowNames release];
    m_foundShowNames = nil;
    [m_foundShowIds release];
    m_foundShowIds = nil;
    [m_foundSeasons release];
    m_foundSeasons = nil;
    [m_foundEpisodes release];
    m_foundEpisodes = nil;

    NSString* urlString = [NSString stringWithFormat:@"http://www.thetvdb.com/api/GetSeries.php?seriesname=%@", searchString];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSURL* url = [NSURL URLWithString:urlString];
    MyXMLDocument* doc = [MyXMLDocument xmlDocumentWithContentsOfURL:url];
    
    if (![[[doc rootElement] name] isEqualToString:@"Data"])
        return NO;
        
    NSArray* series = [[doc rootElement] elementsForName:@"Series"];
    if ([series count] == 0)
        return NO;
        
    m_foundShowNames = [[NSMutableArray alloc] init];
    m_foundShowIds = [[NSMutableArray alloc] init];

    for (MyXMLElement* element in series) {
        NSString* name = [[element lastElementForName:@"SeriesName"] content];
        NSString* seriesidString = [[element lastElementForName:@"seriesid"] content];
        int seriesid = (seriesidString && [seriesidString length] > 0) ? [seriesidString intValue] : -1;
        if (name && [name length] > 0 && seriesid >= 0) {
            [m_foundShowNames addObject:name];
            [m_foundShowIds addObject:[NSNumber numberWithInt:seriesid]];
        }
    }
    
    if ([m_foundShowNames count] == 0) {
        [m_foundShowNames release];
        m_foundShowNames = nil;
        [m_foundShowIds release];
        m_foundShowIds = nil;
        return NO;
    }
    
    return YES;
}

@end
