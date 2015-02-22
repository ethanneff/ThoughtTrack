//
//  NavigationView.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/12/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "MenuView.h"
#import "Config.h"
#import "HorizontalScrollView.h"
#import "Util.h"

@implementation MenuView

#pragma mark - init
-(instancetype)init {
    self = [super init];
    if (self) {
        [self createContainer];
    }
    return self;
}

+(instancetype)createContainer {
    return [[self alloc] init];
}

#pragma mark - create
-(UIView *)createContainer {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, [Config sharedInstance].frameHeight, [Config sharedInstance].frameHeight, 0)];
    self.view.backgroundColor = [Config sharedInstance].colorSelected;
    self.view.tag = 100;
    
    return self.view;
}

-(void)insertRowWithSize:(NSInteger)size withSeparator:(BOOL)separator {
    float rowHeight = [Config sharedInstance].rowHeight;
    if (size > 1) {
        rowHeight = [Config sharedInstance].rowHeight*size-[Config sharedInstance].rowTagPadding*(size-1);
    }
    
    // top down starting at 1
    self.numOfRows++;
    HorizontalScrollView *row = [[HorizontalScrollView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, [Config sharedInstance].frameWidth, rowHeight)];
    row.backgroundColor = [Config sharedInstance].colorBackground;
    row.tag = self.numOfRows;
    
    [self.view addSubview:row];
    
    if (separator) {
        UIView *rowBottomLineBackground = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height+row.frame.size.height, [Config sharedInstance].rowWidth, [Config sharedInstance].rowHorizontalBorderHeight)];
        rowBottomLineBackground.backgroundColor = [Config sharedInstance].colorBackground;
        [self.view addSubview:rowBottomLineBackground];
        
        UIView *rowBottomLine =  [[UIView alloc] initWithFrame:CGRectMake(([Config sharedInstance].frameWidth-[Config sharedInstance].rowHorizontalBorderWidth)/2, self.view.frame.size.height+row.frame.size.height, [Config sharedInstance].rowHorizontalBorderWidth, [Config sharedInstance].rowHorizontalBorderHeight)];
        rowBottomLine.backgroundColor = [Config sharedInstance].colorOutline;
        [self.view addSubview:rowBottomLine];
    }
    float sizeIncrease = (separator) ? row.frame.size.height + [Config sharedInstance].rowHorizontalBorderHeight : row.frame.size.height;
    
    // resize container
    CGRect frame = self.view.frame;
    frame.size.height += sizeIncrease;
    frame.origin.y -= sizeIncrease;
    self.view.frame = frame;
    [self addShadow];
}

#pragma mark - fill
-(void)updateRow:(NSInteger)row withFilters:(NSArray *)filters withSelectionType:(SelectionType)type withController:(UIViewController *)controller {
    // row
    HorizontalScrollView *scrollView = (HorizontalScrollView *)[self.view viewWithTag:row];
    [self removeSubviews:scrollView];
    
    NSInteger height = scrollView.frame.size.height / ([Config sharedInstance].rowHeight - [Config sharedInstance].rowTagPadding);
    
    // filter buttons
    float maxTotalWidthOfFilters = 0;
    for (NSInteger i = 0; i < height; i++) {
        float totalWidthOfFilters = 0;
        for (NSInteger j = i; j < filters.count; j += height) {
            // size buttons based on text size
            NSString *filterName = [filters[j] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            CGSize textSize = [filterName sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:[Config sharedInstance].rowTagTextSize]}];
            
            // create button
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(totalWidthOfFilters+[Config sharedInstance].rowTagPadding, [Config sharedInstance].rowHeight*i - [Config sharedInstance].rowTagPadding*(i-1), textSize.width+[Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight-[Config sharedInstance].rowTagPadding*2)];
            if (type == 0) {
                [button setTag:51];
            } else if (type == 1) {
                [button setTag:52];
            } else if (type == 2) {
                [button setTag:53];
            }
            [button setTitle:filterName forState:UIControlStateNormal];
            [button setTitleColor:[Config sharedInstance].colorNormal forState:UIControlStateNormal];
            [button setTitleColor:[Config sharedInstance].colorSelected forState:UIControlStateSelected];
            [button setTitleColor:[Config sharedInstance].colorSelected forState:UIControlStateHighlighted];
            button.layer.borderColor = [[Config sharedInstance].colorOutline CGColor];
            button.layer.borderWidth = [Config sharedInstance].rowTagBorderWidth;
            button.layer.cornerRadius = [Config sharedInstance].rowTagBorderRadius;
            [button addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
            [scrollView addSubview:button];
            
            totalWidthOfFilters += button.frame.size.width+[Config sharedInstance].rowTagPadding;
        }
        maxTotalWidthOfFilters = (totalWidthOfFilters > maxTotalWidthOfFilters) ? totalWidthOfFilters : maxTotalWidthOfFilters;
    }
    
    scrollView.contentSize = CGSizeMake(maxTotalWidthOfFilters +[Config sharedInstance].rowTagPadding, [Config sharedInstance].rowHeight);
    
    [self.view addSubview:scrollView];
}

