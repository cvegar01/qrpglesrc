**Free                                                                                              
//------------------------------------------------------------------------------                    
//                                (C) CASER€                                                       
//  žAPLICACIÓN € COASEGUROS RECIBOS.                                                               
//  žPROGRAMA   € ICRCOR79                                    žFECHA€ 04/03/2024                    
//  žAUTOR      € Carlos Vega García.                                                               
//  žTAREA      € INC000011439559 - Facturas emitidas de coaseguro cedido.                          
//  žDESCRIPCIÓN€ Actualizar CFDIVA con la fecha de sistema en PFCONCRB para los                    
//   registros de la compañía recibida en parámetros y que sean de código                           
//   contable de cobro/pago de recibos.                                                             
//------------------------------------------------------------------------------                    
                                                                                                    
//------------------------------------------------------------------------------                    
//  žMODIFICACIÓN:€ Coaseguro Recibos Diferencias en importes de IVA.                               
//  Grabar nuevo registro en PFCONCRB por:                                                          
//   -Compañía, compañía coaseguro y tipo de IVA según agrupación realizada.                        
//   -Código contable 0025.                                                                         
//   -Todos los importes a cero con excepción de los gastos de administración                       
//     (agrupación realizada), base de IVA (agrupación realizada), cuota de IVA                     
//     (se asignará agrupación debase de IVA * % de IVA / 100).                                     
//   -El resto de campos blancos o ceros.                                                           
//   -El numero de documento, apunte serán el siguiente que le toque.                               
//   -Fecha contable y Error serán 0.                                                               
//   -Fecha emisión Factura (CFDIVA) la fecha de cierre que actualmente está                        
//    actualizando y ahora no actualizará, se grabará en el registro que se crea.                   
//                                                                                                  
//  žTAREA€        INC000011447561                           žREFERENCIA:€ 47561                    
//  žAUTOR€        Carlos Vega García.                                                              
//  žFECHA€        15/03/2024                                                                       
//------------------------------------------------------------------------------                    
                                                                                                    
//------------------------------------------------------------------------------                    
//Opciones de compilación de especificación de control.                                             
//------------------------------------------------------------------------------                    
Ctl-Opt FixNbr(*InputPacked:*Zoned) Option(*NoDebugIO)                                              
        DftActGrp(*No) ActGrp('COASEG')                                                             
        DatFmt(*Iso) DatEdit(*YMD) DecEdit('0,') UsrPrf(*User);                                     
                                                                                                    
//------------------------------------------------------------------------------                    
//Declaración de ficheros.                                                                          
//------------------------------------------------------------------------------                    
Dcl-F PFCONCRB Disk(*Ext) Keyed Usage(*Output);                                                     
                                                                                                    
//------------------------------------------------------------------------------                    
//Declaración de estructuras.                                                                       
//------------------------------------------------------------------------------                    
//Registro de PFCONCRB,                                                                             
Dcl-Ds rCrb LikeRec(COAREB) Inz;                                                //47561             
//Totales de IVA.                                                               //47561             
Dcl-Ds rTotIva Qualified Inz;                                                   //47561             
  CiaFusionada   Char  (   4);                                                  //47561             
  Coaseguradora  Packed(   4);                                                  //47561             
  PorcentajeIVA  Packed( 5:2);                                                  //47561             
  GastosFactura  Packed(13:2);                                                  //47561             
  BaseIVA        Packed(13:2);                                                  //47561             
  CuotaCalculada Packed(13:2);                                                  //47561             
End-Ds;                                                                         //47561             
                                                                                                    
//------------------------------------------------------------------------------                    
//Declaración de variables.                                                                         
//------------------------------------------------------------------------------                    
Dcl-S wFinPeriodoCierre  Zoned(8) Inz;                                                              
Dcl-S Registros  Int(5) Inz;                                                                        
Dcl-S wFecha     Date   Inz;                                                                        
                                                                                                    
