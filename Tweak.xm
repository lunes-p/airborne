#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <substrate.h>

// -----------------------------------------------------------------------
// Target Offsets (Hopper Address)
// 全て "BL sub_100843bb8" (所持金チェック) の行です
// -----------------------------------------------------------------------

// 1. sub_100328880 (既出)
#define OFFSET_1 0x100328be0

// 2. sub_100328cbc (既出)
#define OFFSET_2 0x100328eec

// 3. sub_100478cb4 (★新規: メイン購入処理の可能性大)
#define OFFSET_3 0x100479188

// 4. sub_10059bed4 (★新規)
#define OFFSET_4 0x10059c040

// 5. sub_1007ac55c (★新規)
#define OFFSET_5 0x1007ac7ac

// -----------------------------------------------------------------------

#define BINARY_NAME "Asphalt8"

// 書き込む命令: MOV X0, #1 (戻り値を成功に偽装)
// ARM64 Hex: 20 00 80 D2
#define PATCH_MOV_X0_1 0xD2800020

void apply_patch() {
    NSLog(@"[A8Mod] Searching for binary: %s", BINARY_NAME);

    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, BINARY_NAME)) {
            intptr_t slide = _dyld_get_image_vmaddr_slide(i);
            
            // パッチ対象リスト
            uintptr_t offsets[] = { OFFSET_1, OFFSET_2, OFFSET_3, OFFSET_4, OFFSET_5 };
            int num_patches = 5;

            uint32_t patch = PATCH_MOV_X0_1;

            for (int j = 0; j < num_patches; j++) {
                uintptr_t off = offsets[j];
                // 0x100000000以上なら補正 (Slide計算用)
                if (off > 0x100000000) off -= 0x100000000;

                uintptr_t addr = slide + off;
                
                // 書き換え実行
                MSHookMemory((void *)addr, &patch, sizeof(patch));
                
                NSLog(@"[A8Mod] Applied Free Shopping Patch #%d at 0x%lx", j+1, addr);
            }
            
            NSLog(@"[A8Mod] --- ALL 5 CHECKPOINTS PATCHED ---");
            NSLog(@"[A8Mod] Go buy some cars!");
            return;
        }
    }
    NSLog(@"[A8Mod] Error: Binary not found.");
}

%ctor {
    // 起動直後の競合を避けるため少し待つ
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_patch();
    });
}