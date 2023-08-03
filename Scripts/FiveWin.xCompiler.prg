/*
 * São Paulo , 16/06/2006 @ 06:36
 * Revisado em 23/8/2006 17:00:02
 * -----------------------------
 * MiniGUI.xCompiler.prg
 *
 * Arquivo contendo os comandos de Script para processamento de um projeto
 * Harbour modo CONSOOLE com Borland BCC ou MinGW.
 */
#define CRLF Chr(13)+Chr(10)

function Prepare
   type := Project( 'TargetType' )

   if FileExists( 'harbour.exe', m_PreSetPath ) .or. ;
      FileExists( 'hb.exe', m_PreSetPath )
      *
   else
      MsgError( 'O arquivo principal do compilador não existe!' )
      return .f.
   end
    
   if !FileExists( 'bcc32.exe', m_PreSetPath )
      MsgError( 'O arquivo requerido BCC32.EXE não foi localizado no sistema!' )
      return .f.
   end
    
   if !FileExists( 'ilink32.exe', m_PreSetPath )
      MsgError( 'O arquivo requerido ILINK32.EXE não foi localizado no sistema!' )
      return .f.
   end
    
   return .t.
 
function UnPrepare
   return .t.
 
/*
 * Esta função é executada, sempre que a xDev precisar compilar um arquivo .PRG
 */ 
function OnFilePRG
 * Preparamos a linha de comando
   cmd := 'harbour.exe'
   cmd += ' "' + m_sFileName + '"'
   cmd += ' /q /o"' + m_sOutPut + '"'
   cmd += ' ' + fFlagA + ' ' + fFlagL + ' ' + fFlagM + ' ' + ; 
          ' ' + fFlagN + ' ' + fFlagZ  + ' ' + fFlagP
 *
 * Verificarmos se ele nao quer desativar o DEBUG para este módulo em específico!
 * para isto usamos a funcao SameText() que compara os 2 argumentos ignorando 
 * letras maiúsculas / minúsculas.
 * 
   if !SameText( PRG_DisableDebug, 'sim' )
      cmd += ' ' + fFlagB 
   end
       
 * Verificamos as diretrivas #DEFINEs e adicionamos ela na linha de comando!
   aDefs := Alltrim(CustomDefines) + ',' + ;   // Diretrivas gerais do projeto
            Alltrim(PRG_Defines)               // Diretrivas específicas deste arquivo 
            
   aDefs := StrTran(aDefs, ';', ',' )
   aDefs := StrTran(aDefs, ' ', '' )
   aDefs := ListAsArray( aDefs, ',')
   cmd   := alltrim( cmd )

   for i := 0 to len( aDefs )
       if !Empty(aDefs[i])
         cmd += ' /D' + aDefs[i]
       end
   next

 * Colocamos os outros parametros (se houver)
   cmd := alltrim( cmd )
   cmd += " " + fMiscOption1           
   
 * Executamos o comando específico para compilar 
   runBat(cmd)      
   
   bOk := (ErrorLevel() == 0)
   return bOk
     
/*
 * Esta função é executada, sempre que a xDev precisar compilar um arquivo .C
 */ 
function OnFileC
   
 * Preparamos a linha de comando
   aLines := {}

 * Verificamos as diretrivas #DEFINEs e adicionamos ela na linha de comando!
   aDefs := Alltrim(CustomDefines) + ',' + ;   // Diretrivas gerais do projeto
            Alltrim(PRG_Defines)               // Diretrivas específicas deste arquivo 
            
   aDefs := StrTran(aDefs, ';', ',' )
   aDefs := StrTran(aDefs, ' ', '' )
   aDefs := ListAsArray( aDefs, ',')
   cmd   := alltrim( cmd )

   for i := 0 to len( aDefs )
       if !Empty(aDefs[i])
          AAdd( aLines, '-D' + aDefs[i])
       end
   next

 * Ajustamos os outros parametros
   AAdd( aLines, '-I"' + m_PreSetInclude +'"')
   AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '"')
   AAdd( aLines, '-o"' + m_sOutPut + '"')
   AAdd( aLines, '"' + m_sFileName + '"')

 * Salvamos e executamos o comando específico para compilar
   MemoWrite( 'b32.bc', aLines )
   runBat('BCC32 -M -c @B32.BC')
   
   bOk := (ErrorLevel() == 0)
   return bOk
     
/*
 * Esta função é executada, sempre que a xDev precisar compilar um arquivo .RC
 */ 
