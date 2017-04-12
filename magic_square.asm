;	ALUNO: PEDRO HENRIQUE FROZI DE CASTRO E SOUZA
;	CARTAO: 161502
;
;	Itens que não foram implementados:
;	-	verificar se todas as somas sao iguais para finalizar
;	-	Apresentar linha e coluna do cursor
;	-   Setas para navegacao, para navegar entre posicoes vazias, ler as instrucoes ao lado do quadrado
;
;	Todos os outros itens foram feitos.
;
         assume cs:codigo,ds:dados,es:dados,ss:pilha

CR        EQU    0DH ; constante - codigo ASCII do caractere "carriage return"
LF        EQU    0AH ; constante - codigo ASCII do caractere "line feed"
ESC1      EQU    1BH ; caractere ASCII "Escape" (para terminar no DOS Box)
TAB		  EQU	 9H  ; caractere ASCII do TAB
DEL		  EQU	 7FH ; caractere ASCII do delete
BKSPC     EQU    08H ; constante - codigo ASCII do caractere "backspace"
; definicao do segmento de dados do programa
dados    	segment
; Mensagens estáticas
msg1     	db     'Iniciando . . . ',CR,LF,'Pressione qualquer tecla para continuar . . .',CR,LF,'$'
msg2     	db     'Posicoes vazias: $'
msg3     	db     'Tentativas:  [    ]$'
msg4     	db     'Posicao do cursor$'
msg5     	db     'Linha	 [    ]$'
msg6     	db     'Coluna	 [    ]$'
msg7    	db     'Somas das diagonais$'
msg8     	db     'Principal  [    ]$'
msg9    	db     'Secundaria [    ]$'

msg10    	db     '*** Instrucoes ***$'
msg11    	db     '     $'
msg12		db	   'Pressione TAB para$'
msg13		db	   'navegar, BKPC apagar$'
msg14		db	   'e ESC para sair!$'
;-------------------------------------------------
; Variáveis para a leitura do arquivo
nome      	  db 64 dup (?)
buffer        db 128 dup (?)
pede_nome     db 'Nome do arquivo: ','$'
em_branco     db '                 ','$'
erro          db 'Erro! Repita.    ','$'
msg_final     db 'Leu o Arquivo!   ','$'
handler       dw ?
buffer_ele    db 3   dup ('0')
vetorQM	      db 300 dup ('0')  ; Matriz do quadrado magico: 100 elementos de 3 digitos
;
; controle dos zeros
vetorPOS   	  db 200 dup ('0')  ; vetor de posicoes vazias (Cada elemento possui 5 posicoes: valida(1 ou 0),indice no vetorQM) . OBS.: tamanho 200 no caso de todos os elementos serem zeros
vetorDES	  dw 100 dup (0)    ; vetor que indica o endereco de onde esta o elemento zero
elemento_z    db '000'
zeros_encont  dw 0				; quantidade de elementos vazios encontrados no vetorQM
zeros_desl	  dw 0			    ; quantidade de deslocamentos 
;
tentativas    db '0000$'
posicoes_vaz  db 5 dup('0')
;--------------------------------------------------
;
um_ascii	  db '001'
digit	      db ?
contador1  	  db 0
col_lim_ini   db ?
col_lim_fim   db ?
; variaveis para a manipulacao da matriz
linha_tela	 db ?
coluna_tela  db ?
somator	  	 db 5 dup(?)
somator_aux  db 5 dup(?)
somator_zero db 4 dup('0')
;-------------------------------------------------
cabecalho 	db     'Sudoku Quadrado Magico ',02DH,' por Pedro Henrique Frozi ',02DH,' Cartao',03AH,' 161502',CR,LF,'$'
quad_fim   	db     '   *----*----*----*----*----*----*----*----*----*----*----*','$'
quad_l   	db     '   *----*----*----*----*----*----*----*----*----*----*----*',CR,LF,'$'
quad_col 	db     '   |    |    |    |    |    |    |    |    |    |    |    |',CR,LF,'$'


dados    	ends

; definicao do segmento de pilha do programa
;
pilha    segment stack ; permite inicializacao automatica de SS:SP
         dw     128 dup(?)
