//
//  PrintCell.h
//  Survey
//
//  Created by Tony Brame on 3/11/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

enum CELL_TYPES {
	CELL_LABEL = 1,
	CELL_TEXT,
	CELL_TEXT_LABEL,
	CELL_CHECKBOX,
	CELL_IMAGE
};

enum BORDERS
{
	BORDER_NONE = 0,
	BORDER_BOTTOM = 1,
	BORDER_LEFT = BORDER_BOTTOM << 1,
	BORDER_TOP = BORDER_BOTTOM << 2,
	BORDER_RIGHT = BORDER_BOTTOM << 3,
	BORDER_ALL = BORDER_BOTTOM | BORDER_LEFT | BORDER_TOP | BORDER_RIGHT
};

#define CELL_CHECKBOX_SIZE TO_PRINTER(8)
/* -- use UITexstAlignemtn
 
 enum TEXT_POSITION
{
	ALIGN_LEFT = 1,
	ALIGN_RIGHT,
	ALIGN_CENTER
};*/

@interface PrintCell : NSObject <NSCopying> {
	
	UIFont *font;
	
	int width;
	
	BOOL overrideHeight;
	int cellHeight;
	
	int cellType;
	
	NSString *cellName;
	/*NSString *cellHeader;
	NSString *cellValue;*/
	
	//underline value - underline the entire column for a value
	BOOL underlineValue;
	//only underline the value text (underlineValue must be true)
	BOOL underlineValueOnlyText;
	//underline the label text
	BOOL underlineLabel;
	BOOL strikethroughLabel;
	
	BOOL wordWrap;
	
	int borderType;
	
	int textPosition;
	
	//possible expansion support
	int padding;
	int borderWidth;
	int labelValSpacer;
	
	NSInteger resolution;
}

@property (nonatomic) NSInteger resolution;
@property (nonatomic) int width;
@property (nonatomic) BOOL overrideHeight;
@property (nonatomic) int cellHeight;
@property (nonatomic) int cellType;
@property (nonatomic) BOOL underlineValue;
@property (nonatomic) BOOL underlineValueOnlyText;
@property (nonatomic) BOOL underlineLabel;
@property (nonatomic) BOOL strikethroughLabel;
@property (nonatomic) BOOL wordWrap;
@property (nonatomic) int borderType;
@property (nonatomic) int textPosition;
@property (nonatomic) int padding;

@property (nonatomic, retain) UIFont *font;
//@property (nonatomic, retain) NSString *cellHeader;
@property (nonatomic, retain) NSString *cellName;
//@property (nonatomic, retain) NSString *cellValue;

-(id)initWithRes:(NSInteger)res;

-(void)drawCell:(CGContextRef)context withPosition:(CGPoint)position withLabel:(NSString*)lab withValue:(NSString*)val;

//-(int)height;
-(int)heightWithText:(NSString*)text;

-(NSDictionary*)getAttributesDictionary;
-(NSDictionary*)getAttributesDictionary:(NSTextAlignment)alignment;
-(NSTextAlignment)getNSTextAlignment;
-(int)heightWithText:(NSString*)text;
-(CGSize)getDrawnSize:(NSString*)text;
-(CGSize)getDrawnSize:(NSString*)text withAlign:(NSTextAlignment)alignment;

+ (void)staticContextSet:(CGContextRef)context;
+ (void)staticFontSet:(UIFont *)font;
+ (void)staticLineWidthSet:(CGFloat)lineWidth;

+ (void)drawTextCellLabel:(NSString *)labelText x:(CGFloat)x y:(CGFloat)y width:(int)theWidth font:(UIFont *)theFont border:(int)theBorder align:(UITextAlignment)theAlign;
+ (void)drawTextCellLabel:(NSString *)labelText x:(CGFloat)x y:(CGFloat)y width:(int)theWidth align:(UITextAlignment)theAlign;
+ (void)drawLine:(CGPoint)from to:(CGPoint)to;
+ (void)drawRectangle:(CGRect)rect;

@end