function OnFileRC  
   cmd := FindFile( 'brc32.exe', m_PreSetPath )
   
   if Empty(cmd)
      cmd := FindFile( 'porc.exe', m_PreSetPath )
   end
   
   if Empty(cmd)
      MsgError( 'Erro ao localizar o aplicativo necessário para compilar o módulo "'+m_sFileName+'"!' )
      return .f.
   end   
   
 * Preparamos a linha de comando
   cmd += ' -r -fo"' + m_sOutPut + '" -i"' + m_PreSetInclude +'"'

 * Verificamos as diretrivas #DEFINEs e adicionamos ela na linha de comando!
   aDefs := Alltrim(CustomDefines) + ',' + ;   // Diretrivas gerais do projeto
            Alltrim(PRG_Defines)               // Diretrivas específicas deste arquivo 
            
   aDefs := StrTran(aDefs, ';', ',' )
   aDefs := StrTran(aDefs, ' ', '' )
   aDefs := ListAsArray( aDefs, ',')
   cmd   := alltrim( cmd )

   for i := 0 to len( aDefs )
       if !Empty(aDefs[i])
          cmd += ' -D' + aDefs[i]
       end
   next

 * Ajustamos os outros parametros
   cmd += ' "' + m_sFileName + '"'  

 * Executamos o comando específico para compilar
   run (cmd)      
   
   bOk := (ErrorLevel() == 0)
   return bOk
     
function MakeFW32_BCC   
   if SameText( type, 'LIB' ) .or. ;     
      SameText( type, 'DLL' )
      MsgError( 'Arquivos *.' + type + ' não são suportados por este script (ainda)!'+;
                'Neste caso use o "Harbour 32 Bits & BCC / MinGW" para criar estes arquivos.' ;
              )
      return .F.
   end                         
   return BuildExe()

function BuildExe()   
 * Preparamos a linha de comando
   aLines  := {}

   AAdd( aLines, '-I"' + m_PreSetInclude +'" +')
   AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '" +')
   
 * Usamos sempre a função SAMETEXT() pq ela compara removendo os espaços e 
 * ignorando maiúsculas e minúsculas
   if SameText( fForceCON, 'Sim' )
      *
   else
      AADD( aLines, '-aa +' )
   end
                                      
   AADD( aLines, '-Gn -Tpe -s +' )
   AADD( aLines, 'c0w32.obj +    ' )

   /*
    * Incluimos os arquivos .OBJ do projeto
    */
   aFiles := Project( "*.OBJ" )

   t := Len( aFiles )
    
   FOR i := 1 TO t
       IF i == t 
          AADD( aLines, '"'+aFiles[i]+'", + ' )
       ELSE
          AADD( aLines, '"'+aFiles[i]+'"  + ' )
       End
   End
   
   AADD( aLines, '"'+m_sOutPut + '", +   ' )
   AADD( aLines, '"'+ChangeFileExt( m_sOutPut, '.map')+'", +   ' )
   
   /*
    * Chamamos a função que pega o nome das libs corretas
    */
   DefaultLibs()
      
   AADD( aLines, 'cw32.lib +     ' )
   AADD( aLines, 'import32.lib + ' )
      
   if SameText( RDD4, 'sim' )   
      AADD( aLines, 'odbc32.lib +')
   end
   
   if FileExists('nddeapi.lib', m_PreSetLib )
      AADD( aLines, 'nddeapi.lib +' )
   end
   
   if FileExists('iphlpapi.lib', m_PreSetLib )
      AADD( aLines, 'iphlpapi.lib +' )
   end
     
   if FileExists('rasapi32.lib', m_PreSetLib )
      AADD( aLines, 'rasapi32.lib +' )
   end
   
   AADD( aLines, ',' )

   /*
    * Põe os RCs do projeto 
    */
   aFiles := Project( "*.RES" )

   FOR i := 1 TO Len( aFiles )
       IF i == t 
          AADD( aLines, '"'+aFiles[i]+'" ' )
       else
          AADD( aLines, '"'+aFiles[i]+'" + ' )
       End
   End

   MemoWrite( 'b32.bc', aLines )
   runBat('ILINK32 @B32.BC')
   
   bOk := (ErrorLevel() == 0)
   /*   
    * Testamos se ele quer compactar o aplicativo gerado usando UPX
    * 22/01/2008 - 10:35:49
    */
   if bOk .and. SameText( fUseUPX, 'Sim' )
      cmd := FindFile( 'upx.exe', m_PreSetPath )

      if Empty(cmd)
         MsgError( 'Erro ao localizar o arquivo UPX.EXE necessário para compactar seu aplicativo!' )
         return .f.
      end       
      
      aLines := {}
      AADD( aLines, 'ECHO xDev TITLE UPX' )
      AADD( aLines, 'ECHO xDev FILE '+ m_sOutPut +'' )       
      AADD( aLines, 'UPX.EXE "'+m_sOutPut + '"' )      
      
      cmd := ListAsText( aLines )  
      runBat( cmd )
              
      bOk := (ErrorLevel() == 0)
   end   
   return bOk

