//
//  OtherTestView.m
//  iOSPrinciple_CALayer
//
//  Created by WhatsXie on 2018/5/28.
//  Copyright © 2018年 WhatsXie. All rights reserved.
//

#import "OtherTestView.h"
#import "MoveLogoImg.h"

@interface OtherTestView ()
@property (weak, nonatomic) IBOutlet MoveLogoImg *img;

@end

@implementation OtherTestView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
    
    //翻转效果
//    [_img showTransform];
    
    //旋转位移
    [_img showAnimation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