//------------------------------------------------------------------------------                    
//Declaración de parámetros.                                                                        
//------------------------------------------------------------------------------                    
// Parm Entrada --> pCia Fusionada, pFecha                                                          
// Parm Salida  --> pError:' ' -Correcto.                                                           
//                         'E' -Errores.                                                            
//                         'X' -No hay registros para la selección.                                 
//------------------------------------------------------------------------------                    
Dcl-Pi *n; //*Entry                                                                                 
  pCiaFusionada Char(4);                                                                            
  pFecha        Char(6);                                                                            
  pError        Char(1);                                                                            
End-Pi;                                                                                             
                                                                                                    
//------------------------------------------------------------------------------                    
//Procedimiento principal.                                                                          
//------------------------------------------------------------------------------                    
Exec Sql Set Option Commit = *None, Naming = *Sys, CloSqlCsr = *EndMod;                             
                                                                                                    
pError = ' ';                                                                                       
                                                                                                    
//Calcular la fecha de cierre.                                                                      
wFecha = %Date(%Dec((pFecha + '01'):8:0)) + %Months(1) - %Days(1);                                  
wFinPeriodoCierre = %Dec(wFecha);                                                                   
                                                                                                    
//Si ya está contabilizada o con fecha de factura, salir sin hacer nada.                            
Exec Sql                                                                                            
  SELECT COUNT(*) INTO :Registros                                                                   
    FROM PFCONCRB INNER JOIN PFCIAFUS ON CCDCIA = FUCANT                                            
   WHERE FUCFUS = :pCiaFusionada                                                                    
     AND SUBSTR(CPERCN, 1, 6) = :pFecha                                                             
     AND CTPREG IN ('0017', '0018', '0022', '0024')                                                 
     AND (CAFCON <> 0 OR CFDIVA <> 0)                                                               
   WITH NC;                                                                                         
                                                                                                    
//Hay registros con fecha de contabilización o fecha de factura.                                    
If SqlCode = 0 And Registros <> 0;                                                                  
                                                                                                    
  pError = ' '; //Salir sin error.                                                                  
                                                                                                    
Else;                                                                                               
                                                                                                    
//47561//La fecha de factura ya no se actualizará, se grabará en el registro que se crea.           
//47561//  Exec Sql                                                                                 
//47561//    UPDATE PFCONCRB                                                                        
//47561//    SET CFDIVA = :wFinPeriodoCierre                                                        
//47561//    WHERE SUBSTR(CPERCN, 1, 6) = :pFecha                                                   
//47561//      AND CTPREG IN ('0017', '0018', '0022', '0024')                                       
//47561//      AND CFDIVA = 0                                                                       
//47561//      AND CAFCON = 0                                                                       
//47561//      AND (CNUDOC, CNUAPU, CCDCIA, CPERCN, CCDCIC)                                         
//47561//       IN (SELECT CNUDOC, CNUAPU, CCDCIA, CPERCN, CCDCIC                                   
//47561//             FROM PFCONCRB INNER JOIN PFCIAFUS ON CCDCIA = FUCANT                          
//47561//            WHERE FUCFUS = :pCiaFusionada                                                  
//47561//              AND SUBSTR(CPERCN, 1, 6) = :pFecha                                           
//47561//              AND CTPREG IN ('0017', '0018', '0022', '0024')                               
//47561//          )                                                                                
//47561//     WITH NC;                                                                              
                                                                                                    
//47561//  Select;                                                                                  
//47561//  //Se ha actualizado la fecha de factura.                                                 
//47561//  When SqlCode = 0;                                                                        
    pError = ' ';                                                                                   
    ExSr SrCalcularTotalesIVA; //47561                                                              
//47561//                                                                                           
//47561//  //No hay registros para la selección.                                                    
//47561//  When SqlCode = 100;                                                                      
//47561//    pError = 'X';                                                                          
                                                                                                    
