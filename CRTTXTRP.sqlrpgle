      //‚-----------------------------------------------------------------------                    
      //‚                                                                                           
      //‚                           (C) C.V.G €                                                    
      //‚                                                                                           
      //‚žPROGRAMA€    - CRTTXT            žFECHA€ 23/04/2008                                       
      //‚                                                                                           
      //‚žAUTOR€       - Carlos Vega García.                                                        
      //‚                                                                                           
      //‚žDESCRIPCIÓN€ - Pasar fichero de base de datos a directorio                                
      //‚                                                                                           
      //‚-----------------------------------------------------------------------                    
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Opciones de compilación de especificación de control.                                      
      //‚-----------------------------------------------------------------------                    
     H DftActGrp(*No) ActGrp('QC2LE') BndDir('QC2LE')                                               
     H UsrPrf(*User)                                                                                
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Declaración de ficheros.                                                                   
      //‚-----------------------------------------------------------------------                    
     FQAFDPHY   IF   E             Disk    UsrOpn ExtFile('QTEMP/QRCDLEN')                          
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Declaración de subprocedimientos (funciones).                                              
      //‚-----------------------------------------------------------------------                    
      //‚Ejecutar un mandato CL.                                                                    
     D ClCmd           PR                  Like(StatusCode)                                         
     D   Cmd                       2048A   Options(*VarSize) Const                                  
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Declaración de procedimientos externos de C para fichero de sistema.                       
      //‚-----------------------------------------------------------------------                    
     D fopen           PR              *   ExtProc('fopen')                                         
     D   FI_                           *   Value Options(*String)                                   
     D   OpenMode                      *   Value Options(*String)                                   
     ‚*                                                                                             
     D fgets           PR              *   ExtProc('fgets')                                         
     D   Var_                          *   Value Options(*String)                                   
     D   Size_                       10i 0 Value                                                    
     D   FI_                           *   Value                                                    
     ‚*                                                                                             
     D fclose          PR            10i 0 ExtProc('fclose')                                        
     D   FI_                           *   Value                                                    
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Declaración de procedimientos externos de C para ficheros STMF.                            
      //‚-----------------------------------------------------------------------                    
     D fopenO          PR              *   ExtProc( '_C_IFS_fopen')                                 
     D   Stmf_                         *   Value Options(*String)                                   
     D   OpenMode                      *   Value Options(*String)                                   
     ‚*                                                                                             
     D fputcO          PR            10i 0 ExtProc('_C_IFS_fputc')                                  
     D   Int                          5i 0 Value                                                    
     D   FO_                           *   Value                                                    
     ‚*                                                                                             
     D fputsO          PR            10i 0 ExtProc('_C_IFS_fputs')                                  
     D   Var_                          *   Value Options(*String)                                   
     D   FI_                           *   Value                                                    
     ‚*                                                                                             
     D fcloseO         PR            10i 0 ExtProc('_C_IFS_fclose')                                 
     D   FO_                           *   Value                                                    
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Declaración de estructuras.                                                                
      //‚-----------------------------------------------------------------------                    
     D PSDS           SDS                                                                           
     D  Usr                  254    263                                                             
     D  StatusCode       *Status                                                                    
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Declaración de variables.                                                                  
      //‚-----------------------------------------------------------------------                    
      //‚Manejador de fichero de entrada ( Sistema ).                                               
     D FI              S               *                                                            
      //‚Manejador de fichero de salida  ( STMF ).                                                  
     D FO              S               *                                                            
      //‚Valor de retorno tipo entero.                                                              
     D Rc              S              5i 0                                                          
      //‚Variable auxiliar.                                                                         
     D i               S             10i 0                                                          
     ‚*                                                                                             
     D Ds_Cadena_para_lectura_del_fichero...                                                        
     D                 Ds                                                                           
     D Cad                        32767A                                                            
     D  CadI                          3u 0 Dim(%Size(Cad)) Overlay(Cad)                             
     D  Cadx                          1A   Dim(%Size(Cad)) Overlay(Cad)                             
      //‚Longitud de registro.                                                                      
     D RcdLen          S                   Like(PHMXRL) Inz                                         
      //‚Fichero de sistema: Libreria/Fichero(Miembro).                                             
     D SFile           S            128A   Varying                                                  
      //‚Fichero continuo (STMF): ruta + nombre de fichero.                                         
     D Stmf            S            512A   Varying                                                  
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Declaración de constantes.                                                                 
      //‚-----------------------------------------------------------------------                    
      //‚Avance de línea.                                                                           
     D LF              C                   x'25'                                                    
                                                                                                    
      //‚-----------------------------------------------------------------------                    
      //‚Declaración de parámetros de entrada.                                                      
      //‚-----------------------------------------------------------------------                    
     C     *Entry        PList                                                                      
     C                   Parm                    PFil             10                                
     C                   Parm                    PLib             10                                
     C                   Parm                    PMbr             10                                
     C                   Parm                    PDir            256                                
     C                   Parm                    PStmf           256                                
                                                                                                    
      /Free                                                                                         
       //‚----------------------------------------------------------------------                    
       //‚Cuerpo principal                                                                          
       //‚----------------------------------------------------------------------                    
       If %Parms >= 5;                                                                              
         ExSr ChkObj;                                                                               
       EndIf;                                                                                       
                                                                                                    
       *InLr = *On;                                                                                 
                                                                                                    
       //‚----------------------------------------------------------------------                    
       //‚Chequear la existencia de los objetos                                                     
       //‚----------------------------------------------------------------------                    
       BegSr ChkObj;                                                                                
                                                                                                    
         Stmf = %Trim(%Trim(PDir)+'/'+%trim(PStmf));                                                
                                                                                                    
         Rc=Clcmd('CHKOBJ OBJ('+%Trim(PLib)+'/'+%Trim(PFil)+') ' +                                  
                         'OBJTYPE(*FILE) MBR('+%Trim(PMbr)+')');                                    
                                                                                                    
         If Rc = 0;                                                                                 
           ExSr GetRcdLen;                                                                          
         EndIf;                                                                                     
       EndSr;                                                                                       
                                                                                                    
       //‚----------------------------------------------------------------------                    
       //‚Obtener longitud de registro                                                              
       //‚----------------------------------------------------------------------                    
       BegSr GetRcdLen;                                                                             
                                                                                                    
         //‚Volcar información del fichero de sistema                                               
         Rc = Clcmd('DSPFD'                                 +                                       
                           ' '+%Trim(PLiB)+'/'+%Trim(PFil)  +                                       
                           ' TYPE(*ATR)'                    +                                       
                           ' OUTPUT(*OUTFILE)'              +                                       
                           ' FILEATR(*PF)'                  +                                       
                           ' OUTFILE(QTEMP/QRCDLEN)'        +                                       
                           ' OUTMBR(*FIRST *REPLACE)');                                             
         //‚Si no hay errores abre el fichero y continúa el proceso.                                
         If Rc = 0;                                                                                 
           Open QAFDPHY;                                                                            
           Read(e) QAFDPHY;                                                                         
           //‚Recupera la longitud de registro.                                                     
           If Not %Eof(QAFDPHY);                                                                    
             RcdLen = PHMXRL;                                                                       
           EndIf;                                                                                   
           Close QAFDPHY;                                                                           
         EndIf;                                                                                     
         //‚Continuar si la longitud de registro no es cero.                                        
         If RcdLen <> 0;                                                                            
           //‚Ficheros sin DDS.                                                                     
           If PHFLS = 'N';                                                                          
             ExSr FLAT_To_TXT;                                                                      
           Else;                                                                                    
             //‚Ficheros con DDS.                                                                   
             Select;                                                                                
             //‚Ficheros PF-SRC.                                                                    
             When PHDTAT = 'S';                                                                     
               ExSr SRC_To_TXT;                                                                     
             //‚Ficheros PF-DAT.                                                                    
             When PHDTAT = 'D';                                                                     
               ExSr DAT_To_TXT;                                                                     
             EndSl;                                                                                 
           EndIf;                                                                                   
         EndIf;                                                                                     
                                                                                                    
       EndSr;                                                                                       
                                                                                                    
       //‚----------------------------------------------------------------------                    
       //‚Copiar datos de fichero plano de sistema a fichero continuo (STMF).                       
       //‚----------------------------------------------------------------------                    
       BegSr FLAT_To_TXT;                                                                           
                                                                                                    
         //‚Componer nombre del fichero de sistema                                                  
         SFile = %Trim(%Trim(Plib)+'/'+%Trim(PFil)+'('+%Trim(PMbr)+')');                            
         //‚Abre fichero de sistema. Lectura binaria y ccsid 819 (win)                              
         FI = fopen( %Trim(SFile) : 'rb, ccsid=819');                                               
         If FI <> *Null;                                                                            
           //‚Abrir fichero de salida con página de códigos 819.                                    
           FO  = fopenO( %Trim(Stmf) : 'w, codepage=819');                                          
           Rc  = fcloseO(FO);                                                                       
           FO  = fopenO( %Trim(Stmf) : 'w');                                                        
           If FO <> *Null ;                                                                         
             //‚Leer FI mientras haya datos                                                         
             Dow fgets( %Addr(Cad) : RcdLen + 1 : FI ) <> *Null;                                    
               rc = fputsO( Cad : FO);  //‚Escribir datos en FO                                     
               rc = fputcO( LF  : FO);  //‚Escribir datos en FO                                     
             EndDo;                                                                                 
           EndIf;                                                                                   
         EndIf;                                                                                     
         //‚Cerrar ficheros FO y FI.                                                                
         Rc = fcloseO(FO);                                                                          
         Rc = fclose(FI);                                                                           
         //‚Establecer autorizaciones al fichero creado.                                            
         ExSr ChgAut;                                                                               
                                                                                                    
       EndSr;                                                                                       
                                                                                                    
       //‚----------------------------------------------------------------------                    
       //‚Copiar datos de fichero SRC de sistema a fichero continuo (STMF).                         
       //‚----------------------------------------------------------------------                    
       BegSr SRC_To_TXT;                                                                            
                                                                                                    
         //‚Componer nombre del fichero de sistema                                                  
         SFile = %Trim(%Trim(Plib)+'/'+%Trim(PFil)+' '+%Trim(PMbr));                                
         //‚Crear fichero continuo con ccsid 819 (UTF)                                              
         FO  = fopenO( %Trim(Stmf) : 'w, codepage=819' );                                           
         //‚Si lo ha creado, lo cierra y le copia los datos.                                        
         If FO <> *NULL;                                                                            
           fcloseO(FO);                                                                             
           //‚Hacer copia de fichero de importación.                                                
           Rc = Clcmd('CPYTOIMPF FROMFILE(' + %Trim(SFile) + ')' +                                  
                      ' TOSTMF(''' + %Trim(Stmf) + ''')'         +                                  
                      ' MBROPT(*REPLACE)'                        +                                  
                      ' RCDDLM(*CRLF) DTAFMT(*FIXED)'            +                                  
                      ' STRDLM(*NONE) FLDDLM('''')');                                               
           //‚Establecer autoriaciones al fichero creado.                                           
           ExSr ChgAut;                                                                             
         EndIf;                                                                                     
                                                                                                    
       EndSr;                                                                                       
                                                                                                    
       //‚----------------------------------------------------------------------                    
       //‚Copiar datos de fichero de sistema a fichero continuo (STMF).                             
       //‚----------------------------------------------------------------------                    
       BegSr DAT_To_TXT;                                                                            
                                                                                                    
         //‚Componer nombre del fichero de sistema                                                  
         SFile = %Trim(%Trim(Plib)+'/'+%Trim(PFil)+'('+%Trim(PMbr)+')');                            
         //‚Abre fichero de sistema.                                                                
         FI  = fopen( %Trim(SFile) : 'rb' );                                                        
         If FI <> *Null;                                                                            
           //‚Abre fichero continuo para escritura con ccsid 819 (UTF)                              
           FO = fopenO( %Trim(Stmf) : 'w, codepage=819' );                                          
           Rc = fcloseO(FO);                                                                        
           FO = fopenO( %Trim(Stmf) : 'w');                                                         
           If FO <> *Null ;                                                                         
             //‚Leer FI mientras haya datos.                                                        
             Dow fgets( %Addr(Cad) : RcdLen + 1 : FI ) <> *Null;                                    
               For i=1 to RcdLen;      //‚Escribir datos en FO.                                     
                 rc=fputcO( CadI(I) : FO);                                                          
               EndFor;                                                                              
               rc = fputcO( LF : FO);  //‚LF - Avance de línea.                                     
             EndDo;                                                                                 
           EndIf;                                                                                   
           //‚Cerrar ficheros FO y FI.                                                              
           rc = fcloseO(FO);                                                                        
           rc = fclose(FI);                                                                         
           //‚Establecer autoriaciones al fichero creado.                                           
           ExSr ChgAut;                                                                             
                                                                                                    
         EndIf;                                                                                     
                                                                                                    
       EndSr;                                                                                       
                                                                                                    
       //‚----------------------------------------------------------------------                    
       //‚Dar autorización PUBLIC(*ALL) y quitar las del usuario.                                   
       //‚----------------------------------------------------------------------                    
       BegSr ChgAut;                                                                                
                                                                                                    
         If Rc = 0;                                                                                 
           //‚Dar autorización PUBLIC(*ALL) al STMF                                                 
           rc =Clcmd('CHGAUT OBJ('''+ %Trim(Stmf) + ''') ' +                                        
                     'USER(*PUBLIC) DTAAUT(*RWX) OBJAUT(*ALL)');                                    
           //‚Quitar autorización USER(USUARIO) al STMF                                             
           rc= Clcmd('CHGAUT OBJ('''+ %Trim(Stmf) + ''') ' +                                        
                     'USER('+ %Trim(Usr) + ') DTAAUT(*NONE) OBJAUT(*NONE)');                        
         EndIf;                                                                                     
                                                                                                    
       EndSr;                                                                                       
      /End-Free                                                                                     
                                                                                                    
       //‚----------------------------------------------------------------------                    
       //‚Ejecutar un mandato CL.                                                                   
       //‚----------------------------------------------------------------------                    
     P ClCmd           B                                                                            
     D                 PI                  Like(StatusCode)                                         
     D   Cmd                       2048A   Options(*VarSize) Const                                  
       //‚Procedimiento externo para ejecutar un mandato CL                                         
     D QcmdExc         PR                  ExtPgm('QCMDEXC')                                        
     D  QCmd                       2048A   Options(*VarSize) Const                                  
     D  QCmdLen                      15P 5 Const                                                    
      /Free                                                                                         
           Callp(e) QCmdExc(%trim(Cmd):%len(%trim(Cmd)));                                           
           Return StatusCode;                                                                       
      /End-Free                                                                                     
     P                 E                                                                            
