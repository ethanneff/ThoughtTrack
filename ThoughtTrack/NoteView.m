//
//  NoteView.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/15/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "NoteView.h"
#import "Config.h"

@interface NoteView()

@property (nonatomic) UIWebView *noteContentWebView;

@end

@implementation NoteView

#pragma mark - init
-(instancetype)init {
    self = [super init];
    if (self) {
        _view = [[UIView alloc] init];
        _noteContentWebView = [[UIWebView alloc] init];
    }
    return self;
}

-(instancetype)initWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    self = [super init];
    if (self) {
        [self createWithMenu:menu withController:controller];
    }
    return self;
}

+(instancetype)createWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    return [[self alloc] initWithMenu:menu withController:controller];
}

#pragma mark - helper methods
-(UIView *)createWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].frameWidth, [Config sharedInstance].frameHeight-(menu.frame.size.height))];
    [self.view setBackgroundColor:[Config sharedInstance].colorSelected];
    
    UITextField *txtTitle = [[UITextField alloc] initWithFrame:CGRectMake(0, [Config sharedInstance].statusBarHeight, [Config sharedInstance].frameWidth, [Config sharedInstance].rowHeight)];
    [txtTitle setFont:[UIFont boldSystemFontOfSize:18.0]];
    [txtTitle setTag:91];
    [txtTitle setBackgroundColor:[Config sharedInstance].colorSelected];
    [txtTitle setTextColor:[Config sharedInstance].colorBackground];
    [txtTitle setTintColor:[Config sharedInstance].colorBackground];
    txtTitle.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Note Title..." attributes:@{NSForegroundColorAttributeName:[Config sharedInstance].colorOutline}];
    txtTitle.delegate = (id)controller;
    txtTitle.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:txtTitle];
    
    UIView *titleSpacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    [txtTitle setLeftViewMode:UITextFieldViewModeAlways];
    [txtTitle setLeftView:titleSpacer];
    
    UIView *viewSeparatorBackground = [[UIView alloc] initWithFrame:CGRectMake(0, txtTitle.frame.origin.y+txtTitle.frame.size.height, [Config sharedInstance].frameWidth, [Config sharedInstance].rowHorizontalBorderHeight)];
    [viewSeparatorBackground setBackgroundColor:[Config sharedInstance].colorSelected];
    [self.view addSubview:viewSeparatorBackground];
    
    UIView *viewSeparator = [[UIView alloc] initWithFrame:CGRectMake(([Config sharedInstance].frameWidth-[Config sharedInstance].rowHorizontalBorderWidth)/2, txtTitle.frame.origin.y+txtTitle.frame.size.height, [Config sharedInstance].rowHorizontalBorderWidth, [Config sharedInstance].rowHorizontalBorderHeight)];
    [viewSeparator setBackgroundColor:[Config sharedInstance].colorBackground];
    [self.view addSubview:viewSeparator];
    
    UIWebView *webViewContent = [[UIWebView alloc] initWithFrame:CGRectMake(0, viewSeparator.frame.origin.y+viewSeparator.frame.size.height, [Config sharedInstance].frameWidth,250)];
    webViewContent.tag = 92;
    webViewContent.delegate = (id)controller;
    self.noteContentWebView = webViewContent;
    [self.view addSubview:webViewContent];
    
    return self.view;
}

