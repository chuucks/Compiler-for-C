%{
/*
Compiladores. Laura Sandoval. 2015-2
Analizador Sintáctico (Parser)
3 de Marzo de 2015
Salazar Cárdenas Carlos Eduardo
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *tokens;
FILE *atomos; //Apuntador a archivo en donde se almacenara la cadena de atomos
FILE *simbolos;
FILE *cadenas;
FILE *errores;
FILE *aux;

int cont_cad=0, cont_iden=0, cont_err_lex=0, bandera=0, valida=0;
int cont_err_sint=0, apuntador=0; //El contador de errores sintácticos es para llevar el orden de los errores, la variable apuntador llevara el control de los caracteres en la cadena de atomos
char atomo, caracter; //La variable atomo guarda el valor del caracter para el atomo en cuestion, y la variable caracter guarda las lecturas de la cadena de atomos

char *tokens_palabras_reservadas[9] = {"char", "double", "else", "float", "for", "if", "int", "while", "return"};
char *tokens_operadores_asignacion[10] = {"=", "+=", "-=", "*=", "/=", "|=", "%=", "<<=", ">>=", "&="};
char *tokens_operadores_aritmeticos[5] = {"+", "-", "*", "/", "%"};
char *tokes_operadores_relacionales[6] = {"<", ">", "<=", ">=", "==", "!="};
char *tokens_operadores_logicos[2] = {"&&", "||"};

//A continuacion se define en arreglos el token para cada uno de los atomos
char atomos_palabras_reservadas[9] = {'c', 'd', 'l', 'r', 'f', 'i', 'e', 'w', 'v'};
char atomos_operadores_asignacion[10] = {'=', 'k', 'm', 'p', 'q', 'u', 'x', 'y', '&'};
char atomos_operadores_aritmeticos[5] = {'+', '-', '*', '/', '%'};
char atomos_operadores_relacionales[6] = {'<', '>', 'b', 'g', 'j', '!'};
char fin_cadena = '$';

%}
pal_res ("char"|"double"|"else"|"float"|"for"|"if"|"int"|"while"|"return")
identif ([a-z]|[A-Z]|\_)+([0-9]|[a-z]|[A-Z]|\_)*
car_esp \,|\;|\(|\)|\{|\}|\@
cns_cad \".*\" 
op_asig \=|"+="|"-="|"*="|"/="|"*="|"|="|"%="|"<<="|">>="|"&="
op_arit \+|\-|\*|\/|\%
op_rel  \<|\>|"<="|">="|"=="|"!="
op_log  &&|"||"
cns_dec (0|([1-9]+[0-9]*))
cns_flo ((\.[0-9]+)|([1-9][0-9]*\.[0-9]+))
cns_oct 0[0-7]+
cns_hex 0(x|X)([0-9]|[a-f]|[A-F])+
coment  ("/*"(.|\n)*"*/")|("//".*)
espacio (\n|\t|" ")

%%
{pal_res} {int indice = buscaIndices(0);
		   fprintf(tokens,"0, %i\n",indice);
		   fprintf(atomos,"%c",atomo);}

{identif} {int indice = ordenaIdentificadores(yytext);
		   if(bandera)
		   	fprintf(simbolos,"%i, %s\n", indice, yytext);
		   fprintf(tokens,"1, %i\n",indice);
		   fprintf(atomos,"a");}

{car_esp} {fprintf(tokens,"2, %s\n",yytext);
		   fprintf(atomos,"%s", yytext);}

{cns_cad} {int indice = buscaIndices(3);
		   fprintf(cadenas,"%i, %s\n", indice, yytext);
		   fprintf(tokens,"3, %i\n", indice);
		   fprintf(atomos, "s");}

{op_asig} {int indice = buscaIndices(4);
		   fprintf(tokens,"4, %i\n",indice);		   
		   fprintf(atomos,"%c",atomo);}

{op_arit} {int indice = buscaIndices(5);
		   fprintf(tokens,"5, %i\n",indice);		  
		   fprintf(atomos,"%c",atomo);}

{op_rel} {int indice = buscaIndices(6);
		  fprintf(tokens,"6, %i\n",indice);		  
		  fprintf(atomos,"%c",atomo);}

{op_log} {int indice = buscaIndices(7);
		  fprintf(tokens,"7, %i\n",indice);}

{cns_dec} {if(!strcmp(yytext, "0"))
		   	valida = 1;
		   else
		   	fprintf(tokens,"9, %s\n", yytext);		   	
		   fprintf(atomos,"n");}

{cns_flo} {if(valida == 1 && strcspn(yytext, ".") == 0)
		   	fprintf(tokens,"11, 0%s\n", yytext);
		   else if(valida==1){
		   	fprintf(tokens,"9, 0\n");
		   	fprintf(tokens,"11, %s\n", yytext);
		   }else
		    fprintf(tokens,"11, %s\n", yytext);
		   valida = 0;
		   fprintf(atomos,"z");}

{cns_oct} {if(valida == 1)
		  	fprintf(tokens,"9, 0\n");
		   fprintf(tokens,"8, %s\n", yytext);
		   valida = 0;
		   fprintf(atomos,"o");}

{cns_hex} {if(valida == 1)
		  	fprintf(tokens,"9, 0\n");
		   int indice = buscaIndices(10);
		   fprintf(tokens,"10, %s\n", yytext);
		   valida = 0;
		   fprintf(atomos,"h");}

{coment} {if(valida == 1)
		  	fprintf(tokens,"9, 0\n");
		  valida = 0;}

{espacio} {if(valida == 1)
		  	fprintf(tokens,"9, 0\n");
		   valida = 0;}

. {if(strlen(yytext) == 1)
		   	fprintf(errores,"Error léxico #%i\n\tEl caracter '%s' no se reconoce\n", cont_err_lex, yytext);
		   else
		   	fprintf(errores,"Error léxico #%i\n\tLa cadena '%s' no se reconoce\n", cont_err_lex, yytext);
  			cont_err_lex ++;
  			valida = 0;}
%%
int main(int argc, char *argv[]){	
	
	char buffer[100];
	
	if(argc == 2){		
		yyin = fopen(argv[1], "r");			
		if(yyin != 0){
			tokens = fopen("Tokens.txt","w");			
			atomos = fopen("Atomos.txt","w+"); //Apuntador al archivo de la cadena de atomos
			simbolos = fopen("Tabla_simbolos.txt","w");
			cadenas = fopen("Tabla_cadenas.txt", "w");
			errores = fopen("Errores.txt", "w");
			aux = fopen("Auxiliar.txt", "w+");

			yylex();
			fprintf(atomos, "%c", fin_cadena); //Se agrega el fin de cadena a la cadena de atomos

			printf("-Analisis lexico:\n");
			if(cont_err_lex == 0){
				fseek(atomos, 0, SEEK_SET);
				
				while((fscanf(atomos, "%s\n", buffer)) == 1){					
					printf("Archivo lexicamente correcto.\nCadena de atomos: %s\n",buffer);
				}

				fclose(tokens);
				fclose(simbolos);
				fclose(cadenas);
				fclose(aux);
				parser(); //Se hace una llamada a la función del analizis sintáctico
				acepta();
			}else{
				printf("Archivo lexicamente incorrecto.\nEl archivo tiene %i error(es) lexico(s)\n", cont_err_lex);
				fclose(tokens);
				fclose(simbolos);
				fclose(cadenas);
				fclose(aux);
				fclose(atomos);
			}
			
		}else
		printf("Error: El archivo no existe\n");
	}else
		printf("Error: Ingrese el nombre de 1 archivo\n");

	return 0;
}

int buscaIndices(int a){	
	
	int i;
	if(valida == 1)
		fprintf(tokens,"9, 0\n");
	valida = 0;

	switch(a){

		case 0:			
			for(i=0; i<9; i++){
				if(!strcmp(yytext, tokens_palabras_reservadas[i])){
					atomo = atomos_palabras_reservadas[i];
					return i;
				}
			}
		break;

		case 3:						
			cont_cad ++;
			return cont_cad-1;
		break;

		case 4:
			for(i=0; i<10; i++){
				if(!strcmp(yytext, tokens_operadores_asignacion[i])){
					atomo = atomos_operadores_asignacion[i];
					return i;				
				}
			}
		break;

		case 5:
			for(i=0; i<5; i++){
				if(!strcmp(yytext, tokens_operadores_aritmeticos[i])){
					atomo = atomos_operadores_aritmeticos[i];
					return i;
				}
			}
		break;

		case 6:
			for(i=0; i<6; i++){
				if(!strcmp(yytext, tokes_operadores_relacionales[i])){
					atomo = atomos_operadores_relacionales[i];
					return i;				
				}
			}
		break;
	}		
}

int ordenaIdentificadores(char *cadena){	

	int i=0;
	char buffer[100];

	if(valida == 1)
		fprintf(tokens,"9, 0\n");
	valida = 0;

	bandera = 0; 
	
	fseek(aux, 0, SEEK_SET);
	while(fscanf(aux, "%s\n", buffer) == 1){
		if(!strcmp(cadena, buffer))
			return i;
		i++;
	}

	fprintf(aux, "%s\n", cadena);
	cont_iden ++;
	bandera = 1;
	return cont_iden-1;		
}

//Función que inicia el analizis sintáctico
parser(){
	fseek(atomos, 0, SEEK_SET); //Se regresa el apuntador al archivo de la cadena de atomos al principio
	printf("\n-Analisis sintáctico:\n");
	prog(); //Se llama a la primera producción de la gramática
}

//Función que hace la lectura de la cadena de atomos
getchar(){
	caracter = fgetc(atomos);
	apuntador ++;
	if(caracter == '$') //Si se llego al fin de la cadena se verifica si la cadena es aceptada
		acepta();
}

//Función que regresa el apuntador un caracter en la cadena de atomo, en caso de que aun no tenga que salir de la pila
setchar(){
	apuntador --;
	fseek(atomos, apuntador, SEEK_SET);	
}

//Se evalua si la cadena tiene errores al llegar al fin de cadena, se muestra el resultado en pantalla
acepta(){
	if(cont_err_sint == 0)
		printf("La cadena de atomos es aceptada\n");
	else
		printf("La cadena de atomos es rechazada, tiene %i error(es)\n", cont_err_sint);
	fclose(atomos);
	exit(1);
}

//Se agregan los errores al archivo de errores con un formato adecuado
error(char a){	
	fprintf(errores,"Error sintáctico: #%i\n\tSe esperaba '%c', antes de '%c'\n", cont_err_sint, a, caracter);
	cont_err_sint++;
}

//Se agregan los errores al archivo de errores con un formato adecuados
error2(int a){

	char c = '%';

	switch(a){
		case 1:
			fprintf(errores,"Error sintáctico: #%i\n\tSe esperaba 'c', 'd', 'r', o 'e', antes de '%c'\n", cont_err_sint, caracter);
		break;

		case 2:
			fprintf(errores,"Error sintáctico: #%i\n\tSe esperaba ',' o ';', antes de '%c'\n", cont_err_sint, caracter);
		break;

		case 3:
			fprintf(errores,"Error sintáctico: #%i\n\tSe esperaba ')' o ';', antes de '%c'\n", cont_err_sint, caracter);
		break;

		case 4:
			fprintf(errores,"Error sintáctico: #%i\n\tSe esperaba '@', 'a', 'o', 'n', 'h', 'z', 's' o '(', antes de '%c'\n", cont_err_sint, caracter);
		break;

		case 5:
			fprintf(errores,"Error sintáctico: #%i\n\tSe esperaba '<', '>', 'b', 'g', 'j' o '!', antes de '%c'\n", cont_err_sint, caracter);
		break;

		case 6:
			fprintf(errores,"Error sintáctico: #%i\n\tSe esperaba '=', 'k', 'm', 'p', 'q', 't', 'u', 'x', 'y' o '&' antes de '%c'\n", cont_err_sint, caracter);
		break;
	}
	cont_err_sint++;
}

/*Las siguientes funciones definen la gramatica:*/

prog(){		
	fun();
	masfun();	
}

fun(){	
	tipo();
	getchar();
	if(caracter == 'a'){
		getchar();
		if(caracter == '('){
			listaparam();
			getchar();
			if(caracter == ')')
				cuerpo();
			else
				error(')');
		}else
			error('(');
	}else
		error('a');
}

dec(){	
	tipo();
	getchar();
	if(caracter == 'a')
		listaId();
	else		
		error('a');
}

tipo(){	
	getchar();
	if(caracter == 'c' || caracter == 'd' || caracter == 'r' || caracter == 'e'){
		
	}else		
		error2(1);	
}

listaId(){
	getchar();
	if(caracter == ','){
		getchar();
		if(caracter == 'a')
			listaId();
		else			
			error('a');		
	}else if(caracter == ';'){

	}else
		error2(2);
}

masfun(){
	getchar();
	if(caracter == '$')
		setchar();
	else if(caracter == 'c' || caracter == 'd' || caracter == 'r' || caracter == 'e'){
		setchar();
		fun();
		masfun();
	}else{
		setchar();		
	}
}

listaparam(dd){
	getchar();
	if(caracter == ')'){
		setchar();
	}else if(caracter == 'c' || caracter == 'd' || caracter == 'r' || caracter == 'e'){
		setchar();
		tipo();
		getchar();
		if(caracter == 'a')
			masparam();		
		else
			error('a');
	}else{
		setchar();
	}
}

masparam(){
	getchar();
	if(caracter == ')'){
		setchar();
	}else if(caracter == ','){
		setchar();
		getchar();
		if(caracter == ','){
			tipo();
			getchar();
			if(caracter == 'a')
				masparam();
			else
				error('a');
		}else
			error(',');
	}else{
		error2(3);
	}
}

cuerpo(){
	getchar();
	if(caracter == '{'){
		listadec();
		listaProp();
		getchar();
		if(caracter == '}'){

		}else
			error('}');
	}else
		error('{');
}

listadec(){
	getchar();
	if(caracter =='w' || caracter == 'i' || caracter == 'f' || caracter == 'v' || caracter == 'a' || caracter == '@'){
		setchar();
	}else if(caracter == 'c' || caracter == 'd' || caracter == 'r' || caracter == 'e'){
		setchar();
		dec();
		listadec();	
	}else{
		setchar();
	}
}

listaProp(){
	getchar();
	if(caracter == '}'){
		setchar();
	}else if(caracter =='w' || caracter == 'i' || caracter == 'f' || caracter == 'v' || caracter == 'a' || caracter == '@'){
		setchar();
		prop();
		listaProp();
	}else{
		setchar();
	}
}

prop(){
	getchar();
	if(caracter == 'w'){
		setchar();
		fun_while();
	}else if(caracter == 'i'){
		setchar();
		fun_if();
	}else if(caracter == 'f'){
		setchar();
		fun_for();
	}else if(caracter == 'v'){
		setchar();
		fun_return();
	}else if(caracter == 'a'){
		setchar();
		asig();
	}else if(caracter == '@'){
		setchar();
		llamada();
	}
	else		
		setchar();
}

fun_while(){	
	getchar();
	if(caracter == 'w'){
		getchar();
		if(caracter == '('){
			expRel();
			getchar();
			if(caracter == ')')
				opLoop();
			else 
				error(')');
		}else
			error('(');
	}else
		error('w');
}

opLoop(){
	getchar();
	if(caracter == '{'){
		setchar();
		cuerpo();
	}else if(caracter == ';'){

	}else if(caracter =='w' || caracter == 'i' || caracter == 'f' || caracter == 'v' || caracter == 'a' || caracter == '@'){
		setchar();
		prop();
	}else		
		setchar();
}

fun_return(){
	getchar();
	if(caracter == 'v'){
		getchar();
		if(caracter == '('){
			fun_exp();
			getchar();
			if(caracter == ')'){
				getchar();
				if(caracter == ';'){

				}else
					error(';');
			}else
				error('v');
		}else
			error(')');
	}else
		error('v');
}

asig(){
	getchar();
	if(caracter == 'a'){
		opAsig();
		fun_exp();
		getchar();
		if(caracter == ';'){

		}else
			error(';');
	}else
		error('a');
}

llamada(){
	getchar();
	if(caracter == '@'){
		getchar();
		if(caracter == 'a'){
			getchar();
			if(caracter == '('){
				listarg();
				getchar();
				if(caracter == ')'){
					getchar();
					if(caracter == ';'){

					}else
						error(';');

				}else 
					error(')');
			}else
				error('(');
		}else
			error('a');
	}else
		error('@');
}

listarg(){
	getchar();
	if(caracter == ')'){
		setchar();
	}else if(caracter == '(' || caracter == 'a' || caracter == 'o' || caracter == 'n' || caracter == 'h' || caracter == 'z' || caracter == 's' || caracter == '@'){
		setchar();
		fun_exp();
		listaExp();
	}else
		setchar();
}

listaExp(){
	getchar();
	if(caracter == ')'){
		setchar();
	}else if(caracter == ','){
		setchar();
		getchar();
		if(caracter == ','){
			fun_exp();
			listaExp();
		}else
			error(',');
	}else
		setchar();
}

fun_for(){
	getchar();
	if(caracter == 'f'){
		getchar();
		if(caracter == '('){
			listafor();
			getchar();
			if(caracter == ')')
				opLoop();
			else
				error(')');
		}else
			error('(');
	}else
		error('f');
}

listafor(){	
	expGral();
	getchar();
	if(caracter == ';'){
		expGral();
		getchar();
		if(caracter == ';')
			expGral();
		else
			error(';');
	}else
		error(';');
}
	
expGral(){
	getchar();
	if(caracter == ';' || caracter == ')'){
		setchar();	
	}else if(caracter == '(' || caracter == 'a' || caracter == 'o' || caracter == 'n' || caracter == 'h' || caracter == 'z' || caracter == 's' || caracter == '@'){
		setchar();
		expRel();
	}else
		setchar();
}

fun_if(){
	getchar();
	if(caracter == 'i'){
		getchar();
		if(caracter == '('){
			expRel();
			getchar();
			if(caracter == ')'){
				opLoop();
				getchar();
				if(caracter == 'l')
					opLoop();
				else
					error('l');
			}else
				error(')');
		}else
			error('(');
	}else
		error('i');
}

expRel(){	
	fun_exp();
	//getchar();
	//if(caracter == '('){
		opcionRel();
		/*getchar();
		if(caracter == ')'){
		
		}else 
			error(')');
	}else 
		error('(');*/
}


opcionRel(){	
	getchar();
	if(caracter == ')'){
		setchar();
	}else if(caracter == '<' || caracter == '>' || caracter == 'b' || caracter == 'g' || caracter == 'j' || caracter == '!'){
		setchar();
		opRel();
		fun_exp();
	}else
		setchar();
}

fun_exp(){
	T();
	EP();
}

EP(){
	getchar();
	if(caracter == '+' || caracter == '-'){		
		T();
		EP();
	}else if(caracter == ')' || caracter == ';')
		setchar();		
	else
		setchar();
}

T(){	
	F();
	TP();	
}

TP(){
	getchar();
	if(caracter == '*' || caracter == '/' || caracter == '%'){
		F();
		TP();
	}else if(caracter == '+' || caracter == '-')
		setchar();
	else
		setchar();
}

F(){
	getchar();
	if(caracter == '('){
		fun_exp();
		getchar();
		if(caracter == ')'){
		
		}else
			error(')');	
	}else if(caracter == 'a' || caracter == 'o' || caracter == 'n' || caracter == 'h' || caracter == 'z' || caracter == 's'){

	}else if(caracter == '@'){
		setchar();
		llamada();
	}else
		error2(4);
}

opRel(){
	getchar();
	if(caracter == '<' || caracter == '>' || caracter == 'b' || caracter == 'g' || caracter == 'j' || caracter == '!'){

	}else
		error2(5);
}

opAsig(){
	getchar();
	if(caracter == '=' || caracter == 'k' || caracter == 'm' || caracter == 'p' || caracter == 'q' || caracter == 't' || caracter == 'u' || caracter == 'x' || caracter == 'y' || caracter == 'z'){

	}else
		error2(6);
}
