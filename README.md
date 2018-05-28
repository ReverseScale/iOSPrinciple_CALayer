# iOSPrinciple_CALayer
Principle CALayer

## CoreAnimation
### 什么是 CoreAnimation？
CoreAnimation(CA) 是苹果提供的一套基于绘图的动画框架。

在 Apple 的图形架构中，CoreAnimation 是在 OpenGL 和 CoreGraphics 的基础上封装的一套动画 API，而 OpenGL 和 CoreGraphics 则提供一些接口来访问图形硬件(GPU)。

> CoreGraphics (CG) 是一个C语言库，是系统绘制界面、文字、图像等UI的基础。

所以 CoreAnimation 的位置关系应该是这个样子滴：

GPU —> OpenGL & CoreGraphics —> CoreAnimation

### CoreAnimation 和 QuartzCore 的关系？
QuartzCore 主要结构:
* CoreAnimation
* CADisplayLink 定时器
* CALayer 及其子类（参考上方链接）
* CAMediaTiming 协议相关
* CATransaction 事物相关
* CATransform3D

> QuartzCore 引用了 CoreAnimation 头文件，类似于对 CoreAnimation 的包装。

## CALayer
在iOS中，我们所看到的视图UIView是通过QuartzCore(CoreAnimation) 中的CALayer显示出来的，我们讨论的动画效果也是加在这个CALayer上的。 

> CALayer图层类是CoreAnimation的基础，它提供了一套抽象概念。CALayer是整个图层类的基础，它是所有核心动画图层的父类

### 为什么UIView要加一层Layer来负责显示呢？

我们知道 QuartzCore 是跨 iOS 和 macOS 平台的，而 UIView 属于 UIKit 是 iOS 开发使用的，在 macOS 中对应 AppKit 里的 NSView。

```
iOS —> UIKit(触控)      \
							QuartzCore
macOS —> NSView(鼠标)   /
```

这是因为macOS是基于鼠标指针操作的系统，与iOS的多点触控有本质的区别。虽然iOS在交互上与macOS有所不同，但在显示层面却可以使用同一套技术。 

每一个UIView都有个属性layer、默认为CALayer类型，也可以使用自定义的Layer

```objc
/* view的leyer，view是layer的代理 */
@property(nonatomic,readonly,strong) CALayer  *layer;
```

我们看到的 View 其实都是它的 layer，下面我们通过 CALayer 中的集合相关的属性来认识它：

* bounds:图层的bounds是一个CGRect的值，指定图层的大小（bounds.size)和原点(bounds.origin)
* position：指定图层的位置(相对于父图层而言)
* anchorPoint：锚点指定了position在当前图层中的位置，坐标范围0~1
* transform：指定图层的几何变换，类型为上篇说过的CATransform3D

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/46656764.jpg)

如上图的这些属性，注释最后都有一句 Animatable，就是说我们可以通过改变这些属性来实现动画。

默认地，我们修改这些属性都会导致图层从旧值动画显示为新值，称为隐式动画。 

注意到frame的注释里面是没有Animatable的。事实上，我们可以理解为图层的frame并不是一个真实的属性：当我们读取frame时，会根据图层position、bounds、anchorPoint和transform的值计算出它的frame；而当我们设置frame时，图层会根据anchorPoint改变position和bounds。也就是说frame本身并没有被保存。

CALayer 也有类似于UIView的层次结构，一个view实例拥有父视图(superView)和子视图(subView)；同样一个layer也有父图层(superLayer)和子图层(subLayer)。我们可以直接在view的layer上添加子layer达到一些显示效果，但这些单独的layer无法像UIView那样进行交互响应。

## CAAnimation
CALayer 提供以下方法来管理动画：

```objc
- (void)addAnimation:(CAAnimation*)anim forKey:(nullable NSString*)key;
- (void)removeAllAnimations;
- (void)removeAnimationForKey:(NSString*)key;
- (nullable NSArray<NSString*>*)animationKeys;
- (nullable CAAnimation*)animationForKey:(NSString*)key;
```

CAAnimation是动画基类，我们常用的CABasicAnimation和CAKeyframeAnimation都继承于CAPropertyAnimation即属性动画。

