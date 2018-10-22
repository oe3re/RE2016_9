;re_projekat.asm

INCLUDE Irvine32.inc
INCLUDE macros.inc
BUFFER_SIZE = 500000

.data 

buffer BYTE BUFFER_SIZE DUP(?)                 ;ulazni bafer
color BYTE ?                                   ;bajt za boju kvadrata
bytesInFile DWORD ?                            ;broj ucitanih bajtova
x0_cord BYTE ?                                 ;x0 i y0 su koordinate gornjeg desnog ugla kvadrata 
y0_cord BYTE ?                                 
x1_cord BYTE ?                                 ;x1 i y1 su koordinate donjeg desnog ugla kvadrata
y1_cord BYTE ?
filename BYTE 80 DUP(0)                        ;ime ulaznog fajla
fileHandle HANDLE ?                            
cursorInfo CONSOLE_CURSOR_INFO <>
outHandle DWORD ?

.code

;PROCEDURA KOJA PRETVARA ASCII U INT

convert_ascii_to_int PROC
mov ecx,    0                             ;u ecx stavljamo 0
mov eax,    0							  ;u ecx stavljamo 0
nextDigit:
    mov bl, [esi]						  ;u bl stavljamo ono na sta ukazuje ESI
    cmp bl, '0'							  ;proveravamo da li je cifra u opsegu 0-9
    jl  exitProc
    cmp bl, '9'
    jg  exitProc
    add bl, -30h						   ;oduzimamo 30h 
    imul    eax,    10                     ;mnozimo eax sa 10
    add eax,    ebx						   ;na eax dodajemo novoprocitanu cifru

    inc ecx								   ;inkrementiramo ecx
    inc esi								   ;inkrementiramo esi

    jmp nextDigit						   ;ucitavamo sledecu cifru (dakle ovo ce vec da ucita 20h) da utvrdi da to nije broj i da izadje)

exitProc: 
    ret
convert_ascii_to_int ENDP

main proc
; Korisnik upisuje ime fajla sa standardnog ulaza
	mWrite "Unesite ime fajla: "
	mov edx, OFFSET filename
	mov ecx, SIZEOF filename
	call ReadString

; Otvaranje fajla
	mov edx, OFFSET filename
	call OpenInputFile
	mov fileHandle, eax

; Provera gresaka
	cmp eax, INVALID_HANDLE_VALUE							;da li je bilo gresaka pri otvaranju?
	jne file_opened											;ako jeste - sledeca instrukcija
	mWrite "Greska: Nije moguce otvoriti fajl!"
	call WriteWindowsMsg
	jmp quit												;prekid rada jer postoji greska

file_opened:
;Ucitavanje fajla u bafer
	mov edx, OFFSET buffer
	mov ecx, BUFFER_SIZE
	call ReadFromFile
	mov bytesInFile, eax                                    ;cuvamo broj procitanih bajtova
	jnc check_buffer_size									;proveravamo da li je doslo do greske pri citanju
	mWrite "Greska: Doslo je do greske pri citanju fajla!"	;ako jeste - prikazuje se poruka na ekranu 
	call WriteWindowsMsg
	jmp close_file

check_buffer_size:
	cmp eax, BUFFER_SIZE 	                                                                       ;proveravamo se da li je ulazni bafer dovoljno veliki
	jb drawing								                                                       ;ako jeste - lets draw!
	mWrite "Greska: Broj karaktera u fajlu prevazilazi velicinu bafera! Ucitajte manji fajl"       ;ukoliko nije ispisuje se greska
	call WriteWindowsMsg
	jmp quit
	
;zatvorimo file
close_file:
	mov eax, fileHandle
	call CloseFile

;lets draw!
drawing:
	
	mov eax,0
	mov ebx,0
	mov ecx,0
	mov edx,0
	
	;brisanje sadrzaja konzole i podesavanja kursora
	call Clrscr
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax
	INVOKE GetConsoleCursorInfo, outHandle, ADDR cursorInfo
	mov cursorInfo.bVisible,0
	INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo

	mov eax,0

	mov esi, OFFSET buffer ;u ESI se stavlja adresa buffer-a

	ReadOneLine:                            ;citamo koordinate jednog kvadrata

		call convert_ascii_to_int           ;ucitavamo koordinate

		cmp bl, ' '                         ;svaki put kada se skoci na ReadLine ocekuje se da je u bl cifra osim ako je kraj falja
		jz ifNotEnd                         ;ukoliko nije kraj fajla nakon izlaska iz procedure convert_ascii_to_int u bl ce se nalaziti
		jmp quit                            ;' ', u suprotnom  smo dosli do kraja i treba zavrsiti program
		
		
		ifNotEnd:

			mov x0_cord, al                ;ucitavamo x0
			inc esi
			 
			call convert_ascii_to_int      ;ucitavamo y0
			mov y0_cord, al
			inc esi

			call convert_ascii_to_int      ;ucitavamo x1
			mov x1_cord, al
			inc esi

			call convert_ascii_to_int      ;ucitavamo y1
			mov y1_cord, al
			inc esi

			call convert_ascii_to_int      ;ucitavamo boju
			mov color, al
			inc esi
	
			mov bl, [esi]                  ; u bl ucitavamo ono sto je na adresi na koju ukazuje esi
			cmp bl, ' '                    ; uporedjuje bl sa razmakom
			jz ReadSpecialCaracters
			cmp bl, 0ah
			jz ReadSpecialCaracters
			cmp bl, 0dh                    ;uporedjuje bl sa 0ah
			jz ReadSpecialCaracters

	ReadSpecialCaracters:
		inc esi                       ;posto je u bl ili ' ' ili \r ili \n inkrementiramo esi
		mov bl, [esi]                 ;pomeramo u bl, [esi]

		cmp bl, 0ah                   ;proveravamo da li je \n
		jz ReadSpecialCaracters

		cmp bl, 0dh                   ;proveravamo da li je \r
		jz ReadSpecialCaracters

		cmp bl, ' '                   ;proveravamo da li je ' '
		jz ReadSpecialCaracters

		jmp DrawRect                  ;kada smo ucitali liniju, idemo na iscrtavanje

	DrawRect:
		
		mov dh, y0_cord               ;u dh stavljamo y cursor position

		DrawVertical:                 ;iscrtavanje po vertikali
			
			mov eax, 0
			mov al, color      ;postavljamo boju kvadrata koji treba iscrtati
			call SetTextColor

			mov eax, 0
			mov dl, x0_cord               ;u dl stavljamo x cursor position
			mov al, y1_cord
			sub al, y0_cord
			add al, 1
			mov ecx, eax                  ;u brojac stavljamo duzinu stanice po x osi (jer je ista kao po y osi)
			mov al, 0DBh                  ;solid-block

			DrawHorizontal:               ;iscrtavamo po x osi ecx puta

				call Gotoxy       
				call WriteChar
				inc dl
				loop DrawHorizontal
			
			cmp dh, y1_cord
			jz ReadOneLine

			inc dh
			jmp DrawVertical

quit:                                                           ;zavrsavamo program
	mov al, 0ah													;menjamo broju teksta na belu 
	mov eax, 15
	call SetTextColor
	call ReadChar                                               ;ceka na karakter sa ulaza da bi zavrsio izvrsavanje
	exit

main endp
end main