pilha    ends
         
; definicao do segmento de codigo do programa
codigo   segment

inicio:  ; CS e IP sao inicializados com este endereco
         mov    ax,dados ; inicializa DS
         mov    ds,ax    ; com endereco do segmento DADOS
         mov    es,ax    ; idem em ES
; fim da carga inicial dos registradores de segmento

; a partir daqui, as instrucoes especificas para cada programa

	
		 lea     dx,msg1
         call    echo1
         call    espera_tecla
		 call	 limpa_tela1
		 
		 ; imprimir mascaras de tela
		 mov     dh,1		  ; parametros do cursor
		 mov     dl,3
		 call pos_cursor
		 lea     dx,cabecalho	; cabeçalho
		 call	 echo1
		 call 	 desenha_qm1	; desenha quadrado magico
		 call	 numeracaoQM    ; numeraçoes (colunas)
		 call    numeracaoQM2   ; numeraçoes (linhas)
		 mov     dh,2		  
		 mov     dl,60
		 call pos_cursor
		 lea     dx,msg2
		 call	 echo1
		 mov     dh,3		  
		 mov     dl,60
		 call pos_cursor
		 lea     dx,msg3
		 call	 echo1
		 mov     dh,5		  
		 mov     dl,60
		 call pos_cursor
		 lea     dx,msg4
		 call	 echo1
		 mov     dh,6		  
		 mov     dl,62
		 call pos_cursor
		 lea     dx,msg5
		 call	 echo1
		 mov     dh,7		  
		 mov     dl,62
		 call pos_cursor
		 lea     dx,msg6
		 call	 echo1
		 mov     dh,9		  
		 mov     dl,60
		 call pos_cursor
		 lea     dx,msg7
		 call	 echo1
		 mov     dh,10		  
		 mov     dl,62
		 call pos_cursor
		 lea     dx,msg8
		 call	 echo1
		 mov     dh,11		  
		 mov     dl,62
		 call pos_cursor
		 lea     dx,msg9
		 call	 echo1
		 mov     dh,23  
		 mov     dl,54
		 call pos_cursor
		 lea     dx,msg11
		 call	 echo1
		 mov     dh,24  
		 mov     dl,54
		 call pos_cursor
		 lea     dx,msg11
		 call	 echo1
		 ; Fim da impressao das mascaras de tela