```objc
/** Subclass for property-based animations. **/
CA_CLASS_AVAILABLE (10.5, 2.0, 9.0, 2.0)
@interface CAPropertyAnimation : CAAnimation
/* Creates a new animation object with its `keyPath' property set to
 * 'path'. */
+ (instancetype)animationWithKeyPath:(nullable NSString *)path;
/* The key-path describing the property to be animated. */
@property(nullable, copy) NSString *keyPath;
/* When true the value specified by the animation will be "added" to
 * the current presentation value of the property to produce the new
 * presentation value. The addition function is type-dependent, e.g.
 * for affine transforms the two matrices are concatenated. Defaults to
 * NO. */
@property(getter=isAdditive) BOOL additive;
/* The `cumulative' property affects how repeating animations produce
 * their result. If true then the current value of the animation is the
 * value at the end of the previous repeat cycle, plus the value of the
 * current repeat cycle. If false, the value is simply the value
 * calculated for the current repeat cycle. Defaults to NO. */
@property(getter=isCumulative) BOOL cumulative;
/* If non-nil a function that is applied to interpolated values
 * before they are set as the new presentation value of the animation's
 * target property. Defaults to nil. */
@property(nullable, strong) CAValueFunction *valueFunction;
@end
```

CAPropertyAnimation(属性动画)通过改变layer的可动画属性(位置、大小等)实现动画效果。

#### CABasicAnimation
CABasicAnimation可以看做有两个关键帧的CAKeyframeAnimation，通过插值形成一条通过各关键帧的动画路径。但CABasicAnimation更加灵活一些：

```objc
@interface CABasicAnimation : CAPropertyAnimation
@property(nullable, strong) id fromValue;
@property(nullable, strong) id toValue;
@property(nullable, strong) id byValue;
@end
```

我们可以通过上面三个值来规定CABasicAnimation的动画起止状态:

* 这三个属性都是可选的，通常给定其中一个或者两个，以下是官方建议的使用方式 
* 给定fromValue和toValue，将在两者之间进行插值 *
* 给定fromValue和byValue，将在fromValue和fromValue+byValue之间插值 *
* 给定byValue和toValue，将在toValue-byValue和toValue之间插值 *
* 仅给定fromValue，将在fromValue和当前值之间插值 *
* 仅给定toValue，将在当前值和toValue之间插值 *
* 仅给定byValue，将在当前值和当前值+byValue之间插值 *

#### CAKeyframeAnimation
在CAKeyframeAnimation中，除了给定各关键帧之外还可以指定关键帧之间的时间和时间函数：

```objc
@interface CAKeyframeAnimation : CAPropertyAnimation
@property(nullable, copy) NSArray *values;
@property(nullable, copy) NSArray<NSNumber *> *keyTimes;
/* 时间函数有线性、淡入、淡出等简单效果，还可以指定一条三次贝塞尔曲线 */
@property(nullable, copy) NSArray<CAMediaTimingFunction *> *timingFunctions;
@end
```

到这我们已经能够感觉到，所谓动画实际上就是在不同的时间显示不同画面，时间在走进而形成连续变化的效果。所以，动画的关键就是对时间的控制。

## CAMediaTiming
CAMediaTiming是CoreAnimation中一个非常重要的协议，CALayer和CAAnimation都实现了它来对时间进行管理。 

协议定义了8个属性，通过它们来控制时间，这些属性大都见名知意：

```objc
@protocol CAMediaTiming
@property CFTimeInterval beginTime;
@property CFTimeInterval duration;
@proterty float speed;
/* timeOffset时间的偏移量，用它可以实现动画的暂停、继续等效果*/
@proterty CFTimeInterval timeOffset;
@property float repeatCount;
@property CFTimeInterval repeatDuration;
/* autoreverses为true时时间结束后会原路返回，默认为false */
@property BOOL autoreverses;
/* fillMode填充模式，有4种，见下 */
@property(copy) NSString *fillMode;
@end
```

下面这张图形象的说明了这些属性是如何灵活的进行动画时间控制的：

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/2016289.jpg)

需要注意的是，CALayer也实现了CAMediaTiming协议，也就是说如果我们将layer的speed设置为2，那么加到这个layer上的动画都会以两倍速执行。

上面从图层、动画和时间控制的关系上简单认识了CALayer、属性动画和动画时间控制，了解属性动画是根据时间在各关键帧之间进行插值，随时间连续改变layer的某动画属性来实现的。

## UIView与CALayer动画原理
下面从以下两点结合具体代码来探索下CoreAnimation的一些原理
* 1.UIView动画实现原理 
* 2.展示层(presentationLayer)和模型层(modelLayer)

### UIView动画实现原理

UIView提供了一系列UIViewAnimationWithBlocks，我们只需要把改变可动画属性的代码放在animations的block中即可实现动画效果，比如：

```objc
[UIView animateWithDuration:1 animations:^(void){        
		if (_testView.bounds.size.width > 150) {
		    _testView.bounds = CGRectMake(0, 0, 100, 100);
		} else {
			_testView.bounds = CGRectMake(0, 0, 200, 200);
		}
} completion:^(BOOL finished){
		NSLog(@"%d",finished);
}];
```

效果如下： 

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/37448645.jpg)

之前说过，UIView对象持有一个CALayer，真正来做动画的是这个layer，UIView只是对它做了一层封装，可以通过一个简单的实验验证一下：我们写一个MyTestLayer类继承CALayer，并重写它的set方法；再写一个MyTestView类继承UIView，重写它的layerClass方法指定图层类为MyTestLayer：

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/35879217.jpg)

MyTestLayer 实现：

```objc
@interface MyTestLayer : CALayer
@end
@implementation MyTestLayer
- (void)setBounds:(CGRect)bounds {
    NSLog(@"----layer setBounds");
    [super setBounds:bounds];
    NSLog(@"----layer setBounds end");
}
...
@end
```

MyTestView 实现：

```objc
@interface MyTestView : UIView
- (void)setBounds:(CGRect)bounds {
    NSLog(@"----view setBounds");
    [super setBounds:bounds];
    NSLog(@"----view setBounds end");
}
...
+ (Class)layerClass {
    return [MyTestLayer class];
}
@end
```

当我们给view设置bounds时，getter、setter的调用顺序是这样的： 

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/85897136.jpg)

也就是说，在view的setBounds方法中，会调用layer的setBounds；同样view的getBounds也会调用layer的getBounds。其他属性也会得到相同的结论。那么动画又是怎么产生的呢？当我们layer的属性发生变化时，会调用代理方法actionForLayer: forKey: 来获得这次属性变化的动画方案，而view就是它所持有的layer的代理：

```objc
@interface CALayer : NSObject <NSCoding, CAMediaTiming>
...
@property(nullable, weak) id <CALayerDelegate> delegate;
...
@end

