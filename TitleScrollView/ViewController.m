//
//  ViewController.m
//  TitleScrollView
//
//  Created by rocky on 2017/2/17.
//  Copyright © 2017年 RockyFung. All rights reserved.
//

#define SCREEN_W [UIScreen mainScreen].bounds.size.width
#define SCREEN_H [UIScreen mainScreen].bounds.size.height

#import "ViewController.h"
#import "TitleLabel.h"
#import "BaseTableViewController.h"

@interface ViewController ()<UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *titleScrollView;
@property (nonatomic, strong) UIScrollView *mainScrollView;
@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, strong) BaseTableViewController *needScrollToTopPage;
@end

@implementation ViewController

- (UIScrollView *)titleScrollView{
    if (!_titleScrollView) {
        _titleScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0,0, SCREEN_W, 40)];
        [self.view addSubview:_titleScrollView];
    }
    return _titleScrollView;
}

- (UIScrollView *)mainScrollView{
    if (!_mainScrollView) {
        _mainScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(0, 40, SCREEN_W, SCREEN_H - 104)];
        [self.view addSubview:_mainScrollView];
    }
    return _mainScrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
//    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.titles = @[@"头条",@"要闻",@"科技",@"汽车",@"军事",@"房产",@"财经",@"游戏"];
    
    self.titleScrollView.showsVerticalScrollIndicator = NO;
    self.titleScrollView.showsHorizontalScrollIndicator = NO;
    self.titleScrollView.scrollsToTop = NO;
    
    self.mainScrollView.scrollsToTop = NO;
    CGFloat contentX = self.titles.count * SCREEN_W;
    self.mainScrollView.contentSize = CGSizeMake(contentX, 0);
    self.mainScrollView.pagingEnabled = YES;
    self.mainScrollView.delegate = self;
    
    [self addTitlesView];
    [self addControllers];
    
    // 添加默认控制器
    UIViewController *vc = [self.childViewControllers firstObject];
    vc.view.frame = self.mainScrollView.bounds;
    [self.mainScrollView addSubview:vc.view];
    TitleLabel *label = [self.titleScrollView.subviews firstObject];
    label.scale = 1.0;
    self.mainScrollView.showsHorizontalScrollIndicator = NO;
    
}
- (void)addControllers{
    for (int i = 0; i < self.titles.count; i++) {
        BaseTableViewController *vc = [[BaseTableViewController alloc]init];
        vc.title = self.titles[i];
        [self addChildViewController:vc];
    }
}


- (void)addTitlesView{
    for (int i = 0; i < self.titles.count; i++) {
        CGFloat itemW = 70;
        CGFloat itemH = 40;
        CGFloat itemY = 0;
        CGFloat itemX = i * itemW;
        
        TitleLabel *label = [[TitleLabel alloc]init];
        label.text = self.titles[i];
        label.frame = CGRectMake(itemX, itemY, itemW, itemH);
        label.font = [UIFont fontWithName:@"HYQiHei" size:19];
        [self.titleScrollView addSubview:label];
        label.tag = i;
        label.userInteractionEnabled = YES;
        // 添加点击手势
        [label addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelClick:)]];
    }
    self.titleScrollView.contentSize = CGSizeMake(70 * self.titles.count, 0);
}

// title点击手势方法
- (void)labelClick:(UIGestureRecognizer *)tap{
    
    TitleLabel *label = (TitleLabel *)tap.view; // 获取点击的view
    
    // 点击改变mainScrollView的contentOffset；
    CGFloat offsetX = label.tag * self.mainScrollView.frame.size.width;
    CGFloat offsetY = self.mainScrollView.contentOffset.y;
    CGPoint offset = CGPointMake(offsetX, offsetY);
    [self.mainScrollView setContentOffset:offset animated:YES];
}



#pragma mark - scrollViewDelegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    // 获得索引
    NSUInteger index = scrollView.contentOffset.x / self.mainScrollView.frame.size.width;
    
    // 滚动标题栏
    TitleLabel *label = (TitleLabel *)self.titleScrollView.subviews[index];
    
    // label中心距离屏幕中心的距离
    CGFloat offsetX = label.center.x - self.titleScrollView.frame.size.width * 0.5;
    CGFloat offsetMax = self.titleScrollView.contentSize.width - self.titleScrollView.frame.size.width;
    
    // label在最前端和最后端位置offsetX的距离不变
    if (offsetX < 0) { // 选中label位置没有超过屏幕中点位置
        offsetX = 0;
    }else if(offsetX > offsetMax){
        offsetX = offsetMax;
    }
    
    CGPoint offset = CGPointMake(offsetX, self.titleScrollView.contentOffset.y);
    [self.titleScrollView setContentOffset:offset animated:YES];
    
    // 添加控制器
    BaseTableViewController *vc = self.childViewControllers[index];
    vc.index = index;
    
    // 把除选中状态外的其他titla设置scale为0
    [self.titleScrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx != index) {
            TitleLabel *label = self.titleScrollView.subviews[idx];
            label.scale = 0;
        }
    }];
    
    if (vc.view.superview) {
        return;
    }
    vc.view.frame = scrollView.bounds;
    [self.mainScrollView addSubview:vc.view];
}

// 滚动结束
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self scrollViewDidEndScrollingAnimation:scrollView];
}

// 正在滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    CGFloat value = scrollView.contentOffset.x / scrollView.frame.size.width; // 滚动距离（标题title）
    if (value < 0) {
        value = 0;
    }
    NSInteger leftIndex = (int)value; // 取整
    NSInteger rightIndex = leftIndex + 1;
    CGFloat scaleRight = value - leftIndex;
    CGFloat scaleLeft = 1 - scaleRight;
    TitleLabel *labelLeft = self.titleScrollView.subviews[leftIndex];
    labelLeft.scale = scaleLeft;
    // 考虑到最后一个板块，如果右边已经没有板块了 就不在下面赋值scale了
    if (rightIndex < self.titleScrollView.subviews.count) {
        TitleLabel *labelRight = self.titleScrollView.subviews[rightIndex];
        labelRight.scale = scaleRight;
    }
    self.title = [NSString stringWithFormat:@"%f",value];
}











- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
