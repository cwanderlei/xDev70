/*
 * São Paulo , 1/10/2006 07:38:53
 * Revisado em 1/10/2006 07:39:00
 * -----------------------------
 * HwGUI.xCompiler.prg
 *
 * Arquivo contendo os comandos de Script para processamento de um projeto
 * Harbour modo GUI com Borland BCC e HwGUI.
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

   /*
    * 30/9/2006 21:02:35
    * Aqui neste ponto setamos a variavel abaixo como SIM, indicando
    * que desejamos recompilar todo o projeto. Caso o valor dela seja .F.
    * a xDev irá compilar e linkar usando o padrao solicitado pelo 
    * programador que estiver usando a xDev.
    */
   m_bCompileAll := SameText( fForceCompileAll, 'sim' )
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
            Alltrim(PRG_Defines)   + ',' + ;   // Diretrivas específicas deste arquivo
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
            Alltrim(PRG_Defines)   + ',' + ;   // Diretrivas específicas deste arquivo
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

 * Ajustamos os outros parametros
   AAdd( aLines, '-I"' + m_PreSetInclude +'"')
   AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '"')
   AAdd( aLines, '-o"' + m_sOutPut + '"')
   AAdd( aLines, '"' + m_sFileName + '"')

 * Salvamos e executamos o comando específico para compilar
   MemoWrite( 'b32.bc', aLines )
   runBat('BCC32 -M -c -tWM @B32.BC')
   
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
            Alltrim(PRG_Defines)   + ',' + ;   // Diretrivas específicas deste arquivo
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

 * Ajustamos os outros parametros
   cmd += ' "' + m_sFileName + '"'  

 * Executamos o comando específico para compilar
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
 
 *  
 * Usamos sempre a função SAMETEXT() pq ela compara removendo os espaços e 
 * ignorando maiúsculas e minúsculas
 *
   if !SameText( fForceCON, 'Sim' )
      AADD( aLines, '-aa +' )
   end
                                        
   AADD( aLines, '-Gn -Tpe +' )   
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
    * Põe os RCs project files 
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
      AADD( aLines, '\xDev70\UPX.EXE "'+m_sOutPut + '"' )      
      
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
   
 * Usamos sempre a função SAMETEXT() pq ela compara removendo os espaços e 
 * ignorando maiúsculas e minúsculas
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
    * Chamamos a função que pega o nome das libs corretas
    */
   DefaultLibs()
   AADD( aLines, 'cw32.lib +     ' )
   AADD( aLines, 'import32.lib,  ' )

   /*
    * Põe os RCs project files 
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
      AADD( aLines, 'xDev70\UPX.EXE "'+m_sOutPut + '"' )      
      
      cmd := ListAsText( aLines )  
      runBat( cmd )
              
      bOk := (ErrorLevel() == 0)
   end   
   return bOk

function BuildLib()
* Preparamos a linha de comando
   aLines  := {}

 * Veja bem, se ele quer criar uma .LIB, então temos que pegar todos os arquivos
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
 * Se deu tudo certo na compilação e for para copiar para a pasta LIB do nosso 
 * compilador, fazemos isto agora!
 *   
   if (bOk) .and. SameText( fInstallLIB, 'sim' )
      Dest := getLibFolder() + extractfilename( m_sOutPut )
      bOk := CopyFile( m_sOutPut, Dest )
   end
   return bOk

function DefaultLibs()

   if SameText( CustomLIBs, 'Sim')
      /*
       * Se ele tem a lista de LIBs personalizadas não preenchemos isto...
       */
   else

      /*
       * Colocamos as LIBs da HwGUI primeiro
       */
      AADD( aLines, 'hwgui.lib + ' )
      AADD( aLines, 'procmisc.lib + ' )
      AADD( aLines, 'hbxml.lib + ' )
      AADD( aLines, 'hwg_qhtm.lib + ' )
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
         if FileExists( 'codepage.lib', m_PreSetLib ) 
            AADD( aLines, 'codepage.lib + ' )
         end

         AADD( aLines, 'macro.lib +    ' )
         AADD( aLines, 'rdd.lib +      ' )
               
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
         
         AADD( aLines, 'common.lib +   ' )
         AADD( aLines, 'pp.lib +       ' )

         if FileExists('hbsx.lib', m_PreSetLib ) 
            AADD( aLines, 'hbsx.lib +    ' )
         end
         if FileExists('hbsix.lib', m_PreSetLib ) 
            AADD( aLines, 'hbsix.lib +    ' )
         end

         if FileExists('pcrepos.lib', m_PreSetLib ) 
            AADD( aLines, 'pcrepos.lib +    ' )
         end
         if FileExists('hbole.lib', m_PreSetLib ) 
            AADD( aLines, 'hbole.lib +    ' )
         end
      end      
   
      if SameText( RDD1, 'sim' )   
         AADD( aLines, ApplyMacros( 'sqllib_($hV).lib + ') )
         AADD( aLines, 'libmysql.lib +')
      end   
   end   
   
   /*
    * Incluimos os arquivos .LIB no projeto. O segundo parametro .T. indica que
    * queremos TODOS os arquivos ATÉ MESMO AQUELES MARCADOS com a opção 
    * compile=FALSE, por isto usamos um parametro .T. 
    *
    * Quando omitimos o segundo parametro, ele puxará apenas os arquivos
    * marcados como COMPILE=TRUE e desde modo, irá ignorar os arquivos .LIB
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