@protocol CALayerDelegate <NSObject>
@optional
...
/* If defined, called by the default implementation of the
 * -actionForKey: method. Should return an object implementating the
 * CAAction protocol. May return 'nil' if the delegate doesn't specify
 * a behavior for the current event. Returning the null object (i.e.
 * '[NSNull null]') explicitly forces no further search. (I.e. the
 * +defaultActionForKey: method will not be called.) */
- (nullable id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event;
...
@end
```

注释中说明，该方法返回一个实现了CAAction的对象，通常是一个动画对象；当返回nil时执行默认的隐式动画，返回null时不执行动画。还是上面那个改变bounds的动画，我们在MyTestView中重写actionForLayer:方法

```objc
- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
    id<CAAction> action = [super actionForLayer:layer forKey:event];
    return action;
}
```

观察它的返回值：

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/72587459.jpg)

是一个内部使用的_UIViewAddtiveAnimationAction对象，其中包含一个CABassicAnimation，默认fillMode为both，默认时间函数为淡入淡出，只包含fromValue(即动画之前的值，会在这个值和当前值(block中修改过后的值)之间做动画)。我们可以尝试在重写的这个方法中强制返回nil，会发现我们不写任何动画的代码直接改变属性也将产生一个默认0.25s的隐式动画，这和上面的注释描述是一致的。

#### 关于显式动画和隐式动画
显式动画是指用户自己通过beginAnimations:context:和commitAnimations创建的动画。

隐式动画（iOS 4.0后）是指通过UIView的animateWithDuration:animations:方法创建的动画。

#### 如果两个动画重叠在一起会是什么效果呢？

还是最开始的例子，我们添加两个相同的UIView动画，一个时间为3s，一个时间为1s，并打印finished的值和两个动画的持续时间。先执行3s的动画，当它还没有结束时加上一个1s的动画，可以先看下实际效果：

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/71441972.jpg)

log 打印

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/42888419.jpg)

很明显，两个动画的finished都为true且时间也是我们设置好的3s和1s。也就是说第二个动画并不会打断第一个动画的执行，而是将动画进行了叠加。

动画的心酸路程：
* 最开始方块的bounds为(100,100)，点击执行3s动画，bounds变为(200,200)，并开始展示变大的动画；
* 动画过程中(假设到了(120,120))，点击1s动画，由于这时真实bounds已经是(200,200)了，所以bounds将变回100，并产生一个fromValue为(200,200)的动画。

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/87478630.jpg)

但此时方块并没有从200开始，而是马上开始变小，并明显变到一个比100更小的值。

* 1s动画结束，finished为1，耗时1s。此时屏幕上的方块是一个比100还要小的状态，又缓缓变回到100—3s动画结束，finished为1，耗时3s，方块最终停在(100,100)的大小。

从这个现象我们可以猜想UIView动画的叠加方式：当我们通过改变View属性实现动画时，这个属性的值是会立即改变的，动画只是展示出来的效果。当动画还未结束时如果对同个属性又加上另一个动画，两个动画会从当前展示的状态开始进行叠加，并最终停在view的真实位置。 
> 举个通俗点的例子，我们8点从家出发，要在9点到达学校，我们按照正常的步速行走，这可以理解为一个动画；假如我们半路突然想到忘记带书包了，需要回家拿书包（相当于又添加了一个动画），这时我们肯定需要加快步速，当我们拿到书包时相当于第二个动画结束了，但我们上学这个动画还要继续执行，我们要以合适的速度继续往学校赶，保证在9点准时到达终点—学校。

所以刚才那个方块为什么会有一个比100还小的过程就不难理解了：当第二个动画加上去的时候，由于它是一个1s由200变为100的动画，肯定要比3s动画执行的快，而且是从120的位置开始执行的，所以一定会朝反方向变化到比100还小；1s动画结束后，又会以适当的速度在3s的时间点回到最终位置(100,100)。当然叠加后的整个过程在内部实现中可能是根据时间函数已经计算好的。

这么做或许是为了让动画显得更流畅平滑，那么既然我们设置属性值是立即生效的，动画只是看上去的效果，那刚才叠加的时刻屏幕展示上的位置(120,120)又是什么呢？这就是本篇要讨论的下一个话题。 

### 展示层(presentationLayer)和模型层(modelLayer)
我们知道UIView动画其实是layer层做的，而view是对layer的一层封装，我们对view的bounds等这些属性的操作其实都是对它所持有的layer进行操作，我们做一个简单的实验—在UIView动画的block中改变view的bounds后，分别查看下view和layer的bounds的实际值：

```objc
_testView.bounds = CGRectMake(0, 0, 100, 100);
[UIView animateWithDuration:1 animations:^(void){
	 _testView.bounds = CGRectMake(0, 0, 200, 200);
} completion:nil];
```
 赋值完成后我们分别打印view，layer的bounds： 

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/41186001.jpg)

都已经变成了(200,200)，这是肯定的，之前已经验证过set view的bounds实际上就是set 它的layer的bounds。可动画不是layer实现的么？layer也已经到达终点了，它是怎么将动画展示出来的呢？ 

这里就要提到CALayer的两个实例方法presentationLayer和modelLayer：

```objc
@interface CALayer : NSObject <NSCoding, CAMediaTiming>
...
/* 以下参考官方api注释 */
/* presentationLayer
 * 返回一个layer的拷贝，如果有任何活动动画时，包含当前状态的所有layer属性
 * 实际上是逼近当前状态的近似值。
 * 尝试以任何方式修改返回的结果都是未定义的。
 * 返回值的sublayers 、mask、superlayer是当前layer的这些属性的presentationLayer
 */