-(void)updateRow:(NSInteger)row withNavigation:(UIViewController *)controller {
    // container
    HorizontalScrollView *scrollView = (HorizontalScrollView *)[self.view viewWithTag:row];
    [self removeSubviews:scrollView];
    
    // left image icon (settings)
    UIButton *buttonLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    [buttonLeft setTag:21];
    [buttonLeft addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonLeft setTitle:[Config sharedInstance].navigationTitles[0] forState:UIControlStateNormal];
    [buttonLeft setImage:[[UIImage imageNamed:@"settingsNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonLeft setTintColor:[Config sharedInstance].colorNormal];
    buttonLeft.imageEdgeInsets = UIEdgeInsetsMake(1, 0, -1, 0);
    [buttonLeft setImage:[UIImage imageNamed:@"settingsClicked"] forState:UIControlStateSelected];
    [buttonLeft setImage:[UIImage imageNamed:@"settingsClicked"] forState:UIControlStateHighlighted];
    [scrollView addSubview:buttonLeft];
    
    // middle text icons
    float widthOfButton = (([Config sharedInstance].rowWidth - 2*([Config sharedInstance].rowHeight) - 4*[Config sharedInstance].rowVerticalBorderWidth) / ([Config sharedInstance].navigationTitles.count-2));
    for (int i = 1; i < [Config sharedInstance].navigationTitles.count-1; i++) {
        if ([Config sharedInstance].rowVerticalBorder) { // initial
            UIView *verticalBar = [[UIView alloc] initWithFrame:CGRectMake([Config sharedInstance].rowHeight+([Config sharedInstance].rowVerticalBorderWidth+widthOfButton)*(i-1), ([Config sharedInstance].rowHeight - [Config sharedInstance].rowVerticalBorderHeight)/2, [Config sharedInstance].rowVerticalBorderWidth, [Config sharedInstance].rowVerticalBorderHeight)];
            [verticalBar setTag:21 + i];
            verticalBar.backgroundColor = [Config sharedInstance].colorOutline;
            [scrollView addSubview:verticalBar];
            if (i == [Config sharedInstance].navigationTitles.count-2) { // ending
                UIView *verticalBar = [[UIView alloc] initWithFrame:CGRectMake([Config sharedInstance].rowHeight+([Config sharedInstance].rowVerticalBorderWidth+widthOfButton)*i,([Config sharedInstance].rowHeight - [Config sharedInstance].rowVerticalBorderHeight)/2, [Config sharedInstance].rowVerticalBorderWidth, [Config sharedInstance].rowVerticalBorderHeight)];
                [verticalBar setTag:11];
                verticalBar.backgroundColor = [Config sharedInstance].colorOutline;
                [scrollView addSubview:verticalBar];
            }
        }
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake([Config sharedInstance].rowHeight+[Config sharedInstance].rowVerticalBorderWidth*i+widthOfButton*(i-1), 0, widthOfButton, [Config sharedInstance].rowHeight)];
        [button setTag:21 + i];
        [button setTitle:[NSString stringWithFormat:@"%@", [[Config sharedInstance].navigationTitles objectAtIndex:i]] forState: UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:[Config sharedInstance].rowTextSize];
        [button setTitleColor:[Config sharedInstance].colorNormal forState:UIControlStateNormal];
        [button setTitleColor:[Config sharedInstance].colorSelected forState:UIControlStateSelected];
        [button setTitleColor:[Config sharedInstance].colorSelected forState:UIControlStateHighlighted];
        [button addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
        [scrollView addSubview:button];
    }
    
    // right image icon
    UIButton *buttonRight = [[UIButton alloc] initWithFrame:CGRectMake([Config sharedInstance].rowWidth-[Config sharedInstance].rowHeight, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    [buttonRight setTag:21 + [Config sharedInstance].navigationTitles.count - 1];
    [buttonRight addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonRight setTitle:[Config sharedInstance].navigationTitles[[Config sharedInstance].navigationTitles.count-1] forState:UIControlStateNormal];
    [buttonRight setImage:[[UIImage imageNamed:@"plusNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonRight setTintColor:[Config sharedInstance].colorNormal];
    [buttonRight setImage:[UIImage imageNamed:@"plusClicked"] forState:UIControlStateSelected];
    [buttonRight setImage:[UIImage imageNamed:@"plusClicked"] forState:UIControlStateHighlighted];
    [scrollView addSubview:buttonRight];
    
    [self.view addSubview:scrollView];
}

-(void)updateRow:(NSInteger)row withSettings:(UIViewController *)controller {
    // container
    HorizontalScrollView *scrollView = (HorizontalScrollView *)[self.view viewWithTag:row];
    [self removeSubviews:scrollView];
    
    UIButton *buttonLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    [buttonLeft addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonLeft setTag:61];
    [buttonLeft setTitle:@"Back" forState:UIControlStateNormal];
    [buttonLeft setImage:[[UIImage imageNamed:@"backNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonLeft setTintColor:[Config sharedInstance].colorNormal];
    [buttonLeft setImage:[UIImage imageNamed:@"backClicked"] forState:UIControlStateSelected];
    [buttonLeft setImage:[UIImage imageNamed:@"backClicked"] forState:UIControlStateHighlighted];
    [scrollView addSubview:buttonLeft];
    
    UILabel *labelUsername = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].rowWidth, [Config sharedInstance].rowHeight)];
    [labelUsername setTag:42];
    [labelUsername setText:@""];
    [labelUsername setTextAlignment:NSTextAlignmentCenter];
    [labelUsername setTextColor:[Config sharedInstance].colorOutline];
    [labelUsername setFont:[UIFont boldSystemFontOfSize:[Config sharedInstance].rowTextSize]];
    [scrollView addSubview:labelUsername];
    
    UIButton *buttonRight = [[UIButton alloc] initWithFrame:CGRectMake([Config sharedInstance].rowWidth-100, 0, 90, [Config sharedInstance].rowHeight)];
    [buttonRight addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonRight setTag:43];
    [buttonRight setTitle:@"Login" forState:UIControlStateNormal];
    [buttonRight setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    buttonRight.titleLabel.font = [UIFont boldSystemFontOfSize:[Config sharedInstance].rowHeight/2];
    [buttonRight setTitleColor:[Config sharedInstance].colorNormal forState:UIControlStateNormal];
    [buttonRight setTitleColor:[Config sharedInstance].colorSelected forState:UIControlStateSelected];
    [buttonRight setTitleColor:[Config sharedInstance].colorSelected forState:UIControlStateHighlighted];
    [scrollView addSubview:buttonRight];
    
    [self.view addSubview:scrollView];
}

-(void)updateRow:(NSInteger)row withSearch:(SearchLocation)searchLocation withController:(UIViewController *)controller {
    // container
    HorizontalScrollView *scrollView = (HorizontalScrollView *)[self.view viewWithTag:row];
    [self removeSubviews:scrollView];
    
    // refresh
    UIButton *buttonFive = [[UIButton alloc] initWithFrame:CGRectMake([Config sharedInstance].rowWidth-[Config sharedInstance].rowHeight, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    if (searchLocation == SearchLocationMenu) {
        [buttonFive setTag:37];
        [buttonFive addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
        [buttonFive setTitle:@"Refresh" forState:UIControlStateNormal];
        [buttonFive setImage:[[UIImage imageNamed:@"refreshnormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [buttonFive setTintColor:[Config sharedInstance].colorNormal];
        [buttonFive setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        [buttonFive setImage:[UIImage imageNamed:@"refreshselected"] forState:UIControlStateHighlighted];
        [buttonFive setImage:[UIImage imageNamed:@"refreshselected"] forState:UIControlStateSelected];
    } else {
        [buttonFive setTag:40];
        [buttonFive addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
        [buttonFive setTitle:@"Submit" forState:UIControlStateNormal];
        [buttonFive setImage:[[UIImage imageNamed:@"checkNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [buttonFive setTintColor:[Config sharedInstance].colorGreen];
        buttonFive.imageEdgeInsets = UIEdgeInsetsMake(0, -2, 0, 0);
        [buttonFive setImage:[UIImage imageNamed:@"checkClicked"] forState:UIControlStateHighlighted];
        [buttonFive setImage:[UIImage imageNamed:@"checkClicked"] forState:UIControlStateSelected];
    }
    [scrollView addSubview:buttonFive];
    
    // TODO: add filter button (alpha, popular, recent)
    
    // sort
    UIButton *buttonFour = [[UIButton alloc] initWithFrame:CGRectMake(buttonFive.frame.origin.x - buttonFive.frame.size.width, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    [buttonFour setTag:36];
    [buttonFour addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonFour setTitle:@"Sort-az" forState:UIControlStateNormal];
    [buttonFour setImage:[[UIImage imageNamed:@"sortaznormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonFour setTintColor:[Config sharedInstance].colorNormal];
    [buttonFour setImageEdgeInsets:UIEdgeInsetsMake(5, -3, 5, 1)];
    [buttonFour setImage:[UIImage imageNamed:@"sortazselected"] forState:UIControlStateHighlighted];
    [scrollView addSubview:buttonFour];
    (searchLocation == SearchLocationMenu) ? [buttonFour setHidden:NO] : [buttonFour setHidden:YES];
    
    // trash
    UIButton *buttonThree = [[UIButton alloc] initWithFrame:CGRectMake(buttonFour.frame.origin.x - buttonFour.frame.size.width, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    [buttonThree setTag:35];
    [buttonThree addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonThree setTitle:@"Trash" forState:UIControlStateNormal];
    [buttonThree setImage:[[UIImage imageNamed:@"trashNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonThree setTintColor:[Config sharedInstance].colorNormal];
    [buttonThree setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    [buttonThree setImage:[UIImage imageNamed:@"trashClicked"] forState:UIControlStateHighlighted];
    [buttonThree setImage:[UIImage imageNamed:@"trashClicked"] forState:UIControlStateSelected];
    [scrollView addSubview:buttonThree];
    (searchLocation == SearchLocationMenu) ? [buttonThree setHidden:NO] : [buttonThree setHidden:YES];
    
    // undo
    UIButton *buttonTwo = [[UIButton alloc] initWithFrame:CGRectMake(buttonThree.frame.origin.x - buttonThree.frame.size.width, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    (searchLocation == SearchLocationMenu) ? [buttonTwo setTag:34] : [buttonTwo setTag:39];
    [buttonTwo addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonTwo setTitle:@"Undo" forState:UIControlStateNormal];
    [buttonTwo setTitle:@"Undo" forState:UIControlStateSelected];
    [buttonTwo setImage:[[UIImage imageNamed:@"deleteNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonTwo setTintColor:[Config sharedInstance].colorNormal];
    [buttonTwo setImageEdgeInsets:UIEdgeInsetsMake(2, 6, 0, -2)];
    [buttonTwo setImage:[UIImage imageNamed:@"deleteClicked"] forState:UIControlStateSelected];
    [buttonTwo setImage:[UIImage imageNamed:@"deleteClicked"] forState:UIControlStateHighlighted];
    [scrollView addSubview:buttonTwo];
    
    // search count
    UILabel *labelNoteCount = [[UILabel alloc] initWithFrame:CGRectMake(buttonTwo.frame.origin.x - buttonTwo.frame.size.width+4, 0, [Config sharedInstance].rowHeight+2, [Config sharedInstance].rowHeight)]; //fix
    [labelNoteCount setTag:33];
    [labelNoteCount setTextAlignment:NSTextAlignmentCenter];
    [labelNoteCount setFont:[UIFont boldSystemFontOfSize:12.0]]; //fix
    [labelNoteCount setText:@" 0"]; //fix
    [labelNoteCount setTextColor:[Config sharedInstance].colorOutline];
    [scrollView addSubview:labelNoteCount];
    
    // search
    UITextField *txtSearch = [[UITextField alloc] initWithFrame:CGRectMake([Config sharedInstance].rowTagPadding, [Config sharedInstance].rowTagPadding, scrollView.frame.size.width-(scrollView.frame.size.width-labelNoteCount.frame.origin.x), scrollView.frame.size.height-[Config sharedInstance].rowTagPadding*2)];
    (searchLocation == SearchLocationMenu) ? [txtSearch setTag:32] : [txtSearch setTag:38];
    txtSearch.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search..." attributes:@{NSForegroundColorAttributeName:[Config sharedInstance].colorOutline}];
    [txtSearch setTextColor:[Config sharedInstance].colorSelected];
    [txtSearch setTintColor:[Config sharedInstance].colorSelected];
    [txtSearch addTarget:controller action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [txtSearch setDelegate:(id)controller];
    UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 0)];
    [txtSearch setLeftViewMode:UITextFieldViewModeAlways];
    [txtSearch setLeftView:spacerView];
    txtSearch.layer.borderColor = [[Config sharedInstance].colorOutline CGColor];
    txtSearch.layer.borderWidth = [Config sharedInstance].rowTagBorderWidth;
    txtSearch.layer.cornerRadius = [Config sharedInstance].rowTagBorderRadius;
    [txtSearch setReturnKeyType:UIReturnKeyDone];
    [scrollView addSubview:txtSearch];
    
    [self.view addSubview:scrollView];
}

-(void)updateRow:(NSInteger)row withCreate:(UIViewController *)controller {
    // container
    HorizontalScrollView *scrollView = (HorizontalScrollView *)[self.view viewWithTag:row];
    [self removeSubviews:scrollView];
    
    // close icon
    UIButton *buttonLeft = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    [buttonLeft setTag:61];
    [buttonLeft addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonLeft setTitle:@"Cancel" forState:UIControlStateNormal];
    [buttonLeft setImage:[[UIImage imageNamed:@"deleteNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonLeft setTintColor:[Config sharedInstance].colorNormal];
    [buttonLeft setImage:[UIImage imageNamed:@"deleteClicked"] forState:UIControlStateSelected];
    [buttonLeft setImage:[UIImage imageNamed:@"deleteClicked"] forState:UIControlStateHighlighted];
    [scrollView addSubview:buttonLeft];
    
    // submit icon
    UIButton *buttonRight = [[UIButton alloc] initWithFrame:CGRectMake([Config sharedInstance].rowWidth-[Config sharedInstance].rowHeight, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    [buttonRight setTag:63];
    [buttonRight addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonRight setTitle:@"Submit" forState:UIControlStateNormal];
    [buttonRight setImage:[[UIImage imageNamed:@"checkNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonRight setTintColor:[Config sharedInstance].colorGreen];
    buttonRight.imageEdgeInsets = UIEdgeInsetsMake(0, -2, 0, 0);
    [buttonRight setImage:[UIImage imageNamed:@"checkClicked"] forState:UIControlStateHighlighted];
    [buttonRight setImage:[UIImage imageNamed:@"checkClicked"] forState:UIControlStateSelected];
    [scrollView addSubview:buttonRight];
    
    [self.view addSubview:scrollView];
}

-(void)addShadow {
    [Util createDropShadowWithView:self.view zPosition:4 down:NO];
}

-(void)removeSubviews:(HorizontalScrollView *)scrollView {
    for (id view in [scrollView subviews]) {
        [view removeFromSuperview];
    }
}

#pragma mark - empty methods to avoid warnings
-(void)buttonTap:(UIButton *)button {
    
}

-(void)textFieldDidChange:(UITextField *)textField {
    
}

@end
