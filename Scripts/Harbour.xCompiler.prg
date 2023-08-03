/*
 * S�o Paulo , 16/06/2006 @ 06:36
 * Revisado em 23/8/2006 17:00:02
 * -----------------------------
 * Harbour.xCompiler.prg
 *
 * Arquivo contendo os comandos de Script para processamento de um projeto
 * Harbour modo CONSOLE com Borland BCC ou MinGW.
 */
#define CRLF Chr(13)+Chr(10)

function Prepare
   type := Project( 'TargetType' )
   
   if FileExists( 'harbour.exe', m_PreSetPath ) .or. ;
      FileExists( 'hb.exe', m_PreSetPath )
   /*
      alert(1)
   elseif ; 
      FileExists( 'hb.exe', m_PreSetPath )*/
      
      *
   else
      MsgError( 'O arquivo principal do compilador n�o existe!' )
      return .f.
   end
    
   if !FileExists( 'bcc32.exe', m_PreSetPath )
      MsgError( 'O arquivo requerido BCC32.EXE n�o foi localizado no sistema!' )
      return .f.
   end
    
   if !FileExists( 'ilink32.exe', m_PreSetPath )
      MsgError( 'O arquivo requerido ILINK32.EXE n�o foi localizado no sistema!' )
      return .f.
   end

   /*
    * 30/9/2006 21:02:35
    * Aqui neste ponto setamos a variavel abaixo como SIM, indicando
    * que desejamos recompilar todo o projeto. Caso o valor dela seja .F.
    * a xDev ir� compilar e linkar usando o padrao solicitado pelo 
    * programador que estiver usando a xDev.
    */
   m_bCompileAll := SameText( fForceCompileAll, 'sim' )
   return .t.
 
function UnPrepare
   return .t.
 
/*
 * Esta fun��o � executada, sempre que a xDev precisar compilar um arquivo .PRG
 */ 
function OnFilePRG
 * Preparamos a linha de comando
   cmd := 'harbour.exe'
   cmd += ' "' + m_sFileName + '"'
   cmd += ' /q /o"' + m_sOutPut + '"'
   cmd += ' ' + fFlagA + ' ' + fFlagL + ' ' + fFlagM + ' ' + ; 
          ' ' + fFlagN + ' ' + fFlagZ  + ' ' + fFlagP
 *
 * Verificarmos se ele nao quer desativar o DEBUG para este m�dulo em espec�fico!
 * para isto usamos a funcao SameText() que compara os 2 argumentos ignorando 
 * letras mai�sculas / min�sculas.
 * 
   if !SameText( PRG_DisableDebug, 'sim' )
      cmd += ' ' + fFlagB 
   end
       
 * Verificamos as diretrivas #DEFINEs e adicionamos ela na linha de comando!
   aDefs := Alltrim(CustomDefines) + ',' + ;   // Diretrivas gerais do projeto
            Alltrim(PRG_Defines)   + ',' + ;   // Diretrivas espec�ficas deste arquivo
            Alltrim(m_PreSetDefines)           // Estas sao as diretrivas do PROJETO e do PRESET atual  
            

   aDefs := StrTran(aDefs, ';', ',' )
   aDefs := StrTran(aDefs, ' ', '' )
   aDefs := ListAsArray( aDefs, ',')
   cmd   := alltrim( cmd )

   for i := 0 to len( aDefs )
       if !Empty(aDefs[i])
         cmd += ' /D' + aDefs[i]
       end
   next
   
 * Isto inclui os #DEFINEs de cada versao do xHb e do HB espec�ficas
   if !Empty(m_PresetConstants)  
      cmd  += m_PresetConstants
   end

 * Colocamos os outros parametros (se houver)
   cmd := alltrim( cmd )
   cmd += " " + fMiscOption1           
   
 * Executamos o comando espec�fico para compilar 
   runBat(cmd)      
   
   bOk := (ErrorLevel() == 0)
   return bOk
     