- (nullable instancetype)presentationLayer;

/* modelLayer
 * 对presentationLayer调用，返回当前模型值。
 * 对非presentationLayer调用，返回本身。
 * 在生成表示层的事务完成后调用此方法的结果未定义。
 */
- (instancetype)modelLayer;
...
```

从注释不难看出，这个presentationLayer即是我们看到的屏幕上展示的状态，而modelLayer就是我们设置完立即生效的真实状态，我们动画开始后延迟0.1s分别打印layer，layer.presentationLayer，layer.modelLayer和layer.presentationLayer.modelLayer : 

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/76512189.jpg)

明显，layer.presentationLayer是动画当前状态的值，而layer.modelLayer 和 layer.presentationLayer.modelLayer 都是layer本身。

到这里，CALayer动画的原理基本清晰了，当有动画加入时，presentationLayer会不断的(从按某种插值或逼近得到的动画路径上)取值来进行展示，当动画结束被移除时则取modelLayer的状态展示。这也是为什么我们用CABasicAnimation时，设定当前值为fromValue时动画执行结束又会回到起点的原因，实际上动画结束并不是回到起点而是到了modelLayer的位置。

虽然我们可以使用fillMode控制它结束时保持状态，但这种方法在动画执行完之后并没有将动画从渲染树中移除(因为我们需要设置animation.removedOnCompletion = NO才能让fillMode生效)。如果我们想让动画停在终点，更合理的办法是一开始就将layer设置成终点状态，其实前文提到的UIView的block动画就是这么做的。

如果我们一开始就将layer设置成终点状态再加入动画，会不会造成动画在终点位置闪一下呢？其实是不会的，因为我们看到的实际上是presentationLayer，而我们修改layer的属性，presentationLayer是不会立即改变的：

```objc
MyTestView *view = [[MyTestView alloc]initWithFrame:CGRectMake(200, 200, 100, 100)];
[self.view addSubview:view];

