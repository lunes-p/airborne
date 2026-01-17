#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <substrate.h>

// -----------------------------------------------------------------------
// 最終ターゲット:
// チェック結果を判定する `cbz` 命令のオフセット
// -----------------------------------------------------------------------
#define FINAL_BRANCH_OFFSET 0x100311de4

#define BINARY_NAME "Asphalt8"

// 書き込む命令: B loc_100311e04 (無条件ジャンプ)
// ARM64 Hex: 08 00 00 14
#define PATCH_UNCONDITIONAL_JUMP 0x14000008

void apply_final_patch() {
    NSLog(@"[A8Mod_ForceJump] Searching for binary: %s", BINARY_NAME);

    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, BINARY_NAME)) {
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            
            uint32_t patch = PATCH_UNCONDITIONAL_JUMP;
            
            uintptr_t target_addr = slide + (FINAL_BRANCH_OFFSET - 0x100000000);
            
            MSHookMemory((void *)target_addr, &patch, sizeof(patch));
            
            NSLog(@"[A8Mod_ForceJump] Forced the success branch jump at 0x%lx. This is the one!", target_addr);
            return;
        }
    }
    NSLog(@"[A8Mod_ForceJump] Error: Binary not found.");
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_final_patch();
    });
}