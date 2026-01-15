// ---------------------------------------------------------
// 1. Imports & Constants (ファイルの先頭に配置)
// ---------------------------------------------------------
#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <substrate.h>

// Hopperで表示されているアドレスそのまま (削らない)
#define HOPPER_ADDRESS 0x100afd14c

// バイナリ名 (部分一致検索用)
#define BINARY_NAME "Asphalt8"

// 書き込む命令: MOV X0, #0 (ARM64 Little Endian: 00 00 80 D2 -> 0xD2800000)
#define PATCH_INSTRUCTION 0xD2800000

// ---------------------------------------------------------
// 2. Helper Functions
// ---------------------------------------------------------

// メモリの書き換え処理 (vm_protectで保護を外して書き込む)
bool patch_memory(uintptr_t address, uint32_t instruction) {
    kern_return_t err;

    // 1. 書き込み許可を与える (READ | WRITE | COPY)
    err = vm_protect(mach_task_self(), (vm_address_t)address, sizeof(uint32_t), 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (err != KERN_SUCCESS) {
        NSLog(@"[A8Mod] Error: vm_protect(RW) failed with code %d at 0x%lx", err, address);
        return false;
    }

    // 2. 命令を書き込む
    *(uint32_t *)address = instruction;
    NSLog(@"[A8Mod] Successfully wrote instruction 0x%X to address 0x%lx", instruction, address);

    // 3. 実行許可に戻す (READ | EXECUTE)
    err = vm_protect(mach_task_self(), (vm_address_t)address, sizeof(uint32_t), 0, VM_PROT_READ | VM_PROT_EXECUTE);
    
    if (err != KERN_SUCCESS) {
        NSLog(@"[A8Mod] Warning: vm_protect(RX) failed with code %d. App might be unstable.", err);
    }

    return true;
}

// パッチ適用のメインロジック
void apply_patches() {
    NSLog(@"[A8Mod] --- Starting Patch Process ---");

    uint32_t count = _dyld_image_count();
    intptr_t slide = 0;
    bool found = false;

    // バイナリを検索
    for (uint32_t i = 0; i < count; i++) {
        const char *image_name = _dyld_get_image_name(i);
        if (image_name && strstr(image_name, BINARY_NAME) != NULL) {
            slide = _dyld_get_image_vmaddr_slide(i);
            found = true;
            NSLog(@"[A8Mod] Found Target Binary: %s", image_name);
            NSLog(@"[A8Mod] ASLR Slide: 0x%lx", slide);
            break;
        }
    }

    if (!found) {
        NSLog(@"[A8Mod] Error: Binary '%s' not found.", BINARY_NAME);
        return;
    }

    // アドレス計算: Slide + HopperAddress
    // これで 0x72c4000 + 0x100afd14c = 0x107d8114c のような正しいアドレスになります
    uintptr_t targetAddr = slide + HOPPER_ADDRESS;

    NSLog(@"[A8Mod] Hopper Address: 0x%llx", (uint64_t)HOPPER_ADDRESS);
    NSLog(@"[A8Mod] Calculated Runtime Address: 0x%lx", targetAddr);

    // デバッグ: 書き換え前の値を確認
    // アドレス計算が間違っているとここでクラッシュするので、ログで確認できる
    @try {
        uint32_t currentVal = *(uint32_t *)targetAddr;
        NSLog(@"[A8Mod] Current value at target: 0x%X", currentVal);
    } @catch (NSException *e) {
        NSLog(@"[A8Mod] Critical Error: Cannot read memory at 0x%lx. Address calculation might still be wrong.", targetAddr);
        return;
    }

    // パッチ実行
    if (patch_memory(targetAddr, PATCH_INSTRUCTION)) {
        NSLog(@"[A8Mod] --- PATCH APPLIED SUCCESSFULLY ---");
        NSLog(@"[A8Mod] Check in-game if 'Tokens' are now 'Credits'.");
    } else {
        NSLog(@"[A8Mod] --- PATCH FAILED ---");
    }
}

// ---------------------------------------------------------
// 3. Constructor
// ---------------------------------------------------------
%ctor {
    NSLog(@"[A8Mod] Dylib loaded. Waiting for game to initialize...");
    
    // 起動直後の競合を避けるため3秒待つ
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_patches();
    });
}