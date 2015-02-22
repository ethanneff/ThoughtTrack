//
//  NotesTableView.m
//  ThoughtTrack
//
//  Created by Ethan Neff on 1/15/15.
//  Copyright (c) 2015 ethanneff. All rights reserved.
//

#import "NotesTableView.h"
#import "Config.h"
#import "Util.h"
#import "Storage.h"
#import "CellTextField.h"

@interface NotesTableView() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIViewController *controller;
@property (nonatomic) UIView *menu;

@end

@implementation NotesTableView

#pragma mark - init
-(instancetype)init {
    self = [super init];
    if (self) {
        _view = [[UITableView alloc] init];
    }
    return self;
}

-(instancetype)initWithMenu:(UIView *)menu withController:(UIViewController *)controller
{
    self = [super init];
    if (self) {
        [self createWithMenu:menu withController:controller];
    }
    return self;
}

+(instancetype)createWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    return [[self alloc] initWithMenu:menu withController:controller];
}

#pragma mark - create
-(UIView *)createWithMenu:(UIView *)menu withController:(UIViewController *)controller {
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [Config sharedInstance].frameWidth, [Config sharedInstance].frameHeight-(menu.frame.size.height))];
    [self.view setBackgroundColor:[Config sharedInstance].colorSelected];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [Config sharedInstance].statusBarHeight, [Config sharedInstance].frameWidth, [Config sharedInstance].frameHeight-(menu.frame.size.height + [Config sharedInstance].statusBarHeight))];
    [self.tableView setBackgroundColor:[Config sharedInstance].colorSelected];

    [self.tableView setTag:2];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [self.tableView setSeparatorColor:[Config sharedInstance].colorBackground];
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, ([Config sharedInstance].frameWidth-[Config sharedInstance].cellWidth)/2, 0, ([Config sharedInstance].frameWidth-[Config sharedInstance].cellWidth)/2)];
    [self.view addSubview:self.tableView];
    
    self.controller = controller;
    self.menu = menu;
    
    return self.view;
}


#pragma mark - tableview methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    [self createCell:cell withData:self.data[indexPath.row] withIndexPath:indexPath withMenu:self.menu withController:self.controller];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [Config sharedInstance].rowHeight;
}

