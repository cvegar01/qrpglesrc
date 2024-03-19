      *---------------------------------------------------------------*                             
      * Descripción: Selección de Clases de Documentos para SAP.      *                             
      * Proyecto...: 00/200 (Implantación del SAP).                   *                             
      * Autor......: Vicente Candelas de la Hoz (Instituto Ibérico).  *                             
      * Fecha......: 04/10/2.000.                                     *                             
      *---------------------------------------------------------------*                             
      * Modificación:Se recompila por cambio estrucutra SAPCLD .      *                             
      * Tarea.......:INC000011280436              Ref(80436)          *                             
      * Autor.......:Iñaki P. de las Cuevas                           *                             
      * Fecha.......:23/03/2023                                       *                             
      *---------------------------------------------------------------*                             
     H DATEDIT(*YMD)                                                                                
      *---------------------------------------------------------------*                             
     FSAPCLD    IF   E           K DISK                                                             
     FAACDBCDO  CF   E             WORKSTN                                                          
     F                                     SFILE(FMTD:NUMREG)                                       
      *---------------------------------------------------------------*                             
     C     *ENTRY        PLIST                                                                      
     C                   PARM                    XCLADO            2                                
     C                   PARM                    XDESDO           40                                
     C                   PARM                    XRESPU            1                                
      *---------------------------------------------------------------*                             
      *                    PROCESO PRINCIPAL                          *                             
      *---------------------------------------------------------------*                             
     C                   Z-ADD     *ZERO         WFIN              1 0                              
      *                                                                                             
     C     WFIN          DOWEQ     *ZERO                                                            
     C                   SETON                                        92                            
     C                   WRITE     FMTC                                                             
     C                   SETOFF                                       92                            
     C                   Z-ADD     *ZEROS        NUMREG            5 0                              
     C                   EXSR      CARGA                                                            
      *                                                                                             
     C     WFIN          DOWEQ     *ZERO                                                            
     C                   EXSR      VISUAL                                                           
     C                   ENDDO                                                                      
      *                                                                                             
     C                   ENDDO                                                                      
      *                                                                                             
     C                   SETON                                        LR                            
      *---------------------------------------------------------------*                             
     C     CARGA         BEGSR                                                                      
      *         -------   -------                                                                   
     C     *LOVAL        SETLL     SAPCLD                                                           
     C                   READ      SAPCLD                                 30                        
     C     *IN30         DOWEQ     *OFF                                                             
     C                   MOVE      CLDCLA        ZCLADO                                             
     C                   MOVEL     CLDDES        ZDESDO                                             
     C                   ADD       1             NUMREG                                             
     C                   WRITE     FMTD                                                             
     C                   READ      SAPCLD                                 30                        
     C                   ENDDO                                                                      
      *                                                                                             
     C                   ENDSR                                                                      
      *---------------------------------------------------------------*****                         
     C     VISUAL        BEGSR                                                                      
      *         --------  -------                                                                   
     C                   WRITE     FMTM                                                             
     C                   SETON                                        93                            
     C     NUMREG        IFEQ      *ZEROS                                                           
     C                   SETOFF                                       91                            
     C                   ELSE                                                                       
     C                   SETON                                        91                            
     C                   ENDIF                                                                      
     C                   EXFMT     FMTC                                                             
     C                   SETOFF                                       9193                          
     C     *IN03         IFEQ      *ON                                                              
     C                   Z-ADD     1             WFIN                                               
     C                   ELSE                                                                       
     C     NUMREG        IFNE      *ZEROS                                                           
     C                   EXSR      SELE                                                             
     C                   ENDIF                                                                      
     C                   ENDIF                                                                      
     C                   ENDSR                                                                      
      *---------------------------------------------------------------*****                         
     C     SELE          BEGSR                                                                      
      *         ------    -------                                                                   
      * Lee cambiados:                                                                              
     C                   READC     FMTD                                   90                        
     C     *IN90         DOWEQ     *OFF                                                             
      *                                                                                             
     C     ZSELE         IFEQ      '1'                                                              
     C                   MOVE      *BLANKS       XRESPU                                             
     C                   MOVE      ZCLADO        XCLADO                                             
     C                   MOVE      ZDESDO        XDESDO                                             
     C                   SETON                                        90                            
     C                   ELSE                                                                       
     C                   READC     FMTD                                   90                        
     C                   ENDIF                                                                      
     C                   ENDDO                                                                      
      *                                                                                             
     C                   Z-ADD     1             WFIN                                               
      *                                                                                             
     C                   ENDSR                                                                      