view.center = CGPointMake(1000, 1000);

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1/60) * NSEC_PER_SEC)), dispatchQueue, ^{
    NSLog(@"presentationLayer %@ y %f",view.layer.presentationLayer, view.layer.presentationLayer.position.y);
    NSLog(@"layer.modelLayer %@ y %f",view.layer.modelLayer,view.layer.modelLayer.position.y);
});
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1/20) * NSEC_PER_SEC)), dispatchQueue, ^{
    NSLog(@"presentationLayer %@ y %f",view.layer.presentationLayer, view.layer.presentationLayer.position.y);
    NSLog(@"layer.modelLayer %@ y %f",view.layer.modelLayer,view.layer.modelLayer.position.y);
});
```

在上面代码中我们改变view的center，modelLayer是立即改变的因为它就是layer本身。但presentationLayer是没有变的，我们尝试延迟一定时间再去取presentationLayer，发现它是在一个很短的时间之后才发生变化的，这个时间跟具体设备的屏幕刷新频率有关。

也就是说我们给layer设置属性后，当下次屏幕刷新时，presentationLayer才会获取新值进行绘制。因为我们不可能对每一次属性修改都进行一次绘制，而是将这些修改保存在model层，当下次屏幕刷新时再统一取model层的值重绘。

如果我们添加了动画，并将modelLayer设置到终点位置，下次屏幕刷新时，presentationLayer会优先从动画中取值来绘制，所以并不会造成在终点位置闪一下。

#### 小结一下
* UIView持有一个CALayer负责展示，view是这个layer的delegate。改变view的属性实际上是在改变它持有的layer的属性，layer属性发生改变时会调用代理方法actionForLayer: forKey: 来得知此次变化是否需要动画。对同一个属性叠加动画会从当前展示状态开始叠加并最终停在modelLayer的真实位置。
* CALayer内部控制两个属性presentationLayer和modelLayer，modelLayer为当前layer真实的状态，presentationLayer为当前layer在屏幕上展示的状态。presentationLayer会在每次屏幕刷新时更新状态，如果有动画则根据动画获取当前状态进行绘制，动画移除后则取modelLayer的状态。

### 初探CALayer属性

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/46548789.jpg)

#### CALayer和UIView的区别
* 1.UIView是UIKit的(只能iOS使用)，CALayer是QuartzCore的(iOS和mac os通用)
* 2.UIView继承UIResponder,CALayer继承NSObject,UIView比CALayer多了一个事件处理的功能，也就是说，CALayer不能处理用户的触摸事件，而UIView可以
* 3.UIView来自CALayer，是CALayer的高层实现和封装，UIView的所有特性来源于CALayer支持
* 4.CABasicAnimation，CAAnimation，CAKeyframeAnimation等动画类都需要加到CALayer上

其实UIView之所以能显示在屏幕上，完全是因为它内部的一个图层，在创建UIView对象时，UIView内部会自动创建一个图层(即CALayer对象)，通过UIView的layer属性可以访问这个层。

```objc
@property(nonatomic,readonly,retain) CALayer *layer;
```

当UIView需要显示到屏幕上时，会调用drawRect:方法进行绘图，并且会将所有内容绘制在自己的图层上，绘图完毕后，系统会将图层拷贝到屏幕上，于是就完成了UIView的显示。

> 换句话说，UIView本身不具备显示的功能，是它内部的层才有显示功能

CALayer属性表

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/6097440.jpg)

### 使用CALayer的Mask实现注水动画效果

Core Animation一直是iOS比较有意思的一个主题，使用Core Animation可以实现非常平滑的炫酷动画。Core animtion的API是较高级的封装，使用便捷，使得我们免于自己使用OpenGL实现动画。 

下面主要介绍如何使用CALayer的mask实现一个双向注水动画 

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/7735623.jpg)

了解CALayer的mask

```objc
@property(strong) CALayer *mask;
```

mask实际上layer内容的一个遮罩。
 如果把mask设置为透明的，实际看到的layer是完全透明的，也就是说只有mask的内容不透明的部分和layer叠加。

![](http://og1yl0w9z.bkt.clouddn.com/18-5-28/18806290.jpg)

实现思路：设计的思路参考基于Core Animation的KTV歌词视图的平滑实现
(http://www.iwangke.me/2014/10/06/how-to-implement-a-core-animation-based-60-fps-ktv-lyrics-view/)

flow 在View上重叠放置两个UIImageView: grayHead&greenHead，默认greenHead会遮挡住grayHead。 

为greenHead设置一个mask，这个mask不是普通的mask，它由两个subLayer:maskLayerUp maskLayerDown组成。 

默认情况下，subLayer都显示在mask内容之外，此时mask实际上透明的，由此greenHead也是透明的。 

现在我们希望greenHead从左上角和右下角慢慢显示内容，那么我们只需要从两个方向为greenHead填充内容就可以了.

创建mask遮罩

```objc
- (CALayer *)greenHeadMaskLayer {
    CALayer *mask = [CALayer layer];
    mask.frame = self.greenHead.bounds;
     
    self.maskLayerUp = [CAShapeLayer layer];
    self.maskLayerUp.bounds = CGRectMake(0, 0, 30.0f, 30.0f);
    self.maskLayerUp.fillColor = [UIColor greenColor].CGColor; // Any color but clear will be OK
    self.maskLayerUp.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(15.0f, 15.0f)
                                                           radius:15.0f
                                                       startAngle:0
                                                         endAngle:2*M_PI
                                                        clockwise:YES].CGPath;
    self.maskLayerUp.opacity = 0.8f;
    self.maskLayerUp.position = CGPointMake(-5.0f, -5.0f);
    [mask addSublayer:self.maskLayerUp];
     
    self.maskLayerDown = [CAShapeLayer layer];
    self.maskLayerDown.bounds = CGRectMake(0, 0, 30.0f, 30.0f);
    self.maskLayerDown.fillColor = [UIColor greenColor].CGColor; // Any color but clear will be OK
    self.maskLayerDown.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(15.0f, 15.0f)
                                                             radius:15.0f
                                                         startAngle:0
                                                           endAngle:2*M_PI
                                                          clockwise:YES].CGPath;
    self.maskLayerDown.position = CGPointMake(35.0f, 35.0f);
    [mask addSublayer:self.maskLayerDown];
    return mask;
}
```

做夹角动画

```objc
- (void)startGreenHeadAnimation {
    CABasicAnimation *downAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    downAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(-5.0f, -5.0f)];
    downAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(10.0f, 10.0f)];
    downAnimation.duration = duration;
    [self.maskLayerUp addAnimation:downAnimation forKey:@"downAnimation"];
     
    CABasicAnimation *upAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    upAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(35.0f, 35.0f)];
    upAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(20.0f, 20.0f)];
    upAnimation.duration = duration;
    [self.maskLayerDown addAnimation:upAnimation forKey:@"upAnimation"];
}
```

#### 小结一下：
* CALayer提供另外一种操作UI的手段，虽然它提供的API比UIView较底层，但它能提供更加丰富的功能和更高的性能(CALayer的动画是在专门的线程渲染的)。涉及到复杂且性能要求高的UI界面，CALayer的作用就比较明显了，比如AsyncDisplayKit。 
* 其实也能看出CALayer的一个用处，通常我们处理圆角时会直接去修改CALayer的cornerRadius，但这种做法性能比较差，尤其是放在列表里的时候，现在我们有了mask，这样我们可以直接改变layer的mask，而不会影响到图形渲染的性能。 

### 为啥有了CALayer了还要UIView

UIView继承自UIResponder，主要特点是可以响应触摸事件。而CALayer实际的图层内容管理。大家干的的事情不一样，是两个东西，大家的存在互不影响，理所当然。 

#### UILayer 
假设有一个UIView和CALayer集合体UILayer这个UILayer是一个全能的Layer，可以负责管理显示内容，也能处理触摸事件 。

但由于iOS系统的更新，所以你要不断修改维护UILayer，比如iOS3.2版本增加手势识别、iOS4引入了Block语法、iOS6增加AutoLayout特性、iOS7的UI得改头换面，每次都要打开巨长的UILayer从头改到脚。这样的维护成本太高了。 

所以，在这份理所当然的SDK的背后，蕴藏着大牛门几十年的设计智慧。当中应该能够看到很多门道。这次就UIView和CALayer来分析，就可以得出一些东西。

这方面的设计原则：
* 机制与策略分离
* 整体稳定
* 各司其职
* 减少暴露

#### 机制与策略分离

Unix内核设计的一个主要思想是——提供(Mechanism)机制而不是策略(Policy)。编程问题都可以抽离出机制和策略部分。机制一旦实现，就会很少更改，但策略会经常得到优化。例如原子可以看做是机制，而各种原子的组成就是一种策略。

CALayer也可以看做是一种机制，提供图层绘制，你们可以翻开CALayer的头文件看看，基本上是没怎么变过的，而UIView可以看做是策略，变动很多。越是底层，越是机制，越是机制就越是稳定。机制与策略分离，可以使得需要修改的代码更少，特别是底层代码，这样可以提高系统的稳定性。

#### 整体稳定

稳定给你的是什么感觉？坚固？不可形变？稳定其实就是不可变。一个系统不可变的东西越多，越是稳定。所以机制恰是满足这个不可变的因素的。构建一个系统有一个指导思想就是尽量抽取不可变的东西和可变的东西分离。水是成不了万丈高楼的，坚固的混凝土才可以。更少的修改，意味着更少的bug的几率。

#### 各司其职

即使能力再大也不能把说有事情都干了，万一哪一天不行了呢，那就是突然什么都不能干了。所以仅仅是基于分散风险原则也不应该出现全能类。各司其职，相互合作，把可控粒度降到最低，这样也可以是系统更稳定，更易修改。

#### 减少暴露

接口应该面向大众的，按照八二原则，其实20%的接口就可以满足80%的需求，剩下的80%应该隐藏在背后。因为漏的少总是安全的，不是吗。剩下的80%专家接口可以隐藏与深层次。比如UIView遮蔽了大部分的CALayer接口，抽取构造出更易用的frame和动画实现，这样上手更容易。

> 以上原理解析文章来源：https://blog.csdn.net/zmmzxxx/article/details/74276077#一calayer简介