#pragma mark - cell
-(void)createCell:(UITableViewCell *)cell withData:(NSDictionary *)data withIndexPath:(NSIndexPath *)indexPath withMenu:(UIView *)menu withController:(UIViewController *)controller {
    // container
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(([Config sharedInstance].frameWidth-[Config sharedInstance].cellWidth)/2, 0, [Config sharedInstance].cellWidth, [Config sharedInstance].rowHeight)];
    
    // cell id
    UILabel *labelRowIndex = [[UILabel alloc] init];
    labelRowIndex.hidden = YES;
    labelRowIndex.text = [NSString stringWithFormat:@"%li",(long)indexPath.row];
    labelRowIndex.tag = 81;
    [containerView addSubview:labelRowIndex];
    
    // note id
    UILabel *labelNoteGuid = [[UILabel alloc] init];
    labelNoteGuid.hidden = YES;
    labelNoteGuid.text = data[@"noteGuid"];
    labelNoteGuid.tag = 85;
    [containerView addSubview:labelNoteGuid];
    
    CGSize textSize;
    
    // title
    NSString *title = data[@"noteTitle"];
    textSize = [[title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] sizeWithAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:[Config sharedInstance].cellTextSizeTitle]}];
    CellTextField *textFieldNoteTitle = [[CellTextField alloc] initWithFrame:CGRectMake([Config sharedInstance].cellPadding, [Config sharedInstance].cellPadding, [Config sharedInstance].cellWidth-2*[Config sharedInstance].cellPadding-[Config sharedInstance].rowHeight/2-2, [Config sharedInstance].rowHeight)];
    textFieldNoteTitle.tag = 83;
    textFieldNoteTitle.font = [UIFont boldSystemFontOfSize:[Config sharedInstance].cellTextSizeTitle];
    if ([data[@"noteNotebookGuid"] isEqualToString:[[Storage sharedInstance] getNotebookGuidWithName:@"Completed"]]) {
        NSAttributedString *strikeThrough = [[NSAttributedString alloc] initWithString:title attributes:@{NSStrikethroughStyleAttributeName:[NSNumber numberWithInteger:NSUnderlineStyleSingle]}];
        textFieldNoteTitle.attributedText = strikeThrough;
        textFieldNoteTitle.textColor = [Config sharedInstance].colorOutline;
    } else {
        [textFieldNoteTitle setText:title];
        textFieldNoteTitle.textColor = [Config sharedInstance].colorBackground;
    }
    textFieldNoteTitle.tintColor = [Config sharedInstance].colorBackground;
    textFieldNoteTitle.delegate = (id)controller;
    textFieldNoteTitle.returnKeyType = UIReturnKeyDone;
    [containerView addSubview:textFieldNoteTitle];
    
    // details
    NSString *noteUpdated = @"";
    int daysUpdated = (([[NSDate date] timeIntervalSince1970]) - ([data[@"noteUpdated"] floatValue] / 1000)) / 86400;
    if (daysUpdated == 0) {
        noteUpdated = @"Today | ";
    } else if (daysUpdated == 1) {
        noteUpdated = @"1 Day | ";
    } else {
        noteUpdated = [NSString stringWithFormat:@"%i Days | ", daysUpdated];
    }
    NSString *noteNotebook = data[@"noteNotebookName"];
    NSArray *noteTagsNames = (NSArray *)data[@"noteTagNames"];
    (noteTagsNames.count > 0) ? noteNotebook = [NSString stringWithFormat:@"%@ | ", noteNotebook] : nil;
    
    NSString *noteTags = @"";
    for (NSInteger i = 0; i < noteTagsNames.count; i++) {
        if (i != noteTagsNames.count-1) {
            noteTags = [noteTags stringByAppendingString:[NSString stringWithFormat:@"%@ | ", noteTagsNames[i]]];
        } else {
            noteTags = [noteTags stringByAppendingString:noteTagsNames[i]];
        }
    }
    
    NSString *noteDetails = [NSString stringWithFormat:@"%@%@%@", noteUpdated, noteNotebook, noteTags];
    textSize = [[noteDetails stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:[Config sharedInstance].cellTextSizeDetail]}];
    
    UILabel *labelDetails = [[UILabel alloc] initWithFrame:CGRectMake([Config sharedInstance].cellPadding,[Config sharedInstance].rowHeight-textSize.height,[Config sharedInstance].cellWidth-2*[Config sharedInstance].cellPadding-[Config sharedInstance].rowHeight/2,textSize.height)];
    labelDetails.tag = 84;
    labelDetails.text = noteDetails;
    labelDetails.font = [UIFont systemFontOfSize:[Config sharedInstance].cellTextSizeDetail];
    labelDetails.textAlignment = NSTextAlignmentLeft;
    labelDetails.textColor = [Config sharedInstance].colorOutline;
    [containerView addSubview:labelDetails];
    
    [cell addSubview:containerView];
    
    // note view arrow
    UIButton *buttonArrow = [[UIButton alloc] initWithFrame:CGRectMake(([Config sharedInstance].frameWidth-[Config sharedInstance].cellWidth)+[Config sharedInstance].cellWidth-[Config sharedInstance].rowHeight-5, 0, [Config sharedInstance].rowHeight, [Config sharedInstance].rowHeight)];
    [buttonArrow setTag:82];
    [buttonArrow addTarget:controller action:@selector(buttonTap:) forControlEvents: UIControlEventTouchUpInside];
    [buttonArrow setTitle:@"viewNote" forState:UIControlStateNormal];
    [buttonArrow setImage:[[UIImage imageNamed:@"arrowrightNormal"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonArrow setTintColor:[Config sharedInstance].colorOutline];
    [buttonArrow setImageEdgeInsets:UIEdgeInsetsMake(6, 0, 4, 10)];
    [buttonArrow setImage:[UIImage imageNamed:@"arrowrightSelected"] forState:UIControlStateHighlighted];
    [cell addSubview:buttonArrow];
    
    // swipe right
    UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:controller action:@selector(updateCellSwipeRight:)];
    [swipeRightRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [cell addGestureRecognizer:swipeRightRecognizer];
    
    // swipe left
    UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:controller action:@selector(updateCellSwipeLeft:)];
    [swipeLeftRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [cell addGestureRecognizer:swipeLeftRecognizer];
}

#pragma mark - empty methods to avoid warnings
-(void)buttonTap:(UIButton *)button {
    
}

-(void)updateCellSwipeRight:(UITableViewCell *)cell {

}

-(void)updateCellSwipeLeft:(UITableViewCell *)cell {
 
}




@end