; Faz a leitura do arquivo

		 ; pede nome do arquivo
		 mov	col_lim_fim,73		; Limite superior do nome do arquivo
	de_novo: 
		 mov	dh,21
		 mov	dl,60
		 call	pos_cursor
		 lea    dx,pede_nome ; endereco da mensagem em DX
         call 	echo1
		 mov	dh,22
		 mov	dl,60
		 call	pos_cursor
		 call	get_position
		 mov	col_lim_ini,dl
	; le nome do arquivo
		 lea	dx,em_branco
		 call	echo1
		 mov	dh,22
		 mov	dl,60
		 call	pos_cursor
         lea    di, nome
		 jmp 	entrada
		 apaga1:
		 dec	di
		 mov	al,' '
		 call   escreve_cursor
	entrada: 
		 mov    ah,1
         int    21h		; le um caracter com eco
         cmp    al,CR   ; compara com carriage return
         je     continua
		 
		 call	get_position	; verifica se está nos limites
		 cmp	dl,col_lim_ini  ; verifica limite inferior
		 jge 	lim_superior
		 mov	dh,22
		 mov	dl,col_lim_ini
		 call	pos_cursor
		 jmp	entrada
		 lim_superior:
		 cmp	dl,col_lim_fim	; verifica limite superior
		 jne	esta_nos_lim
		 mov	dh,22
		 mov	dl,col_lim_fim
		 dec 	dl
		 call	pos_cursor
		 mov	al,' '
		 call   escreve_cursor
		 jmp	entrada
		 
		 esta_nos_lim:
		 cmp    al,8H   ; compara com backspace
		 je	    apaga1
         mov    [di],al ; coloca no buffer
         inc    di
         jmp    entrada
	continua: 
		 mov    byte ptr [di],0  ; forma string ASCIIZ com o nome do arquivo
         mov    dl,LF   ; escreve LF na tela
         mov    ah,2
         int    21h
		;
		; abre arquivo para leitura 
         mov    ah,3dh
         mov    al,0
         lea    dx,nome
         int 21h
         jnc    abriu_ok
		 mov	dh,22
		 mov	dl,60
		 call	pos_cursor
		 lea    dx,erro ; endereco da mensagem em DX
         call 	echo1
		 mov 	ah,8	 ; espera pela digitacao de uma tecla qualquer
         int 	21h
         jmp    de_novo
		;
	abriu_ok: 
		 mov handler,ax
		 lea di,vetorQM     ; carrega vetorQM em di
	    
 		 proximo_elemento:
		 lea si,buffer_ele  ; carrega buffer do elemento
		 mov ch,0
		 laco:
		 mov ah,3fh         ; le um caracter do arquivo
		 
		 push cx			; coloca ch na pilha (ch sera o contador do tamanho do buffer elemento)
		 mov bx,handler		; trecho para verificar se chegou no fim do arquivo
         mov cx,1
         lea dx,buffer
         int 21h
         cmp ax,cx
         jne fim_leitura   ; se chegou no fim do arquivo termina
		 pop cx
		 
         mov dl,buffer    
         cmp dl,2Ch		   ; codigo ascii da virgula
		 je  pula		   ; se for virgula n enter na tela
		 mov [si],dl       ; coloca caractere no buffer de elem (ele mais significativo)
		 inc si			   ; por ser o mais sig, incrementa o si
		 inc ch			   ; leu um caractere do elemento
		;
		 jne laco
		;
		 pula:			   ; Encontrou virgula
		 call coloca_vetor ; funcao que coloca elemento no vetor
         jmp proximo_elemento
		;
	fim_leitura:
		 pop cx
		 call coloca_vetor ; funcao que coloca elemento no vetor (ultimo elemento)
		 call imprime_vetorsz	; Imprime vetores sem os zeros
		 mov ah,3eh	 ; fecha arquivo
         mov bx,handler
         int 21h
		 ;
		 mov	dh,22
		 mov	dl,60
		 call	pos_cursor		 
         lea    dx,msg_final ; endereco da mensagem em DX
         call	echo1
; Fim da leitura do arquivo
		; imprime instrucoes
		 mov     dh,13  
		 mov     dl,60
		 call pos_cursor
		 lea     dx,msg10
		 call	 echo1
		 mov     dh,15  
		 mov     dl,60
		 call pos_cursor
		 lea     dx,msg12
		 call	 echo1
		 mov     dh,16  
		 mov     dl,60
		 call pos_cursor
		 lea     dx,msg13
		 call	 echo1
		 mov     dh,17  
		 mov     dl,60
		 call pos_cursor
		 lea     dx,msg14
		 call	 echo1
		 
		 mov		dh,2			; Imprime quatidade de posicoes vazias na tela
		 mov		dl,76
		 call		pos_cursor		 
         call		imprime_posvaz
		 
		 call	 	soma_linhas		; Atualiza todas as somas
		 
		; Faz leitura das teclas para interacao com o jogo 
		 lea		di,vetorDES			; vetor de endereços
		 lea		si,vetorPOS			; vetor de posicoes dos zeros
		 call		cursor
	
		 proximo_comando:
		 call	 	espera_tecla
		 cmp	 	al,ESC1			    ; Compara com ESC
		 je		 	fim
		 cmp	 	al,TAB			    ; Compara com TAB
		 je		 	navegar_frente
		 cmp	 	al,DEL			    ; Compara com DEL - Modifica cursor
		 je		 	apagarv
		 cmp	 	al,BKSPC		    ; Compara com BACKSPACE - Modifica cursor
		 je		 	apagarv
		 cmp		dl,col_lim_ini		; impede de digitar mais de 3 digitos
		 je			proximo_comando
		 cmp		dl,col_lim_fim		; impede de digitar mais de 3 digitos
		 je			proximo_comando
		 cmp		al,'0'				
		 jnge		proximo_comando
		 cmp		al,'9'
		 jnle		proximo_comando
		 ; eh um numero! - apresentar na tela e dec cursor
		 push		dx
		 mov 		dl,al
		 mov 		ah,2
         int 		21h
		 pop		dx
		 dec		dl
		 call		pos_cursor
		 
		 jmp		proximo_comando
		 apagarv:
		 inc		dl
		 cmp		dl,col_lim_ini		; impede de digitar mais de 3 digitos
		 jne		cont_apaga
		 dec		dl
		 jmp		proximo_comando
		 cont_apaga:
		 push		dx
		 call		pos_cursor
		 mov 		dl,' '
		 mov 		ah,2
         int 		21h
		 pop		dx
		 call		pos_cursor 
		 jmp		proximo_comando
		 
		 navegar_frente:
		 call		insere_vazio
		 call       somas
		 add		di,2			; eh uma palavra
		 call		limpar_cursor
		 add		si,2
		 mov     	dh,'0'
		 cmp		[si],dh
		 je			primeiro_denovo
		 call		cursor
		 jmp		proximo_comando
		 
		 primeiro_denovo:
		 call       somas
		 lea		di,vetorDES			; vetor de endereços
		 lea		si,vetorPOS
		 call		cursor
		 jmp		proximo_comando