-(NSString *) getNoteContent {
    NSString *htmlInner = [self.noteContentWebView stringByEvaluatingJavaScriptFromString:@"CKEDITOR.instances.editor1.getData()"];
    if (htmlInner.length > 0) {
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&#39" withString:@"\'"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&iexcl;" withString:@"¡"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&cent;" withString:@"¢"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&pound;" withString:@"£"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&curren;" withString:@"¤"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&yen;" withString:@"¥"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&brvbar;" withString:@"¦"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&sect;" withString:@"§"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&uml;" withString:@"¨"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&copy;" withString:@"©"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ordf;" withString:@"ª"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&laquo;" withString:@"«"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&not;" withString:@"¬"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&reg;" withString:@"®"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&macr;" withString:@"¯"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&deg;" withString:@"°"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&plusmn;" withString:@"±"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&sup2;" withString:@"²"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&sup3;" withString:@"³"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&acute;" withString:@"´"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&micro;" withString:@"µ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&para;" withString:@"¶"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&middot;" withString:@"·"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&cedil;" withString:@"¸"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&sup1;" withString:@"¹"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ordm;" withString:@"º"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&raquo;" withString:@"»"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&frac14;" withString:@"¼"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&frac12;" withString:@"½"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&frac34;" withString:@"¾"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&iquest;" withString:@"¿"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Agrave;" withString:@"À"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Aacute;" withString:@"Á"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Acirc;" withString:@"Â"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Atilde;" withString:@"Ã"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Auml;" withString:@"Ä"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Aring;" withString:@"Å"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&AElig;" withString:@"Æ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Ccedil;" withString:@"Ç"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Egrave;" withString:@"È"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Eacute;" withString:@"É"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Euml;" withString:@"Ë"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Igrave;" withString:@"Ì"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Iacute;" withString:@"Í"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Icirc;" withString:@"Î"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Iuml;" withString:@"Ï"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ETH;" withString:@"Ð"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Ntilde;" withString:@"Ñ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Ograve;" withString:@"Ò"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Oacute;" withString:@"Ó"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Ocirc;" withString:@"Ô"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Otilde;" withString:@"Õ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Ouml;" withString:@"Ö"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&times;" withString:@"×"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Oslash;" withString:@"Ø"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Ugrave;" withString:@"Ù"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Uacute;" withString:@"Ú"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Ucirc;" withString:@"Û"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Uuml;" withString:@"Ü"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Yacute;" withString:@"Ý"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&THORN;" withString:@"Þ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&szlig;" withString:@"ß"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&agrave;" withString:@"à"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&aacute;" withString:@"á"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&acirc;" withString:@"â"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&atilde;" withString:@"ã"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&auml;" withString:@"ä"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&aring;" withString:@"å"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&aelig;" withString:@"æ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ccedil;" withString:@"ç"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&egrave;" withString:@"è"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&eacute;" withString:@"é"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ecirc;" withString:@"ê"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&euml;" withString:@"ë"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&igrave;" withString:@"ì"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&iacute;" withString:@"í"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&icirc;" withString:@"î"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&iuml;" withString:@"ï"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&eth;" withString:@"ð"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ntilde;" withString:@"ñ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ograve;" withString:@"ò"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&oacute;" withString:@"ó"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ocirc;" withString:@"ô"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&otilde;" withString:@"õ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ouml;" withString:@"ö"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&divide;" withString:@"÷"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&oslash;" withString:@"ø"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ugrave;" withString:@"ù"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&uacute;" withString:@"ú"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ucirc;" withString:@"û"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&uuml;" withString:@"ü"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&yacute;" withString:@"ý"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&thorn;" withString:@"þ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&yuml;" withString:@"ÿ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&OElig;" withString:@"Œ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&oelig;" withString:@"œ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Scaron;" withString:@"Š"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&scaron;" withString:@"š"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Yuml;" withString:@"Ÿ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&fnof;" withString:@"ƒ"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ndash;" withString:@"–"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&mdash;" withString:@"—"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&lsquo;" withString:@"‘"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&rsquo;" withString:@"’"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&sbquo;" withString:@"‚"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&ldquo;" withString:@"“"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&rdquo;" withString:@"”"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&bdquo;" withString:@"„"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&dagger;" withString:@"†"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&Dagger;" withString:@"‡"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&bull;" withString:@"•"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&hellip;" withString:@"…"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&permil;" withString:@"‰"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&euro;" withString:@"€"];
        htmlInner = [htmlInner stringByReplacingOccurrencesOfString:@"&trade;" withString:@"™"];
    }
    
    NSString *noteContent = [NSString string];
    @try {
        NSRange beginContent = [htmlInner rangeOfString:@"<en-note"];
        NSRange endContent = [htmlInner rangeOfString:@"</en-note"];
        htmlInner = [[htmlInner substringWithRange:NSMakeRange(beginContent.location, endContent.location - beginContent.location)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                                 "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                                 "%@"
                                 "</en-note>"
                                 , htmlInner];
    }
    @catch (NSException *exception) {
        noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                       "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                       "<en-note>"
                       "%@"
                       "</en-note>", htmlInner];
    }

    return noteContent;
}



@end