/*
 * Esta fun��o � executada, sempre que a xDev precisar compilar um arquivo .C/.CPP
 */ 
function OnFileC
   
 * Preparamos a linha de comando
   aLines := {}

 * Verificamos as diretrivas #DEFINEs e adicionamos ela na linha de comando!
   aDefs := Alltrim(CustomDefines) + ',' + ;   // Diretrivas gerais do projeto
            Alltrim(PRG_Defines)   + ',' + ;   // Diretrivas espec�ficas deste arquivo
            Alltrim(m_PreSetDefines)           // Estas sao as diretrivas do PROJETO e do PRESET atual  
                        
   aDefs := StrTran(aDefs, ';', ',' )
   aDefs := StrTran(aDefs, ' ', '' )
   aDefs := ListAsArray( aDefs, ',')
   cmd   := alltrim( cmd )

   for i := 0 to len( aDefs )
       if !Empty(aDefs[i])
          AAdd( aLines, '-D' + aDefs[i])
       end
   next

 * Isto inclui os #DEFINEs de cada versao do xHb e do HB espec�ficas
   if !Empty(m_PresetConstants)  
      AAdd( aLines, m_PresetConstants)
   end

 * Ajustamos os outros parametros
   AAdd( aLines, '-I"' + m_PreSetInclude +'"')
   AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '"')
   AAdd( aLines, '-o"' + m_sOutPut + '"')
   AAdd( aLines, '"' + m_sFileName + '"')

 * Salvamos e executamos o comando espec�fico para compilar
   MemoWrite( 'b32.bc', aLines )
   runBat('BCC32 -M -c @B32.BC')
   
   bOk := (ErrorLevel() == 0)
   return bOk

/*
 * Esta fun��o � executada, sempre que a xDev precisar compilar um arquivo .RC
 */ 
function OnFileRC  
   cmd := FindFile( 'brc32.exe', m_PreSetPath )
   
   if Empty(cmd)
      cmd := FindFile( 'porc.exe', m_PreSetPath )
   end
   
   if Empty(cmd)
      MsgError( 'Erro ao localizar o aplicativo necess�rio para compilar o m�dulo "'+m_sFileName+'"!' )
      return .f.
   end   
   
 * Preparamos a linha de comando
   cmd += ' -r -fo"' + m_sOutPut + '" -i"' + m_PreSetInclude +'"'

 * Verificamos as diretrivas #DEFINEs e adicionamos ela na linha de comando!
   aDefs := Alltrim(CustomDefines) + ',' + ;   // Diretrivas gerais do projeto
            Alltrim(PRG_Defines)   + ',' + ;   // Diretrivas espec�ficas deste arquivo
            Alltrim(m_PreSetDefines)           // Estas sao as diretrivas do PROJETO e do PRESET atual  
            
   aDefs := StrTran(aDefs, ';', ',' )
   aDefs := StrTran(aDefs, ' ', '' )
   aDefs := ListAsArray( aDefs, ',')
   cmd   := alltrim( cmd )

   for i := 0 to len( aDefs )
       if !Empty(aDefs[i])
          cmd += ' -D' + aDefs[i]
       end
   next
   
  * Isto inclui os #DEFINEs de cada versao do xHb e do HB espec�ficas
   if !Empty(m_PresetConstants)  
      cmd  += m_PresetConstants
   end

 * Ajustamos os outros parametros
   cmd += ' "' + m_sFileName + '"'  

 * Executamos o comando espec�fico para compilar
   run (cmd)      
   
   bOk := (ErrorLevel() == 0)
   return bOk
     
function OnBuild      
   if SameText( type, 'LIB' )     
      return BuildLib()
   end
   
   if SameText( type, 'DLL' )     
      return BuildDLL()
   end                         
   return BuildExe()