//47561//  //Resto de códigos.                                                                      
//47561//  Other;                                                                                   
//47561//    pError = 'E';                                                                          
//47561//                                                                                           
//47561//  EndSl;                                                                                   
                                                                                                    
EndIf;                                                                                              
                                                                                                    
*InLr = *On;                                                                                        
                                                                                                    
//------------------------------------------------------------------------------                    
//Calcular los totales de IVA.                                                                      
//------------------------------------------------------------------------------                    
BegSr SrCalcularTotalesIVA; //47561: INICIO.                                                        
                                                                                                    
  Exec Sql CLOSE C1;                                                                                
  Exec Sql DECLARE C1 CURSOR FOR                                                                    
    SELECT                                                                                          
      CiaFusionada,                                                                                 
      Coaseguradora,                                                                                
      Porcentaje_IVA,                                                                               
      Decimal(Sum(Base_IVA)    , 13 , 2) BaseIVA,                                                   
      Decimal(Sum(Base_IVA*Porcentaje_IVA)/100, 13 , 2) CuotaCalculada                              
    FROM(                                                                                           
      SELECT                                                                                        
        FUCFUS CiaFusionada,                                                                        
        CCDCIC Coaseguradora,                                                                       
        CTPIVA Porcentaje_IVA,                                                                      
        CASE WHEN CTPREG IN ('0018',  '0022')                                                       
             THEN SUM((-CGSADM) / 100) ELSE SUM(CGSADM / 100)                                       
        END Gastos_Factura,                                                                         
        CASE WHEN CTPREG IN ('0018',  '0022')                                                       
             THEN SUM((-CBSIVA) / 100) ELSE SUM(CBSIVA / 100)                                       
        END Base_IVA                                                                                
      FROM PFCONCRB INNER JOIN PFCIAFUS ON CCDCIA = FUCANT                                          
      WHERE FUCFUS = :pCiaFusionada                                                                 
        AND SUBSTR(CPERCN, 1, 6) = :pFecha                                                          
        AND CTPREG IN ('0017', '0018', '0022', '0024')                                              
//47561///  AND CFDIVA = :wFinPeriodoCierre                                                         
      GROUP BY FUCFUS, CCDCIC, CTPIVA, CTPREG                                                       
    ) AS T1                                                                                         
    GROUP BY CiaFusionada, Coaseguradora, Porcentaje_IVA                                            
    ORDER BY CiaFusionada, Coaseguradora                                                            
    WITH NC;                                                                                        
                                                                                                    
  Exec Sql OPEN C1;                                                                                 
  Exec Sql FETCH C1 INTO :rTotIva;                                                                  
                                                                                                    
  Dow SqlCode = 0;                                                                                  
    ExSr SrGrabarNuevoRegistro;                                                                     
    Exec Sql FETCH C1 INTO :rTotIva;                                                                
  EndDo;                                                                                            
                                                                                                    
  Exec Sql CLOSE C1;                                                                                
                                                                                                    
EndSr; //47561: FIN.                                                                                
                                                                                                    
//------------------------------------------------------------------------------                    
//Grabar el nuevo registro de código contable de cálculo de IVA con los totales.                    
//------------------------------------------------------------------------------                    
BegSr SrGrabarNuevoRegistro; //47561: INICIO.                                                       
                                                                                                    
  Clear rCrb;                                                                                       
                                                                                                    
  //Seleccionar el último registro para tomar como base.                                            
  Exec Sql                                                                                          
    SELECT * INTO :rCrb                                                                             
      FROM PFCONCRB INNER JOIN PFCIAFUS ON CCDCIA = FUCANT                                          
     WHERE FUCFUS = :rTotIva.CiaFusionada                                                           
       AND CCDCIC = :rTotIva.Coaseguradora                                                          
       AND CTPIVA = :rTotIva.PorcentajeIVA                                                          
       AND SUBSTR(CPERCN, 1, 6) = :pFecha                                                           
       AND CTPREG IN ('0017', '0018', '0022', '0024')                                               
    ORDER BY CNUDOC DESC, CNUAPU DESC                                                               
    LIMIT 1                                                                                         
  WITH NC;                                                                                          
                                                                                                    
  Select;                                                                                           
  When SqlCode = 0;                                                                                 
    ExSr SrCumplimentarCamposRegistro;                                                              
    If RegistrosConCuotaCalculada() = 0;                                                            
      Write COAREB rCrb;                                                                            
    EndIf;                                                                                          
                                                                                                    
  When SqlCode = 100;                                                                               
    //No encontrado                                                                                 
                                                                                                    
  Other;                                                                                            
    //Otros estados.                                                                                
                                                                                                    
  EndSl;                                                                                            
                                                                                                    
