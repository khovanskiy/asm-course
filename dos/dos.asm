global main


section .data
len: db 0

section .text
main:

extern __imp__MessageBoxA@16
extern __imp__ExitProcess@4

push 0
call [__imp__ExitProcess@4]


end