global _print

section .data
left dd 0,0,0,0
right dd 0,0,0,0
flag_plus db 0
flag_minus db 0
flag_space db 0
flag_zero db 0
flag_negate db 0
width dd 0
hex_length dd 0
current_sign db 0

;TODO: FIX problem with -80...00
section .text
_print:
push ebp
mov ebp, esp
sub esp, 0
;[ebp+16] = 3rd argument hex_number
;[ebp+12] = 2sd argument format
;[ebp+8] = 1st argument out_buf
pushad
call zeroLeft
call zeroRight
mov byte [flag_plus], 0
mov byte [flag_minus], 0
mov byte [flag_space], 0
mov byte [flag_zero], 0
mov byte [flag_negate], 0
mov dword [width], 0
mov dword [hex_length], 0
mov byte [current_sign], 0

;PARSE FORMAT
mov eax, [ebp+12]
xor edx, edx ; local width
format_parsing_loop_in:
	mov bl, byte [eax]
	cmp bl, 0x0 ; if (current char == '\0')
		je format_parsing_loop_out
	cmp bl, '+' ; if (current char == '+')
		jne format_current_not_plus
		mov byte [flag_plus], 1
		jmp format_switch_out
	format_current_not_plus:
	cmp bl, '-' ; if (current char == '-')
		jne format_current_not_minus
		mov byte [flag_minus], 1
		jmp format_switch_out
	format_current_not_minus:
	cmp bl, ' ' ; if (current char == ' ')
		jne format_current_not_space
		mov byte [flag_space], 1
		jmp format_switch_out
	format_current_not_space:
	cmp bl, '0'
	jne format_current_not_zero
	cmp edx, 0
	jne format_current_not_zero
		mov byte [flag_zero], 1
		jmp format_switch_out
	format_current_not_zero:
	cmp bl, '9'
		ja parse_error_in
	cmp bl, '0'
		jb parse_error_in
		sub bl, '0'
		imul edx, 10
		and ebx, 0x000000FF
		add edx, ebx
		jmp format_switch_out
	format_switch_out:
	inc eax
	jmp format_parsing_loop_in
format_parsing_loop_out:
mov dword [width], edx

;PARSE HEX HUMBER
;Is hex number negative
mov eax, [ebp+16]
cmp byte [eax], '-'
	jne parse_negation_out
	mov byte [flag_negate], 1
	inc eax
parse_negation_out:

;get length
xor edx, edx
number_length_loop_in:
	mov bl, byte [eax]
	cmp bl, 0x0
	je number_length_loop_out
		inc eax
		inc edx
		jmp number_length_loop_in
number_length_loop_out:
mov dword [hex_length], edx

;hex to dec
xor ecx, ecx
conversion_loop_in:
cmp edx, 0x0
je conversion_loop_out
	dec eax
	pushad
	push ecx
	mov ebx, dword [eax]
	and ebx, 0x000000FF
	; if (number)
	cmp ebx, '9'
	ja not_number 
	cmp ebx, '0'
	jb not_number 
	sub ebx, '0'
	jmp fetch_symbol

	not_number:
	cmp ebx, 'F'
	ja not_number_not_big_char 
	cmp ebx, 'A'
	jb not_number_not_big_char 
	sub ebx, 'A'
	add ebx, 10
	jmp fetch_symbol

	not_number_not_big_char:
	cmp ebx, 'f'
	ja parse_error_in
	cmp ebx, 'a'
	jb parse_error_in
	sub ebx, 'a'
	add ebx, 10

	fetch_symbol:
	mov dword [right], ebx
	mov dword [right+4], 0
	mov dword [right+8], 0
	mov dword [right+12], 0
	call pow16
	pop ecx
	popad

	add ecx, 4
	call summarize

	dec edx
jmp conversion_loop_in
conversion_loop_out:

; if (number is negative)
;call testLeft
call smartInvert
;call testLeft

call defineSign
;call testFlags

; split dec_number
number_splitting_in:

xor ecx, ecx ; count of processed chars

