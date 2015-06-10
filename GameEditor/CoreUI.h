#import <Cocoa/Cocoa.h>

@interface CUICommonAssetStorage : NSObject
- (CUICommonAssetStorage *)initWithPath:(NSString *)path;
- (NSArray *)allRenditionNames;
- (BOOL)assetExistsForKey:(id)key;
@end

@interface CUIStructuredThemeStore : NSObject
- (CUICommonAssetStorage *)themeStore;
@end

@interface CUICatalog : NSObject
- (id)initWithName:(NSString *)carFileName fromBundle:(id)bundle;
- (id)imageWithName:(NSString *)name scaleFactor:(double)factor deviceIdiom:(NSInteger)idiom deviceSubtype:(NSUInteger)subtype;
- (id)imageWithName:(NSString *)name scaleFactor:(double)factor deviceIdiom:(NSInteger)idiom;
- (id)_themeStore;
@end

@interface CUINamedImage : NSObject
@property(copy, nonatomic) NSString *name;
@property(readonly, nonatomic) NSSize size;
@property(readonly, nonatomic) CGImageRef image;
@end
