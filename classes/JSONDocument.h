//
//  JSONDocument.h
//  A thin wrapper around NSJSONSerialization
//  VideoMonkey
//
//  Created by Philippe Casgrain on 2013-11-03.
//
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, JSONReadingOptions) {
    JSONReadingMutableContainers = NSJSONReadingMutableContainers,
    JSONReadingMutableLeaves = NSJSONReadingMutableLeaves,
    JSONReadingAllowFragments = NSJSONReadingAllowFragments,
    JSONUseOlderDecoder = (1UL << 7)
};

@interface JSONDocument : NSObject

+ (id)JSONObjectWithData:(NSData *)data options:(JSONReadingOptions)readingOptions error:(NSError **)error;

@end
