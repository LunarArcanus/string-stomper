%define sys_exit 3Ch
%define sys_write 1
%define sys_read 0
%define sys_close 3
%define sys_open 2

%define std_out 1
%define EOF 0
%define O_RDWR 2

%define buffer_len 1

section .rodata
  endmsg db "Done!", 10
  endmsg_len equ $-endmsg

  neargmsg db "2 arguments expected", 10
  neargmsg_len equ $-neargmsg

  openerrormsg db "An error occurred", 10
  openerrormsg_len equ $-openerrormsg

section .bss
  buffer resq buffer_len
  repbyte resq 1

section .text

global _start
_start:
  align 8
  push rbp
  mov rbp, rsp
  cmp byte [rbp+8], 3
  jne arg_error

  mov rax, sys_open
  mov rdi, qword [rbp+8*3]
  mov r10, qword [rbp+8*4]
  mov [repbyte], r10
  mov rsi, O_RDWR
  syscall

  cmp rax, rax
  js  open_error
  mov r12, rax ; file handler into r12

reader:
  mov rax, sys_read
  mov rdi, r12
  mov rsi, buffer
  mov rdx, buffer_len
  syscall
  cmp rax, EOF
  je done
  cmp qword [buffer], 127
  jge writer
  mov [buffer], r10

writer:
  mov rax, sys_write
  mov rdi, r12
  mov rsi, buffer
  mov rdx, buffer_len
  syscall
  jmp reader

arg_error:
  mov rax, sys_write
  mov rdi, std_out
  mov rsi, neargmsg
  mov rdx, neargmsg_len
  syscall
  
  jmp exit

open_error:
  mov rax, sys_write
  mov rdi, std_out
  mov rsi, open_error
  mov rdx, openerrormsg_len
  syscall

  jmp exit

done:
  mov rax, sys_write
  mov rdi, std_out
  mov rsi, endmsg
  mov rdx, endmsg_len
  syscall
  jmp short close

close:
  mov rax, sys_close
  mov rdi, r12 ; r12 has our file-handler
  syscall
  jmp short exit

exit:
  pop rbp
  mov rax, sys_exit
  xor rdi, rdi
  syscall