function DefaultLibs()

   if FileExists('sqllib.lib', m_PreSetLib )
      sql_lib := 'sqllib.lib + '
   else
      sql_lib := ApplyMacros( 'sqllib_($hV).lib + ')
   end

   if SameText( CustomLIBs, 'Sim')
      /*
       * Se ele tem a lista de LIBs personalizadas não preenchemos isto...
       */
   else

      /*
       * A SQL LIB RDD deve preceder sobre as do FW?
       */
      if !SameText( RDD1, 'sim' )
         * Ele não quer usar a SQL LIB
         
      elseif SameText( fUseSQLLIBFirst, 'sim' )
         * Sim ele quer usar e é para ter precedência!!
                
         AADD( aLines, 'libmysql.lib +')
         AADD( aLines, sql_lib )
      end   
       
      /*
       * É Harbour ou xHabour() ?
       */
       
      if IsHarbour()
         AADD( aLines, 'FiveH.lib FiveHC.lib +' )
      else
         AADD( aLines, 'FiveHx.lib FiveHC.lib +' )
      end
      
      /*
       * Testamos se ele quer usar a HARBOUR.DLL se for, isto reduz o numero de LIBs
       * linkadas no projeto.
       */
       
      if SameText( fUseHBDLL, 'sim' )
         AADD( aLines, 'harbour.lib + ' )
      
         if SameText( RDD3, 'sim' )   
            AADD( aLines, 'rddads.lib +')
            AADD( aLines, 'ace32.lib +')
         end
         
         if FileExists( 'bcc640.lib', m_PreSetLib ) 
            AADD( aLines, 'bcc640.lib +   ' )
         end
         
      else
         AADD( aLines, 'rtl.lib +      ' )
         AADD( aLines, 'vm.lib +       ' )
   
         if FileExists( 'gtgui.lib', m_PreSetLib )
            AADD( aLines, 'gtgui.lib + ' )
         else
            AADD( aLines, 'gtwin.lib + ' )
         end
          
         AADD( aLines, 'lang.lib +     ' )
         AADD( aLines, 'macro.lib +    ' )
         AADD( aLines, 'rdd.lib +      ' )
         
         /*
          * Testa se o arquivo bcc640.lib existe no
          * PATH passado no segundo arqumento, neste caso m_PreSetLib
          */
         if FileExists( 'codepage.lib', m_PreSetLib ) 
            AADD( aLines, 'codepage.lib + ' )
         end
      
         AADD( aLines, 'dbfntx.lib +   ' )
         
         if SameText( RDD2, 'sim' )   
            AADD( aLines, 'dbfcdx.lib +   ' )
         end
      
         if SameText( RDD3, 'sim' )   
            AADD( aLines, 'rddads.lib +')
            AADD( aLines, 'ace32.lib +')
         end
             
         if FileExists( 'bcc640.lib', m_PreSetLib ) 
            AADD( aLines, 'bcc640.lib +   ' )
         end
         
         if FileExists('dbfdbt.lib', m_PreSetLib ) 
            AADD( aLines, 'dbfdbt.lib +   ' )
         end
         
         if FileExists('dbffpt.lib', m_PreSetLib ) 
            AADD( aLines, 'dbffpt.lib +   ' )
         end
         
         if FileExists('hbsix.lib', m_PreSetLib ) 
            AADD( aLines, 'hbsix.lib +    ' )
         end
      end      
   
      if !SameText( RDD1, 'sim' )
         * Ele não quer usar a SQL LIB
         
      elseif SameText( fUseSQLLIBFirst, 'sim' )
         * Já adicionamos isto lá encima.
                
      else
         AADD( aLines, 'libmysql.lib +')
         AADD( aLines, sql_lib )
      end   
   
      AADD( aLines, 'common.lib +   ' )
      AADD( aLines, 'pp.lib +       ' )
   end
      
   /*
    * Incluimos os arquivos .LIB no projeto
    */
   aFiles := Project( "*.LIB" )

   FOR i := 1 TO Len( aFiles )
       AADD( aLines, '"'+aFiles[i]+'" +  ' )
   End         
    
   if SameText( CustomLIBs, 'Sim')
      /*
       * Se ele tem a lista de LIBs personalizada, caimos fora!
       */
   else
      if SameText( fFlagB, '/B' )
         AADD( aLines, 'debug.lib + ' )
      end
   end
   return