fim:       

; retorno ao DOS com codigo de retorno 0 no AL (fim normal)
		 call 	 	limpa_tela1
         mov   		ax,4c00h           ; funcao retornar ao DOS no AH
         int    	21h                ; chamada do DOS

; Subrotinas do programa
zera_buffer		proc
		push	si
		push	di
		push	cx
		lea 	si, elemento_z
		lea 	di, buffer_ele
		mov 	cx, 3
		cld
		rep movsb
		pop		cx
		pop		di
		pop		si
		ret
zera_buffer		endp
; le elemento na tela, retorno em al
le_da_tela		proc
		mov			bh,0
		mov 		ah,8h
        int 		10h
		ret
le_da_tela		endp
; insere elemento digitado
insere_vazio			proc
		 push		si
		 push		di
		 push		dx
		 call		zera_buffer			; zera buffer do elemento
		 lea 		si,buffer_ele
		 
		 dec		col_lim_ini
		 mov		dl,col_lim_ini
		 call		pos_cursor
		 call		le_da_tela
		 cmp		al,' '
		 je			fim_insere_vazio
		 mov		[si+2],al
		 dec		col_lim_ini
		 mov		dl,col_lim_ini
		 call		pos_cursor
		 call		le_da_tela
		 cmp		al,' '
		 je			continua_insere_vazio
		 mov		[si+1],al
		 dec		col_lim_ini
		 mov		dl,col_lim_ini
		 call		pos_cursor
		 call		le_da_tela
		 cmp		al,' '
		 je			continua_insere_vazio
		 mov		[si],al
		 
		 continua_insere_vazio:
		 mov		si,[di]
		 lea		di,buffer_ele
		 xchg		si,di
		 mov 	cx, 3
		 cld
		 rep movsb
		 call		inc_tentativas	
		 mov		dh,3
		 mov		dl,74
		 call		pos_cursor
		 call		imprime_tent
		 
		 fim_insere_vazio:
		 pop		dx
		 pop		di
		 pop		si
		 ret
insere_vazio			endp
; coloca dados na pilha e calcula somas
somas					proc
		 push		dx
		 push		si
		 push		di
		 call	 	soma_linhas		; Atualiza todas as somas
		 pop		di
		 pop		si
		 pop		dx
		 call		pos_cursor
		 ret
somas					endp
; Limpa cursor
limpar_cursor			proc
		 mov     	dh,[si]
		 mov     	dl,[si+1]
		 dec		dl
		 call		pos_cursor
		 mov 		dl,' '
		 mov 		ah,2
         int 		21h
		 ret
limpar_cursor			endp
; imprime cursor
cursor			proc
		 mov     	dh,[si]
		 mov     	dl,[si+1]
		 dec		dl
		 call		pos_cursor
		 mov 		dl,'>'
		 mov 		ah,2
         int 		21h  
		 mov     	dh,[si]
		 mov     	dl,[si+1]
		 add		dl,2
		 call		pos_cursor		
		 ; estipula limites
		 mov 		col_lim_ini,dl
		 mov 		col_lim_fim,dl
		 inc		col_lim_ini
		 sub		col_lim_fim,3
		 ret