call testZero
cmp edx, 0
jne dec_number_not_zero
mov dl, '0'
push edx
inc ecx
jmp splitting_loop_out
dec_number_not_zero:

splitting_loop_in:
call testZero
cmp edx, 0
je splitting_loop_out

call div10
add edx, '0'
push edx

inc ecx
jmp splitting_loop_in
splitting_loop_out:


cmp byte [flag_minus], 1
je align_by_right_side_out

	cmp byte [flag_zero], 0x0
	jne full_filling_zero_in
		cmp byte [current_sign], 0x0
		je without_any_sign_v1
			mov dl, byte [current_sign]
			push edx
			inc ecx
		without_any_sign_v1:

		mov ebx, dword [width]
		filling_space_loop_in:
		cmp ecx, ebx
		jae filling_space_loop_out
			mov dl, ' '
			push edx
			inc ecx
			jmp filling_space_loop_in
		filling_space_loop_out:

		jmp number_splitting_out
	
	full_filling_zero_in:
	
	cmp byte [current_sign], 0x0
	je without_any_sign_v2
		inc ecx
	without_any_sign_v2:

	mov ebx, dword [width]
	filling_zero_loop_in:
	cmp ecx, ebx
	jae filling_zero_loop_out
		mov dl, '0'
		push edx
		inc ecx
		jmp filling_zero_loop_in
	filling_zero_loop_out:

	cmp byte [current_sign], 0x0
	je without_any_sign_v3
		mov dl, byte [current_sign]
		push edx
	without_any_sign_v3:

	jmp number_splitting_out
align_by_right_side_out:
cmp byte [current_sign], 0x0
je without_any_sign_v4
	mov dl, byte [current_sign]
	push edx
	inc ecx
without_any_sign_v4:
number_splitting_out:

;WRITE RESULT TO OUTPUT BUFFER
mov eax, [ebp+8]
mov ebx, ecx
output_write_loop_in:
cmp ecx, 0x0
je output_write_loop_out
	pop edx
	mov byte [eax], dl
	inc eax
	dec ecx
jmp output_write_loop_in
output_write_loop_out:

; Fill other space with space
mov ecx, ebx
full_filling_after_in:
mov ebx, dword [width]
cmp ecx, ebx
	jae full_filling_after_out
	mov byte [eax], ' '
	inc eax
	inc ecx
	jmp full_filling_after_in
full_filling_after_out:

; End of string
mov byte [eax], 0x0

jmp parse_error_out
parse_error_in:

parse_error_out:

popad
mov esp, ebp
pop ebp
ret

invertLeft:
pushad
	mov eax, [left+12]
	not eax
	mov [left+12], eax

	mov eax, [left+8]
	not eax
	mov [left+8], eax

	mov eax, [left+4]
	not eax
	mov [left+4], eax

	mov eax, [left]
	not eax
	mov [left], eax

	add dword [left], 1
	adc dword [left+4], 0
	adc dword [left+8], 0
	adc dword [left+12], 0
popad
ret

smartInvert:
pushad
	call testZero
	cmp edx, 0
	jne smartinvert_number_not_zero
		mov byte [flag_negate], 0
		jmp number_inverting_out
	smartinvert_number_not_zero:
	cmp dword [hex_length], 32
	jne number_inverting_out
		mov eax, dword [left+12]
		and eax, 0xF0000000
		cmp eax, 0x70000000
		jbe number_inverting_out
			call invertLeft
			cmp byte [flag_negate], 1
			jne change_negate_flag_plus
				mov byte [flag_negate], 0
				jmp number_inverting_out
			change_negate_flag_plus:
				mov byte [flag_negate], 1
	number_inverting_out:
popad
ret

; is left != 0
testZero:
push eax
	xor edx, edx
	mov eax, [left]
	or edx, eax
	mov eax, [left+4]
	or edx, eax
	mov eax, [left+8]
	or edx, eax
	mov eax, [left+12]
	or edx, eax
pop eax
ret

zeroLeft:
pushad
	mov dword [left],0
	mov dword [left+4],0
	mov dword [left+8],0
	mov dword [left+12],0