function BuildExe()   
 * Preparamos a linha de comando
   aLines  := {}

   AAdd( aLines, '-I"' + m_PreSetInclude +'" +')
   AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '" +')

 * Usamos sempre a fun��o SAMETEXT() pq ela compara removendo os espa�os e 
 * ignorando mai�sculas e min�sculas
   if SameText( fForceCON, 'Sim' )
      * ele quer q abra a janela dos no fundo.
   else   
    * Testamos abaixo se ele usa uma lib grafica em modo console
    * se for .T. a comparacao abaixo devemos esconder a janela DOS.  
      if SameText( Left( fGUILib,2 ), 'gt') 
         AADD( aLines, '-aa +' )
      end
   end
                             
   if !Empty(fMiscOption4)                                        
      AADD( aLines, fMiscOption4 +' +' )
   end
                                           
   AADD( aLines, '-Gn -M -m  -Tpe -s +' )
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
    * Chamamos a fun��o que pega o nome das libs corretas
    */
   DefaultLibs()
      
   AADD( aLines, 'cw32.lib +     ' )
   AADD( aLines, 'import32.lib + ' )
      
   if SameText( RDD4, 'sim' )   
      AADD( aLines, 'odbc32.lib +')
   end
   
   if FileExists('rasapi32.lib', m_PreSetLib )
      AADD( aLines, 'rasapi32.lib +' )
   end
   
   if FileExists('nddeapi.lib', m_PreSetLib )
      AADD( aLines, 'nddeapi.lib +' )
   end
   
   if FileExists('iphlpapi.lib', m_PreSetLib )
      AADD( aLines, 'iphlpapi.lib +' )
   end
   
   AADD( aLines, ',' )

   /*
    * P�e os RCs project files 
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
         MsgError( 'Erro ao localizar o arquivo UPX.EXE necess�rio para compactar seu aplicativo!' )
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

function BuildDLL()
 * Preparamos a linha de comando
   aLines  := {}

   AAdd( aLines, '-I"' + m_PreSetInclude +'" +')
   AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '" +')
   
 * Usamos sempre a fun��o SAMETEXT() pq ela compara removendo os espa�os e 
 * ignorando mai�sculas e min�sculas
   if SameText( fForceCON, 'Sim' )
      AADD( aLines, '-aa +' )
   end
                 
   AADD( aLines, '-Gn -M -m  -Tpd -s + ' )
   AADD( aLines, '-Gpr -ap + ' )
   AADD( aLines, 'c0d32.obj + ' )

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
    * Chamamos a fun��o que pega o nome das libs corretas
    */
   DefaultLibs()
   AADD( aLines, 'cw32.lib +     ' )
   AADD( aLines, 'import32.lib,  ' )

   /*
    * P�e os RCs project files 
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
         MsgError( 'Erro ao localizar o arquivo UPX.EXE necess�rio para compactar seu aplicativo!' )
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

function BuildLib()
* Preparamos a linha de comando
   aLines  := {}

 * Veja bem, se ele quer criar uma .LIB, ent�o temos que pegar todos os arquivos
 * .OBJ e jogar dentro da LIB
   aFiles := Project( "*.OBJ" )

   t := Len( aFiles )
    
   FOR i := 1 TO t
       AADD( aLines, 'ECHO xDev TITLE Linkando' )
       AADD( aLines, 'ECHO xDev FILE '+ ExtractFileName( aFiles[i] ) +'' )       
       AADD( aLines, 'TLIB "'+m_sOutPut+'" +- "'+aFiles[i]+'"' )
   End
   
 * Existe algo pra compilar?  
   IF Empty( aLines )
      return .T. 
   End
   
   cmd := ListAsText( aLines )  
   runBat( cmd )        
   
   bOk := (ErrorLevel() == 0)
 
 * 
 * 29/9/2006 16:49:59 
 * Se deu tudo certo na compila��o e for para copiar para a pasta LIB do nosso 
 * compilador, fazemos isto agora!
 *   
   if (bOk) .and. SameText( fInstallLIB, 'sim' )
      Dest := getLibFolder() + extractfilename( m_sOutPut )
      bOk := CopyFile( m_sOutPut, Dest )
   end
   return bOk

function DefaultLibs()
   Libs := .T.
   
   if SameText( CustomLIBs, 'Sim')
      /*
       * Se ele tem a lista de LIBs personalizadas n�o preenchemos isto...
       */
   else
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
         
         Libs := .F.
      else
         AADD( aLines, 'hblang.lib +     ' )
         AADD( aLines, 'hbvm.lib +       ' )
         AADD( aLines, 'hbrtl.lib +      ' )
         AADD( aLines, 'hbrdd.lib +      ' )
         AADD( aLines, 'hbmacro.lib +    ' )
         AADD( aLines, 'hbpp.lib +       ' )
         
         AADD( aLines, 'rddntx.lib +   ' )
         
         if SameText( RDD2, 'sim' )   
            AADD( aLines, 'rddcdx.lib +   ' )
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
         
         if FileExists('rddfpt.lib', m_PreSetLib ) 
            AADD( aLines, 'rddfpt.lib +   ' )
         end
      end      
   
      if SameText( RDD1, 'sim' )   
         AADD( aLines, ApplyMacros( 'sqllib_($hV).lib + ') )
         AADD( aLines, 'libmysql.lib +')
      end   
   end   
   
   /*
    * Incluimos os arquivos .LIB no projeto. O segundo parametro .T. indica que
    * queremos TODOS os arquivos AT� MESMO AQUELES MARCADOS com a op��o 
    * compile=FALSE, por isto usamos um parametro .T. 
    *
    * Quando omitimos o segundo parametro, ele puxar� apenas os arquivos
    * marcados como COMPILE=TRUE e desde modo, ir� ignorar os arquivos .LIB
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
         AADD( aLines, 'hbdebug.lib + ' )
      end
            
      if SameText( fUseHBDLL, 'sim' )
         ***
      elseif !Libs
         ***
      else
         /*
			AADD( aLines, 'hbcommon.lib +   ' )
         
         if SameText( fGUILib, 'Gtwvt' )
            *
            AADD( aLines, 'gtwvt.lib +' )
            *
            if FileExists('wvtgui.lib', m_PreSetLib )
               AADD( aLines, 'wvtgui.lib +' )
            end
            *
         elseif SameText( fGUILib, 'Gtwvw' )
            *
            AADD( aLines, 'gtwvw.lib +' )
            *
         elseif SameText( fGUILib, 'CGI/Web' )
            *
            AADD( aLines, 'gtcgi.lib + ' )
            *
         else
            if FileExists('gtwin.lib', m_PreSetLib )
               AADD( aLines, 'gtwin.lib + ' )
            else
               AADD( aLines, 'gtgui.lib + ' )
            end
         end         
         */
      end
       
      /*
       * Testa se o arquivo bcc640.lib existe no
       * PATH passado no segundo arqumento, neste caso m_PreSetLib
       */
      /*
		if FileExists( 'hbcpage.lib', m_PreSetLib ) 
         AADD( aLines, 'hbcpage.lib + ' )
      end
   
      if FileExists('hbct.lib', m_PreSetLib ) 
         AADD( aLines, 'hbct.lib +    ' )
      end
      if FileExists('hbtip.lib', m_PreSetLib ) 
         AADD( aLines, 'hbtip.lib +    ' )
      end
      if FileExists('hbhsx.lib', m_PreSetLib ) 
         AADD( aLines, 'hbhsx.lib +    ' )
      end
      if FileExists('hbpcre.lib', m_PreSetLib ) 
         AADD( aLines, 'hbpcre.lib +    ' )
      end
      if FileExists('hbsix.lib', m_PreSetLib ) 
         AADD( aLines, 'hbsix.lib +    ' )
      end
      */
   end   
   return