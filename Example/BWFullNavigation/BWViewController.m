//
//  BWViewController.m
//  BWFullNavigation
//
//  Created by bairdweng on 10/23/2020.
//  Copyright (c) 2020 bairdweng. All rights reserved.
//

#import "BWViewController.h"
#import <BWFullNavigation/BWFullNavigation-umbrella.h>
@interface BWViewController ()

@end

@implementation BWViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:true animated:true];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor purpleColor];
//    self.bw_prefersNavigationBarHidden = true;
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