EndSr; //47561: FIN.                                                                                
                                                                                                    
//------------------------------------------------------------------------------                    
//Cumplimentar los datos del nuevo registro que se va a grabar.                                     
//------------------------------------------------------------------------------                    
BegSr SrCumplimentarCamposRegistro;                                                                 
                                                                                                    
  rCrb.CNUDOC = ObtenerSiguienteNroDocumento();                                                     
  rCrb.CNUAPU = 1;                                                                                  
  rCrb.CAFCON = 0;                                                                                  
  rCrb.CACERR = 0;                                                                                  
  rCrb.CTPREG = '0025';                                                                             
  rCrb.CCDCIA = rTotIva.CiaFusionada;                                                               
  Clear rCrb.CCDRAM;                                                                                
  Clear rCrb.CCDMOD;                                                                                
  Clear rCrb.CCDSMD;                                                                                
  Clear rCrb.CCDRMC;                                                                                
  Clear rCrb.CCDMDC;                                                                                
  Clear rCrb.CPOLIZ;                                                                                
  Clear rCrb.CCONTR;                                                                                
  Clear rCrb.CPOLCO;                                                                                
  Clear rCrb.CSERIE;                                                                                
  Clear rCrb.CCDOFI;                                                                                
  Clear rCrb.CCDAGE;                                                                                
  Clear rCrb.CTPAGE;                                                                                
  Clear rCrb.CCDCAJ;                                                                                
  Clear rCrb.CCDOFC;                                                                                
  Clear rCrb.CCDPRV;                                                                                
  Clear rCrb.CORNEG;                                                                                
  Clear rCrb.CTPNEG;                                                                                
  Clear rCrb.CPERCN;                                                                                
  rCrb.CCDCIC = rTotIva.Coaseguradora;                                                              
  rCrb.CCDCIF = rCrb.CCDCIF;                                                                        
  Clear rCrb.CPORCE;                                                                                
  Clear rCrb.CCDDIV;                                                                                
  rCrb.CTOTRC = 0;                                                                                  
  rCrb.CPRNET = 0;                                                                                  
  rCrb.COM    = 0;                                                                                  
  rCrb.CBONIF = 0;                                                                                  
  rCrb.CRECAD = 0;                                                                                  
  rCrb.CCONSO = 0;                                                                                  
  rCrb.CIMSPR = 0;                                                                                  
  rCrb.CFNG   = 0;                                                                                  
  rCrb.CCLEA  = 0;                                                                                  
  rCrb.CARBMN = 0;                                                                                  
  rCrb.CSPRIM = 0;                                                                                  
  rCrb.CCOMIS = 0;                                                                                  
  rCrb.CCRECA = 0;                                                                                  
  rCrb.CCCONS = 0;                                                                                  
  rCrb.CGSADM = rTotIva.GastosFactura;                                                              
  rCrb.CRCFRA = 0;                                                                                  
  Clear rCrb.CLIIVA;                                                                                
  Clear rCrb.CCDIVA;                                                                                
  Clear rCrb.CNDIVA;                                                                                
  rCrb.CFDIVA = wFinPeriodoCierre;                                                                  
  rCrb.CBSIVA = rTotIva.BaseIVA;                                                                    
  rCrb.CTPIVA = rTotIva.PorcentajeIVA;                                                              
  rCrb.CCUIVA = rTotIva.CuotaCalculada;                                                             
  rCrb.CARBNC = 0;                                                                                  
  rCrb.CIMP01 = 0;                                                                                  
  rCrb.CIMP02 = 0;                                                                                  
  rCrb.CIMP03 = 0;                                                                                  
  rCrb.CIMP04 = 0;                                                                                  
  Clear rCrb.CORIGE;                                                                                
  rCrb.MO0358 = rCrb.MO0358;                                                                        
  Clear rCrb.CDULOB;                                                                                
  Clear rCrb.CDPAIS;                                                                                
  rCrb.CTAXE1 = 0;                                                                                  
  rCrb.CTAXE2 = 0;                                                                                  
  rCrb.CTAXE3 = 0;                                                                                  
  rCrb.CTAXE4 = 0;                                                                                  
  rCrb.CTAXE5 = 0;                                                                                  
  rCrb.CTAXE6 = 0;                                                                                  
  rCrb.CTAXE7 = 0;                                                                                  
  rCrb.CTAXE8 = 0;                                                                                  
  rCrb.CTAXE9 = 0;                                                                                  
  rCrb.CFCMOV = rCrb.CFCMOV;                                                                        
                                                                                                    
