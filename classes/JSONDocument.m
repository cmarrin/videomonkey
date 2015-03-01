//
//  JSONDocument.m
//  VideoMonkey
//
//  Created by Philippe Casgrain on 2013-11-03.
//
//

#import "JSONDocument.h"
#import "JSONKit.h"

@implementation JSONDocument

+ (NSDictionary *)JSONObjectWithData:(NSData *)data options:(JSONReadingOptions)readingOptions error:(NSError **)error
{
    if (NSClassFromString(@"NSJSONSerialization") && !(readingOptions & JSONUseOlderDecoder) )
    {
        // MacOSX 10.7 and up
        return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)readingOptions error:error];
    }

    // Use non-system decoder
    JSONDecoder *decoder = [JSONDecoder decoder];
    id document = nil;
    if (readingOptions == JSONReadingMutableContainers)
    {
        document = [decoder mutableObjectWithData:data error:error];
    }
    else
    {
        document = [decoder objectWithData:data error:error];
    }

    return document;
}
        
@end
