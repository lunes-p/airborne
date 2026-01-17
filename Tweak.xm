#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <substrate.h>

// ---------------------------------------------------------
// Config
// ---------------------------------------------------------

// ターゲット: sub_10002e0a0 を呼び出す直前の命令
// Hopper: 0x100afd14c (and x0, x21, #0xffffffff)
#define TARGET_OFFSET 0xafd14c

// 書き込む命令: MOV X0, #0 (これで引数が強制的にCreditsになる)
#define PATCH_INSTRUCTION 0xD2800000

#define BINARY_NAME "Asphalt8"

// ---------------------------------------------------------
// Main Logic
// ---------------------------------------------------------

void apply_patch() {
    NSLog(@"[A8Mod] --- Applying Memory Patch ---");

    uint32_t count = _dyld_image_count();
    intptr_t slide = 0;
    bool found = false;

    // バイナリ検索
    for (uint32_t i = 0; i < count; i++) {
        const char *image_name = _dyld_get_image_name(i);
        if (image_name && strstr(image_name, BINARY_NAME) != NULL) {
            slide = _dyld_get_image_vmaddr_slide(i);
            found = true;
            NSLog(@"[A8Mod] Found Binary: %s", image_name);
            break;
        }
    }

    if (!found) {
        NSLog(@"[A8Mod] Error: Binary not found.");
        return;
    }

    // アドレス計算: Slide + HopperOffset
    // 今回はHopperのベース(0x100000000)を引いた「純粋なオフセット」を使います
    // 0x100afd14c - 0x100000000 = 0xafd14c
    uintptr_t targetAddr = slide + TARGET_OFFSET;
    
    NSLog(@"[A8Mod] Patch Target Address: 0x%lx", targetAddr);

    // 書き込むデータを用意
    uint32_t instruction = PATCH_INSTRUCTION;

    // 【重要】MSHookMemoryを使う
    // 自前のvm_protectではなく、Substrate/ElleKitの機能を使って書き換えます。
    // これによりJailed環境での権限エラーを回避できる可能性が高いです。
    MSHookMemory((void *)targetAddr, &instruction, sizeof(instruction));
    
    NSLog(@"[A8Mod] MSHookMemory called. Check game for 'Credits' instead of 'Tokens'.");
}

%ctor {
    NSLog(@"[A8Mod] Dylib loaded.");
    
    // 起動時の競合回避のため少し待つ
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_patch();
    });
}