#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#include <libkern/OSCacheControl.h>

#define MODLog(format, ...) NSLog(@"[A8Mod] " format, ##__VA_ARGS__)

// ============================================================================
// 1. CORE PATCHING FUNCTION (Jailed Memory Patching)
// ============================================================================

// 正しいベースアドレスを取得する
uintptr_t get_base_address() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "Asphalt8")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    // 見つからない場合のフォールバック
    return (uintptr_t)_dyld_get_image_header(0);
}

// メモリ書き換え関数
void patch_mem(uintptr_t offset, uint8_t *bytes, size_t len) {
    static uintptr_t base = 0;
    if (base == 0) {
        base = get_base_address();
        MODLog(@"[Info] Game Base: 0x%lx", base);
    }

    uintptr_t address = base + offset;
    vm_size_t size = len;
    
    // 1. メモリ保護を解除 (RW + Copy)
    kern_return_t err = vm_protect(mach_task_self(), (vm_address_t)address, size, 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (err == KERN_SUCCESS) {
        // 2. 書き込み
        memcpy((void *)address, bytes, len);
        
        // 3. メモリ保護を戻す (RX)
        vm_protect(mach_task_self(), (vm_address_t)address, size, 0, VM_PROT_READ | VM_PROT_EXECUTE);
        
        // 4. 命令キャッシュのクリア (Darwin標準APIを使用)
        // これでリンカーエラーが解消されます
        sys_icache_invalidate((void *)address, len);
        
        MODLog(@"[Success] Patched at 0x%lx", address);
    } else {
        MODLog(@"[Error] vm_protect failed: %d", err);
    }
}

// ============================================================================
// 2. MOD MENU UI
// ============================================================================

@interface AsphaltMenu : UIView
@property (nonatomic, strong) UIView *bgView;
+ (instancetype)shared;
- (void)toggle;
@end

@implementation AsphaltMenu

+ (instancetype)shared {
    static AsphaltMenu *inst = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        inst = [[AsphaltMenu alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    return inst;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        self.hidden = YES;
        self.userInteractionEnabled = YES; // 重要
        
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 220)];
        _bgView.center = self.center;
        _bgView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
        _bgView.layer.cornerRadius = 12;
        _bgView.layer.borderWidth = 2;
        _bgView.layer.borderColor = [UIColor cyanColor].CGColor;
        [self addSubview:_bgView];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 300, 40)];
        title.text = @"Asphalt 8 2.6.0i Mod";
        title.textColor = [UIColor cyanColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont boldSystemFontOfSize:20];
        [_bgView addSubview:title];

        [self addSwitch:@"Token to Credit" y:70 tag:1];
        [self addSwitch:@"Free Shopping" y:130 tag:2];
        
        // 閉じるボタン（念の為）
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(0, 180, 300, 30);
        [closeBtn setTitle:@"Close Menu" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [closeBtn addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
        [_bgView addSubview:closeBtn];
    }
    return self;
}

- (void)addSwitch:(NSString *)name y:(CGFloat)y tag:(NSInteger)tag {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 200, 30)];
    label.text = name;
    label.textColor = [UIColor whiteColor];
    [_bgView addSubview:label];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(230, y, 50, 30)];
    sw.tag = tag;
    [sw addTarget:self action:@selector(swChanged:) forControlEvents:UIControlEventValueChanged];
    [_bgView addSubview:sw];
}

- (void)swChanged:(UISwitch *)sw {
    if (sw.tag == 1) { // Token to Credit (0x2d8b8)
        uint8_t p[] = {0x00, 0x00, 0x80, 0x52, 0xC0, 0x03, 0x5F, 0xD6};
        uint8_t o[] = {0x00, 0x30, 0x40, 0xB9, 0xC0, 0x03, 0x5F, 0xD6};
        patch_mem(0x2d8b8, sw.isOn ? p : o, 8);
    } else if (sw.tag == 2) { // Free Shopping (0x2d9d0)
        uint8_t p[] = {0xC0, 0x03, 0x5F, 0xD6, 0x1F, 0x20, 0x03, 0xD5};
        uint8_t o[] = {0xF6, 0x57, 0xBD, 0xA9, 0xF4, 0x4F, 0x01, 0xA9};
        patch_mem(0x2d9d0, sw.isOn ? p : o, 8);
    }
}

- (void)toggle {
    if (!self.hidden) {
        self.hidden = YES;
    } else {
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        
        if (self.superview != window) [window addSubview:self];
        [window bringSubviewToFront:self];
        self.hidden = NO;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.view == self) self.hidden = YES;
}
@end

// ============================================================================
// 3. HOOKS
// ============================================================================

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAsphaltMod)];
    tap.numberOfTouchesRequired = 3;
    [self addGestureRecognizer:tap];
}

%new
- (void)showAsphaltMod {
    [[AsphaltMenu shared] toggle];
}
%end

%ctor {
    MODLog(@"Mod Loaded. Searching for binary...");
}