cursor			endp
; Imprime variavel de tentativas
imprime_tent	proc
		 push	di
		 push	cx
		 lea	di,tentativas
		 mov	cl,3
		 um_numerotent:			; Faz leitura por numero ( 3 digitos do vetor )
		 mov 	dl,[di+1]
		 cmp 	dl,30h	       		; codigo ascii do zero
		 je  	n_imprimetent	    ; se for zero nao imprime
		 imprimetent:
		 mov 	dl,[di+1]
		 mov 	ah,2
         int 	21h			; imprime do vetor
		 inc 	di
		 dec 	cl
		 jnz 	imprimetent
		 jmp	fim_imprimetent
		 n_imprimetent:
		 mov 	dl,' '
		 mov 	ah,2
         int 	21h
		 inc 	di
		 dec 	cl
		 jnz 	um_numerotent
		 fim_imprimetent:
		 pop cx
		 pop di
		 ret
imprime_tent  endp
; incrementa tentativas
inc_tentativas	proc
		 push		si
		 push		di
		 lea 		si,um_ascii     
		 lea		di,tentativas
		 call		soma_ascii3d
		 push		cx
		 lea 		si, somator
		 lea 		di, tentativas
		 mov	 	cx, 5
		 cld
		 rep movsb
		 pop		cx
		 pop		di
		 pop		si
		 ret
inc_tentativas	endp
; incrementa posicoes vazias
inc_pos_vazias	proc
		 push		si
		 push		di
		 lea 		si,um_ascii     
		 lea		di,posicoes_vaz
		 call		soma_ascii3d
		 push		cx
		 lea 		si, somator
		 lea 		di, posicoes_vaz
		 mov	 	cx, 5
		 cld
		 rep movsb
		 pop		cx
		 pop		di
		 pop		si
		 ret
inc_pos_vazias	endp

copiar_somator	proc
		push	si
		push	di
		push	cx
		lea 	si, somator
		lea 	di, somator_aux
		mov 	cx, 5
		cld
		rep movsb
		pop		cx
		pop		di
		pop		si
		ret
copiar_somator	endp
; Calcula todas as somas( linhas, colunas e diagonais)
soma_linhas		proc
		 ; somas das linhas
		 lea 		si,vetorQM     ; carrega vetorQM em di
		 mov		ch,3
	soma_l:
		 lea		di,somator_zero
		 call		soma_ascii3d
		 mov		contador1,9
		 laco_sum:
		 add		si,3
		 call    	copiar_somator
		 lea		di,somator_aux
		 call		soma_ascii3d
		 dec		contador1
		 jnz		laco_sum
		 mov		dh,ch
		 mov		dl,54
		 call		pos_cursor		 
         call		imprime_somasz
		 add		ch,2
		 add		si,3
		 cmp		ch,23
		 jne		soma_l
		 ; somas das colunas
		 lea 		si,vetorQM     ; carrega vetorQM em di
		 mov		ch,4
		 push		si
		 jmp		soma_col_cont
		 soma_col:
		 pop		si
		 add		si,3
		 push		si
		 soma_col_cont:
		 lea		di,somator_zero
		 call		soma_ascii3d
		 mov		contador1,9
		 laco_sum2:
		 add		si,30
		 call    	copiar_somator
		 lea		di,somator_aux
		 call		soma_ascii3d
		 dec		contador1
		 jnz		laco_sum2
		 mov		dh,23
		 mov		dl,ch
		 call		pos_cursor		 
         call		imprime_somasz
		 add		ch,5
		 cmp		ch,54
		 jne		soma_col
		 pop		si
		 ; soma da diagonal principal
		 lea 		si,vetorQM     ; carrega vetorQM em di
		 lea		di,somator_zero
		 call		soma_ascii3d
		 mov		contador1,9
		 laco_sum3:
		 add		si,33
		 call    	copiar_somator
		 lea		di,somator_aux
		 call		soma_ascii3d
		 dec		contador1
		 jnz		laco_sum3
		 mov		dh,10
		 mov		dl,74
		 call		pos_cursor		 
         call		imprime_somasz
		 ; soma da diagonal secundaria
		 lea 		si,vetorQM     ; carrega vetorQM em di
		 add		si,27
		 lea		di,somator_zero
		 call		soma_ascii3d
		 mov		contador1,9
		 laco_sum4:
		 add		si,27
		 call    	copiar_somator
		 lea		di,somator_aux
		 call		soma_ascii3d
		 dec		contador1
		 jnz		laco_sum4
		 mov		dh,11
		 mov		dl,74
		 call		pos_cursor		 
         call		imprime_somasz
		 ret
