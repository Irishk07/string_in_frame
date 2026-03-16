#ifndef PATCHER_H_
#define PATCHER_H_


const char* CORRECT_FILE        = "hack2.COM";
const char* CORRECT_PATCH_FILE  = "p_hack2.com";
const char* PATCH_FILE          = "patch.com";


struct One_patch {
    long offset;
    unsigned char new_byte;
};

enum Status {
    SUCCES          = 0,
    OPEN_ERROR      = 1,
    CLOSE_ERROR     = 2,
    WRONG_FILE      = 3,
    ALREADY_PATCHED = 4
};


Status Patch(const char* filename, One_patch* all_patches, int patch_count);

long GetFileSize(const char* filename);

unsigned long Hash(const char* filename);


#endif // PATCHER_H_