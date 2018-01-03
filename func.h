#ifndef FUNC_H__
#define FUNC_H__

extern inline void io_hlt();
extern inline void io_cli();
extern inline void io_sti();
extern inline void io_stihlt();
extern inline int  io_in8();
extern inline int  io_in16();
extern inline int  io_in32();
extern inline void io_out8();
extern inline void io_out16();
extern inline void io_out32();
extern inline int  io_load_eflags();
extern inline void io_store_eflags(int eflags);

#endif  // FUNC_H__