EndSr;                                                                                              
                                                                                                    
//------------------------------------------------------------------------------                    
//Obtener el siguiente nº de documento a generar.                                                   
//------------------------------------------------------------------------------                    
Dcl-Proc ObtenerSiguienteNroDocumento; //47561: INICIO.                                             
  Dcl-Pi *n Packed(7);                                                                              
  End-Pi;                                                                                           
  Dcl-S NroDocumento Packed(7) Inz;                                                                 
                                                                                                    
  Exec Sql                                                                                          
    SELECT Max(CNUDOC) INTO :NroDocumento                                                           
      FROM PFCONCRB                                                                                 
      WITH NC;                                                                                      
                                                                                                    
  If SqlCode = -305;                                                                                
    NroDocumento = 0;                                                                               
    SqlCode = 0;                                                                                    
  Else;                                                                                             
    If NroDocumento = 9999999;                                                                      
      Exec Sql                                                                                      
        SELECT MAX(CNUDOC) INTO :NroDocumento                                                       
          FROM PFCONCRB WHERE CNUDOC <= 8000000                                                     
          WITH NC;                                                                                  
    EndIf;                                                                                          
  EndIf;                                                                                            
                                                                                                    
  Return (NroDocumento + 1);                                                                        
                                                                                                    
End-Proc; //47561: FIN.                                                                             
                                                                                                    
//------------------------------------------------------------------------------                    
//Comprobar (contar) si ya está grabado el registro con cuota de IVA.                               
//------------------------------------------------------------------------------                    
Dcl-Proc RegistrosConCuotaCalculada; //47561: INICIO.                                               
  Dcl-Pi *n Int(5);                                                                                 
  End-Pi;                                                                                           
  Dcl-S RegistrosConCuota Int(5) Inz;                                                               
                                                                                                    
  Exec Sql                                                                                          
    SELECT Count(*) INTO :RegistrosConCuota                                                         
      FROM PFCONCRB INNER JOIN PFCIAFUS ON CCDCIA = FUCANT                                          
     WHERE FUCFUS = :pCiaFusionada                                                                  
       AND CCDCIC = :rCrb.CCDCIC                                                                    
       AND CTPREG = '0025'                                                                          
       AND CFDIVA = :wFinPeriodoCierre                                                              
       AND SUBSTR(CPERCN, 1, 6) = :pFecha                                                           
     WITH NC;                                                                                       
                                                                                                    
   Return RegistrosConCuota;                                                                        
                                                                                                    
End-Proc; //47561: FIN.                                                                             