popad
ret

zeroRight:
pushad
	mov dword [right],0
	mov dword [right+4],0
	mov dword [right+8],0
	mov dword [right+12],0
popad
ret

;For [left] debug
testLeft:
pushad
	mov eax, [left]
	mov eax, [left+4]
	mov eax, [left+8]
	mov eax, [left+12]
popad
ret

;For [right] debug
testRight:
pushad
	mov eax, [right]
	mov eax, [right+4]
	mov eax, [right+8]
	mov eax, [right+12]
popad
ret

testFlags:
pushad
	xor eax, eax
	mov al, byte [current_sign]
	mov al, byte [flag_negate]
	mov al, byte [flag_plus]
	mov al, byte [flag_minus]
	mov al, byte [flag_space]
	mov al, byte [flag_zero]
	mov eax, dword [width]
popad
ret

summarize:
pushad
	mov eax, dword [left]
	add eax, dword [right]
	mov dword [left], eax

	mov eax, dword [left+4]
	adc eax, dword [right+4]
	mov dword [left+4], eax

	mov eax, dword [left+8]
	adc eax, dword [right+8]
	mov dword [left+8], eax

	mov eax, dword [left+12]
	adc eax, dword [right+12]
	mov dword [left+12], eax
popad
ret

defineSign:
pushad
	cmp byte [flag_negate], 1
	jne define_not_flag_negate
		mov byte [current_sign], '-'
		jmp defineSign_out
	define_not_flag_negate:
	cmp byte [flag_plus], 1
	jne define_not_flag_plus
		mov byte [current_sign], '+'
		jmp defineSign_out
	define_not_flag_plus:
	cmp byte [flag_space], 1
	jne defineSign_out
		mov byte [current_sign], ' '
	defineSign_out:
popad
ret

;divide [left] cache by 10 and return modulo in EDX
div10:
push ebp
mov ebp, esp
push eax
push ebx
mov ebx, 10

xor edx, edx
mov eax, dword [left+12]
div ebx
mov dword [left+12], eax

mov eax, dword [left+8]
div ebx
mov dword [left+8], eax

mov eax, dword [left+4]
div ebx
mov dword [left+4], eax

mov eax, dword [left]
div ebx
mov dword [left], eax

pop ebx
pop eax
mov esp, ebp
pop ebp
ret

;Multiply [right] cache by 16^m; m = cl
pow16:
push ebp
mov ebp, esp
sub esp, 0

;Let 16^p = 2^n -> n = 4 * p
mov ecx, dword [ebp+8]

;if (2^n: n>=64)
cmp cl, 64
jae greater_or_equals64_in
jmp greater_or_equals64_out
greater_or_equals64_in:
sub cl, 64
mov eax, dword [right]
mov dword [right+8], eax
mov dword [right], 0x0
mov eax, dword [right+4]
mov dword [right+12], eax
mov dword [right+4], 0x0
greater_or_equals64_out:

;if (2^n: n>=32)
cmp cl, 32
jae greater_or_equals32_in
jmp greater_or_equals32_out
greater_or_equals32_in:
sub cl, 32
mov eax, dword [right+8]
mov dword [right+12], eax
mov eax, dword [right+4]
mov dword [right+8], eax
mov eax, dword [right]
mov dword [right+4], eax
mov dword [right], 0x0
greater_or_equals32_out:

;if (2^n: n>=0)
cmp cl, 0
jae greater_or_equals0_in
jmp greater_or_equals0_out
greater_or_equals0_in:
mov eax, dword [right+12]
mov ebx, dword [right+8]
shld eax, ebx, cl
mov dword [right+8], ebx
mov dword [right+12], eax

mov eax, dword [right+8]
mov ebx, dword [right+4]
shld eax, ebx, cl
mov dword [right+4], ebx
mov dword [right+8], eax

mov eax, dword [right+4]
mov ebx, dword [right]
shld eax, ebx, cl
shl ebx, cl
mov dword [right], ebx
mov dword [right+4], eax

greater_or_equals0_out:

mov esp, ebp
pop ebp
ret