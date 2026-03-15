#ifndef PATCHER_H_
#define PATCHER_H_


struct One_patch {
    long offset;
    unsigned char new_byte;
};

enum Status {
    SUCCES      = 0,
    OPEN_ERROR  = 1,
    CLOSE_ERROR = 2
};


#endif // PATCHER_H_