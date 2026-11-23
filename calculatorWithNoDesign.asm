TITLE SIMPLE_CALCULATOR
.model small
.386                                    ; lets us use 32-bit boxes (EAX, EBX...) for BIG numbers
.stack 100h

.data
    menu        db 13,10,13,10,'===== CALCULATOR =====',13,10
                db '1 - Addition',13,10
                db '2 - Subtraction',13,10
                db '3 - Multiplication',13,10
                db '4 - Division',13,10
                db '5 - Exit',13,10
                db 'Select (1-5): $'

    p1          db 13,10,'Enter first number: $'
    p2          db 13,10,'Enter second number: $'
    result_msg  db 13,10,'Result: $'
    quo_msg     db 13,10,'Quotient: $'
    rem_msg     db 13,10,'Remainder: $'
    zero_msg    db 13,10,'Error: cannot divide by zero!$'
    bad_msg     db 13,10,'Invalid choice, try again.$'

    num1        dd 0                    ; dd = 32-bit box (can hold up to 4,294,967,295)
    num2        dd 0

.code
main PROC
    mov ax, @data                       ; find our data area
    mov ds, ax                          ; tell the program where it is

start:                                  ; the menu comes back here after every calculation
    mov dx, offset menu                 ; point to the menu text
    mov ah, 09h                         ; job 09h = print text
    int 21h                             ; show the menu

    mov ah, 01h                         ; job 01h = wait for one key
    int 21h                             ; the key you press goes into AL

    cmp al, '1'                         ; did you press 1?
    je do_add                           ; yes -> go to addition
    cmp al, '2'                         ; did you press 2?
    je do_sub                           ; yes -> go to subtraction
    cmp al, '3'                         ; did you press 3?
    je do_mul                           ; yes -> go to multiplication
    cmp al, '4'                         ; did you press 4?
    je do_div                           ; yes -> go to division
    cmp al, '5'                         ; did you press 5?
    je exit_program                     ; yes -> close the program

    mov dx, offset bad_msg              ; any other key = wrong choice
    mov ah, 09h
    int 21h                             ; show "Invalid choice"
    jmp start                           ; show the menu again

; ---------------- ADDITION ----------------
do_add:
    call ask_numbers                    ; ask for the 2 numbers
    mov dx, offset result_msg
    mov ah, 09h
    int 21h                             ; print "Result: " FIRST (printing text changes EAX!)
    mov eax, num1                       ; now put first number in EAX
    add eax, num2                       ; add the second number
    call print_number                   ; print the answer (it is in EAX)
    jmp start                           ; back to the menu

; ---------------- SUBTRACTION ----------------
do_sub:
    call ask_numbers                    ; ask for the 2 numbers
    mov dx, offset result_msg
    mov ah, 09h
    int 21h                             ; print "Result: "

    mov eax, num1                       ; put first number in EAX
    cmp eax, num2                       ; is the first smaller than the second?
    jb negative                         ; yes -> the answer is below zero

    sub eax, num2                       ; first - second
    call print_number                   ; print the answer
    jmp start                           ; back to the menu

negative:
    mov dl, '-'                         ; print a minus sign first
    mov ah, 02h                         ; job 02h = print one character
    int 21h
    mov eax, num2                       ; then do second - first
    sub eax, num1                       ; (so the number stays positive)
    call print_number                   ; print it
    jmp start                           ; back to the menu

; ---------------- MULTIPLICATION ----------------
do_mul:
    call ask_numbers                    ; ask for the 2 numbers
    mov dx, offset result_msg
    mov ah, 09h
    int 21h                             ; print "Result: " FIRST (printing text changes EAX!)
    mov eax, num1                       ; now put first number in EAX
    mul num2                            ; EAX x second number (answer stays in EAX)
    call print_number                   ; print the answer
    jmp start                           ; back to the menu

; ---------------- DIVISION ----------------
do_div:
    call ask_numbers                    ; ask for the 2 numbers
    cmp num2, 0                         ; is the second number 0?
    je divide_zero                      ; yes -> show an error

    mov dx, offset quo_msg
    mov ah, 09h
    int 21h                             ; print "Quotient: " FIRST (printing text changes EAX!)

    mov eax, num1                       ; now put first number in EAX
    xor edx, edx                        ; clear EDX (division needs it empty)
    div num2                            ; EAX = quotient (answer), EDX = remainder (leftover)
    mov ebx, edx                        ; keep the remainder safe in EBX
    call print_number                   ; print the quotient (still in EAX)

    mov dx, offset rem_msg
    mov ah, 09h
    int 21h                             ; print "Remainder: "
    mov eax, ebx                        ; bring the remainder back into EAX
    call print_number                   ; print the remainder
    jmp start                           ; back to the menu

divide_zero:
    mov dx, offset zero_msg
    mov ah, 09h
    int 21h                             ; print the error
    jmp start                           ; back to the menu

exit_program:
    mov ah, 4ch                         ; job 4Ch = end the program
    int 21h
main ENDP

; ---------------- HELPERS ----------------

ask_numbers PROC                        ; asks for both numbers and saves them
    mov dx, offset p1
    mov ah, 09h
    int 21h                             ; print "Enter first number: "
    call get_number                     ; read the number (comes back in EAX)
    mov num1, eax                       ; save it

    mov dx, offset p2
    mov ah, 09h
    int 21h                             ; print "Enter second number: "
    call get_number                     ; read the number
    mov num2, eax                       ; save it
    ret                                 ; go back
ask_numbers ENDP

get_number PROC                         ; reads typed digits and builds a real number
    push ebx                            ; save the boxes we will use
    push ecx
    push edx
    push esi

    xor ebx, ebx                        ; EBX = 0, the number we are building

read_digit:
    mov ah, 01h                         ; wait for one key
    int 21h

    cmp al, 13                          ; 13 = Enter key
    je done_number                      ; Enter pressed -> finished

    cmp al, '0'                         ; lower than '0'?
    jb read_digit                       ; not a digit, ignore it
    cmp al, '9'                         ; higher than '9'?
    ja read_digit                       ; not a digit, ignore it

    sub al, '0'                         ; turn the letter '7' into the number 7
    movzx ecx, al                       ; copy the digit into ECX
    mov eax, ebx                        ; take the number built so far
    mov esi, 10
    mul esi                             ; multiply it by 10 (12 becomes 120)
    add eax, ecx                        ; add the new digit (120 + 3 = 123)
    mov ebx, eax                        ; save it
    jmp read_digit                      ; read the next key

done_number:
    mov eax, ebx                        ; give back the finished number in EAX
    pop esi                             ; put back the saved boxes
    pop edx
    pop ecx
    pop ebx
    ret
get_number ENDP

print_number PROC                       ; prints the number that is in EAX
    push eax                            ; save the boxes we will use
    push ebx
    push ecx
    push edx

    xor ecx, ecx                        ; CX counts how many digits there are
    mov ebx, 10                         ; we divide by 10 each time

divide_loop:
    xor edx, edx                        ; clear EDX before dividing
    div ebx                             ; EAX / 10 -> EDX = the last digit
    push edx                            ; store the digit (they come out backwards)
    inc cx                              ; count one more digit
    cmp eax, 0                          ; anything left?
    jne divide_loop                     ; yes -> repeat

print_loop:
    pop edx                             ; take a digit out (now in the right order)
    add dl, '0'                         ; turn the number 7 into the letter '7'
    mov ah, 02h                         ; job 02h = print one character
    int 21h
    loop print_loop                     ; repeat once for each digit

    pop edx                             ; put back the saved boxes
    pop ecx
    pop ebx
    pop eax
    ret
print_number ENDP

END main