soma_linhas		endp
; imprime variavel somator sem os zeros
imprime_somasz	proc
		 push	di
		 push	cx
		 lea	di,somator
		 mov	cl,4
		 um_numero2:			   ; Faz leitura por numero ( 4 digitos do vetor )
		 mov 	dl,[di]
		 cmp 	dl,30h	       ; codigo ascii do zero
		 je  	n_imprimez2	   ; se for zero nao imprime
		 imprimez2:
		 mov 	dl,[di]
		 mov 	ah,2
         int 	21h			; imprime do vetor
		 inc 	di
		 dec 	cl
		 jnz 	imprimez2
		 jmp	fim_imprimesz
		 n_imprimez2:
		 mov 	dl,' '
		 mov 	ah,2
         int 	21h
		 inc 	di
		 dec 	cl
		 jnz 	um_numero2
		 fim_imprimesz:
		 pop cx
		 pop di
		 ret
imprime_somasz  endp
; Imprime variavel de posicoes vazias
imprime_posvaz	proc
		 push	di
		 push	cx
		 lea	di,posicoes_vaz
		 mov	cl,3
		 um_numeroposvaz:			; Faz leitura por numero ( 3 digitos do vetor )
		 mov 	dl,[di+1]
		 cmp 	dl,30h	       		; codigo ascii do zero
		 je  	n_imprimeposvaz	    ; se for zero nao imprime
		 imprimeposvaz:
		 mov 	dl,[di+1]
		 mov 	ah,2
         int 	21h			; imprime do vetor
		 inc 	di
		 dec 	cl
		 jnz 	imprimeposvaz
		 jmp	fim_imprimeposvaz
		 n_imprimeposvaz:
		 mov 	dl,' '
		 mov 	ah,2
         int 	21h
		 inc 	di
		 dec 	cl
		 jnz 	um_numeroposvaz
		 fim_imprimeposvaz:
		 pop cx
		 pop di
		 ret
imprime_posvaz  endp
; soma caracteres ascii de numero. valor1 apontado por di, com 4 digitos; valor 2 apontado por si, com tres digitos, resultado na variavel somator
soma_ascii3d	proc
		push	ax
		push	cx
		mov		al,0
		mov		ch,[si+2]
		add		ch,[di+3]
		mov		cl,[si+1]
		add		cl,[di+2]
		mov		ah,[si]
		add		ah,[di+1]
		push	si
		lea		si,somator
		mov		[si],al
		sub		ch,96
		sub		cl,96
		sub		ah,96
		cmp		ch,10
		jl	    dig2
		sub		ch,10
		add		cl,1
		dig2:
		cmp		cl,10
		jl	    dig3
		sub		cl,10
		add		ah,1
		dig3:
		cmp		ah,10
		jl	    para_somator
		sub		ah,10
		jmp		dig4
		dig4:
		inc		al
		mov		[si],al	
		para_somator:
		mov		al,[di]
		sub		al,48
		add		[si],al
		mov		[si+3],ch
		mov		[si+2],cl
		mov		[si+1],ah
		mov		al,48
		add		[si],al
		add		[si+3],al
		add		[si+2],al
		add		[si+1],al
		mov		al,'$'
		mov		[si+4],al
		pop		si
		pop		cx
		pop		ax
		ret
