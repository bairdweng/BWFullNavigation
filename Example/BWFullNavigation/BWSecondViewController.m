//
//  BWSecondViewController.m
//  BWFullNavigation_Example
//
//  Created by bairdweng on 2020/10/23.
//  Copyright © 2020 bairdweng. All rights reserved.
//

#import "BWSecondViewController.h"
#import <BWFullNavigation/BWFullNavigation-umbrella.h>
@interface BWSecondViewController ()

@end

@implementation BWSecondViewController
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"第二个页面";
    // 系统自带实现
//    [self.navigationController setNavigationBarHidden:false animated:true];
    
    self.bw_prefersNavigationBarHidden = NO;

//    self.bw_prefersNavigationBarHidden = false;
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
