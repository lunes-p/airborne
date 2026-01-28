#import <substrate.h>
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import <string.h>

#define MODLog(format, ...) NSLog(@"[Asphalt8Mod] " format, ##__VA_ARGS__)

// ヘッダ取得関数
const struct mach_header *get_game_header() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "Asphalt8")) {
            return _dyld_get_image_header(i);
        }
    }
    return NULL;
}

// ---------------------------------------------------------
// Target: sub_100843bb8 (Money Check / Calculator)
// ---------------------------------------------------------
// Hopper Addr: 0x100843bb8 -> Offset: 0x843bb8
// この関数は起動時には実行されないため、安全にフックできる可能性が高いです。
// ---------------------------------------------------------

int (*old_sub_100843bb8)(void *thisPointer);

int new_sub_100843bb8(void *thisPointer) {
    MODLog(@"[MoneyCheck] sub_100843bb8 CALLED!");
    
    // オリジナルの値をログに出す（もし呼ばれたら重要）
    int original = old_sub_100843bb8(thisPointer);
    MODLog(@"[MoneyCheck] Original Value: %d", original);
    
    // 強制的に 9億 にする
    // これで購入が成功すれば、表示が変わらなくても実質無限
    return 999999999;
}

%ctor {
    MODLog(@"========== MOD PHASE 5 LOADED ==========");
    
    const struct mach_header *header = get_game_header();
    
    if (header != NULL) {
        // オフセット 0x843bb8 (sub_100843bb8)
        uintptr_t staticOffset = 0x843bb8;
        void *targetAddr = (void *)((uintptr_t)header + staticOffset);
        
        MODLog(@"Hooking sub_100843bb8 at: %p", targetAddr);
        
        MSHookFunction(targetAddr, (void *)new_sub_100843bb8, (void **)&old_sub_100843bb8);
        
        MODLog(@"Hook installed.");
    } else {
        MODLog(@"Error: Game header not found.");
    }
}