soma_ascii3d endp
limpa_tela1	  proc
		 mov     dh,24        ; linha 24
         mov     dl,79        ; coluna 79
         mov     ch,0         ; linha zero  
         mov     cl,0         ; coluna zero
         mov     bh,07h       ; atributo de preenchimento (fundo preto e letras cinzas)
         mov     al,0         ; numero de linhas (zero = toda a janela)
         mov     ah,6         ; scroll window up
         int     10h          ; chamada BIOS (video)
		 ret
limpa_tela1   endp

; parametros dh=linha, dl=coluna
; posiciona cursor (linha,coluna)=(dh,dl)
pos_cursor 	  proc
		 mov     bh,0		  ; numero da pagina (zero = primeira)
		 mov     ah,2         ; set cursor position
		 int     10h          ; chamada BIOS (video)
		 ret
pos_cursor	  endp

imprime_vetorsz	proc		; imprime vetor sem os zeros menos significativos
		 lea 	di,vetorQM     ; carrega vetorQM em di
		 mov 	linha_tela,1	
	 proxima_linha:				; inicializa linha inicial e coluna inicial
		 mov 	coluna_tela,0
		 add 	linha_tela,2
		 cmp 	linha_tela,23
		 je 	fim_imprz  		; Indica o fim da matriz do quadrado magico
	 lacoivsz:					; A cada elemento lido, reposiciona o cursor
		 add 	coluna_tela,5
		 cmp	coluna_tela,55
		 je		proxima_linha		
		 mov	dh,linha_tela
		 mov	dl,coluna_tela
		 call	pos_cursor	
		 mov 	contador1,3
		 call verifica_se_z	   ; verifica se eh elemento zero
		 um_numero:			   ; Faz leitura por numero ( 3 digitos do vetor )
		 mov 	dl,[di]
		 cmp 	dl,30h	       ; codigo ascii do zero
		 je  	n_imprimez	   ; se for zero nao imprime
		 imprimez:
		 mov 	dl,[di]
		 mov 	ah,2
         int 	21h			; imprime do vetor
		 inc 	di
		 dec 	contador1
		 jnz 	imprimez
		 jmp 	lacoivsz
		 n_imprimez:
		 mov 	dl,' '
		 mov 	ah,2
         int 	21h
		 inc 	di
		 dec 	contador1
		 jnz 	um_numero
		 jmp 	lacoivsz
	 fim_imprz:
		 ret
imprime_vetorsz	endp
		 
; Numeracao de linhas
numeracaoQM2  proc
; Inicia comandos para imprimir os titulos de linha do QM
		 mov 	 contador1,9	; inicializacoes da funcao
		 mov	 cl,3
		 mov	 ch,49
		 laco_numqm2:
		 mov     dh,cl			  ; parametros do cursor
		 mov     dl,1
		 call pos_cursor
		 mov	 dl,ch
		 mov 	 ah,2
         int 	 21h
		 inc	 ch
		 add	 cl,2
		 
		 dec	 contador1
		 jnz	 laco_numqm2
		 mov     dh,cl			  ; parametros do cursor
		 mov     dl,0
		 call pos_cursor
		 mov	 dl,49              ; imprime 1
		 mov 	 ah,2
         int 	 21h
		 mov	 dl,48				; imprime 0
		 mov 	 ah,2
         int 	 21h
		 add	 cl,2
		 mov     dh,cl			  ; parametros do cursor
		 mov     dl,0
		 call pos_cursor
		 mov	 dl,'S'              ; imprime S
		 mov 	 ah,2
         int 	 21h
		 mov	 dl,'C'				; imprime L
		 mov 	 ah,2
         int 	 21h
		 ; Fim dos comandos para imprimir os titulos de linha
		 ret
numeracaoQM2  endp
; Numeracao de colunas
numeracaoQM	  proc
		 ; Inicia comandos para imprimir os titulos de coluna do QM
		 mov 	 contador1,9	; inicializacoes da funcao
		 mov	 cl,6
		 mov	 ch,49
		 laco_numqm:
		 mov     dh,1			  ; parametros do cursor
		 mov     dl,cl
		 call pos_cursor
		 mov	 dl,ch
		 mov 	 ah,2
         int 	 21h
		 inc	 ch
		 add	 cl,5
		 
		 dec	 contador1
		 jnz	 laco_numqm
		 dec	 cl
		 mov     dh,1			  ; parametros do cursor
		 mov     dl,cl
		 call pos_cursor
		 mov	 dl,49              ; imprime 1
		 mov 	 ah,2
         int 	 21h
		 mov	 dl,48				; imprime 0
		 mov 	 ah,2
         int 	 21h
		 add	 cl,5
		 mov     dh,1			  ; parametros do cursor
		 mov     dl,cl
		 call pos_cursor
		 mov	 dl,'S'              ; imprime S
		 mov 	 ah,2
         int 	 21h
		 mov	 dl,'L'				; imprime L
		 mov 	 ah,2
         int 	 21h
		 ; Fim dos comandos para imprimir os titulos de coluna
		 ret
numeracaoQM   endp

desenha_qm1   proc
		 mov     dh,3		  ; parametros do cursor
		 mov     dl,0
		 
		 call pos_cursor
		 
		 mov	contador1,11
		 dqm1_laco1:
		 lea    dx,quad_l
		 call   echo1
		 lea    dx,quad_col
		 call   echo1
         dec	contador1
		 jnz	dqm1_laco1
		 lea    dx,quad_fim
		 call   echo1
		 ret
desenha_qm1   endp

echo1   proc
        ; assume que dx aponta para a mensagem
         mov    ah,9               ; funcao exibir mensagem no AH
         int    21h                ; chamada do DOS
         ret
echo1   endp
espera_tecla proc
         mov    ah,0               ; funcao esperar tecla no AH
         int    16h                ; chamada do DOS
         ret
espera_tecla endp
get_position	proc	 ; Verifica a posicao da tela em que esta o cursor. Resultado: dh=linha, dl=coluna
		 push	cx		 ; cx eh modificado na execução do comando de sistema, entao eh colocado na pilha
		 push	bx
		 mov	bh,0
		 mov	ah,3h
		 int	10h
		 pop	bx
		 pop	cx
		 ret
get_position	endp
escreve_cursor proc		; escreve em cima do cursor o caractere em al
		 push	bx
		 push	cx
		 mov	ah,0Ah
		 mov	bh,0
		 mov	cx,1
		 int	10h
		 pop	cx
		 pop	bx
		 ret
escreve_cursor endp
; Coloca variavel buffe_ele no vetorQM
coloca_vetor	proc
		 lea si,buffer_ele
		 mov bh,0
		 
		 cmp ch,3
		 je laco_tres_ele
		 cmp ch,2
		 je dois_ele
		 inc di			; tem apenas um elemento
		 dois_ele:
		 inc di
		 laco_tres_ele:
		 
		 mov bl,[si]
 		 mov [di],bl
		
		 inc si
		 inc di
		
		 inc bh
		 cmp bh,ch
		 jne laco_tres_ele
		 ;
		 ;
		 ret
coloca_vetor	endp
; Busca linha e coluna do elemento, armazena linha=ch e coluna=cl
lin_col_elem	proc
		
		ret
lin_col_elem	endp
; verifica se um elemento eh zero,se for armazena no vetorPOS a posicao do do elemento na tela (dh e dl) e a posicao no vetorQM
verifica_se_z	proc
		 push	si
		 push	di
		 push	cx
		 cld
		 lea    si, elemento_z
		 mov    cx, 3
         repe   cmpsb
		 jne	fim_vsz	   		; nao eh igual a zero
		 inc 	posicoes_vaz
		 lea	si,vetorPOS
		 add	si,zeros_encont
		 add	zeros_encont,2	; 2 em 2 digitos do vetor
		 mov	ch,linha_tela
		 mov	cl,coluna_tela
		 mov	[si],ch 		; Primeiro digito valida o elemento(1)
		 mov	[si+1],cl		; coloca o indice do elemento no segundo digito do vetor de posicoes
		 lea	si,vetorDES
		 add	si,zeros_desl
		 sub	di,3
		 mov	[si],di
		 add	zeros_desl,2	; eh uma palavra
		 call	inc_pos_vazias
		fim_vsz:
		pop		cx
		pop		di
		pop		si
		ret
verifica_se_z	endp
codigo   ends

; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
         end    inicio   ; para o programa iniciar em "inicio" quando for executado
