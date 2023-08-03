/*
 * São Paulo , 16/06/2006 @ 06:36
 * Revisado em 1/10/2006 10:49:31
 * -----------------------------
 * MiniGUI.xCompiler.prg
 *
 * Arquivo contendo os comandos de Script para processamento de um projeto
 * Harbour/MiniGUI com Borland BCC ou MinGW.
 */
#define CRLF Chr(13)+Chr(10)

function Prepare
   type := Project( 'TargetType' )
   bcc  := !isMinGW()
   
   if FileExists( 'harbour.exe', m_PreSetPath ) .or. ;
      FileExists( 'hb.exe', m_PreSetPath )
      *
   else
      MsgError( 'O arquivo principal do compilador não existe!' )
      return .f.
   end

   if bcc    
      if !FileExists( 'bcc32.exe', m_PreSetPath )
         MsgError( 'O arquivo requerido BCC32.EXE não foi localizado no sistema!' )
         return .f.
      end
       
      if !FileExists( 'ilink32.exe', m_PreSetPath )
         MsgError( 'O arquivo requerido ILINK32.EXE não foi localizado no sistema!' )
         return .f.
      end
   else
      if !FileExists( 'gcc.exe', m_PreSetPath )
         MsgError( 'O arquivo requerido GCC.EXE não foi localizado no sistema!' )
         return .f.
      end
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
   cmd   := ''

   for i := 0 to len( aDefs )
       if !Empty(aDefs[i])
          AAdd( aLines, '-D' + aDefs[i])
       end
   next

 * Ajustamos os outros parametros
   if Bcc
      AAdd( aLines, '-I"' + m_PreSetInclude +'"')
      AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '"')
      AAdd( aLines, '-o"' + m_sOutPut + '"')
      AAdd( aLines, '"' + m_sFileName + '"')

    * Salvamos o comando de compilação.
      MemoWrite( 'b32.bc', aLines )
      cmd := 'BCC32 -M -c @B32.BC'
   else
      AAdd( aLines, '-I.')
      Temp := ListAsArray(m_PreSetInclude,';')
      
      FOR i := 1 TO Len(Temp)
          if !Empty(Temp[i])
             AAdd( aLines, '-I"'+Temp[i]+'"')
          end
      next
      
      *AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '"')
      AAdd( aLines, '-mno-cygwin -Wall') 
      AAdd( aLines, '-c "' + m_sFileName + '"')
      AAdd( aLines, '-o"' + m_sOutPut + '"')
   
    * Salvamos o comando de compilação.
      cmd := 'gcc ' + ListAsText(aLines,' ') // esta funcao converte o array para string
   end
   
 * Executamos o comando específico para compilar...
   runBat( cmd )

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

/*
 * Este método é oq gera o .EXE! As rotinas e funções alistadas neste .PRG deste
 * ponto para cima, nao sofreran alteração. O detalhe específico da MiniGUI entra
 * agora!!
 */     
function OnBuild
   if SameText( type, 'LIB' ) .or. ;     
      SameText( type, 'DLL' )

      MsgError( 'A geração de um arquivo "'+m_sOutPut+'" conforme solicitado por este projeto não é atualmente suportada!' )           
      return .f.
   end              
   
   if Bcc           
      return BuildExeBCC()
   else
      return BuildExeGCC()
   end

/*
 * 30/08/2006 @ ??:??
 * Script de compilação da MiniGUI 
 * com Borland C++ Compiler
 */
function BuildExeBCC()   
 * Preparamos a linha de comando
   aLines  := {}

   AAdd( aLines, '-I"' + m_PreSetInclude +'" +')
   AAdd( aLines, '-L"' + m_PreSetLib + ';' +m_PreSetObj + '" +')
   
 * Usamos sempre a função SAMETEXT() pq ela compara removendo os espaços e 
 * ignorando maiúsculas e minúsculas
   if !SameText( fForceCON, 'Sim' )
      AADD( aLines, '-aa +' )
   end
                                        
   AADD( aLines, ' -Gn -Tpe +' )   
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
      AADD( aLines, 'UPX.EXE "'+m_sOutPut + '"' )      
      
      cmd := ListAsText( aLines )  
      runBat( cmd )
              
      bOk := (ErrorLevel() == 0)
   end   
   return bOk

/*
 * 01/10/2006 10:50:25
 * Script de compilação da MiniGUI 
 * com MinGW C++ Compiler
 */
function BuildExeGCC()
//gcc -Wall -o%1.exe %1.o %MINIGUI_INSTALL%\resources\minigui.o -mwindows -L%MINGW%\lib -L%HRB_DIR%\lib -L%MINIGUI_INSTALL%\lib -mno-cygwin -Wl,--start-group -lminigui -lhbsix -lvm -lrdd -lmacro -lpp -lrtl -lpp -llang -lcommon -lnulsys  -ldbfntx  -ldbfcdx -ldbffpt -lgtwin -luser32 -lwinspool -lcomctl32 -lcomdlg32 -lgdi32 -lole32 -loleaut32 -luuid -lwinmm -lvfw32 -lwsock32 -lct -lmisc -lhbodbc -lodbc32  -lsocket  -lmysql -lmysqldll -lgraph -ledit -lreport -lini -leditex -lcrypt -ldll -lhbole -lregistry -lcodepage -Wl,--end-group
//gcc -I. -I%HRB_DIR%\include -mno-cygwin -Wall -c %1.c -o%1.o
   return .T.
   
/*
 * Script adaptado da HMG EXP 1.9
 */
function DefaultLibs()
   if SameText( CustomLIBs, 'Sim')
      /*
       * Se ele tem a lista de LIBs personalizadas não preenchemos isto...
       */
   else
    * Se for HB a lista de LIBs muda, então...
      if isHarbour()
         
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
         
      else
         AADD( aLines, 'tsbrowse.lib + ')     
         //AADD( aLines, 'minigui.lib +  ')     
         AADD( aLines, 'dll.lib +      ')     
         AADD( aLines, 'rtl.lib +      ')     
         AADD( aLines, 'vm.lib +       ')     
   
         if FileExists('gtgui.lib', m_PreSetLib ) 
            AADD( aLines, 'gtgui.lib + ')
         else
            AADD( aLines, 'gtwin.lib + ')
         end
   
         AADD( aLines, 'lang.lib +     ')     
         AADD( aLines, 'codepage.lib + ')     
         AADD( aLines, 'macro.lib +    ')     
         AADD( aLines, 'rdd.lib +      ')
         AADD( aLines, 'dbfntx.lib +   ')
              
         if SameText( RDD2, 'sim' )   
            AADD( aLines, 'dbfcdx.lib +   ' )
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
                    
         if SameText( RDD1, 'sim' )   
            AADD( aLines, ApplyMacros( 'sqllib_($hV).lib + ') )
            AADD( aLines, 'libmysql.lib +')
         end   
         
         AADD( aLines, 'common.lib +   ')     
         AADD( aLines, 'pp.lib +       ')     
      end      
   
      if SameText( fFlagB, '/B' )
         AADD( aLines, 'debug.lib + ' )
      end
   
      if FileExists('ct.lib', m_PreSetLib ) 
         AADD( aLines, 'ct.lib +       ')     
      end
   
      if FileExists('hbct.lib', m_PreSetLib ) 
         AADD( aLines, 'hbct.lib +     ')     
      end
   
      cFile := FindFile('hbprinter.lib', m_PreSetLib )
      if !Empty( cFile ) 
         AADD( aLines, cFile + ' +')
      end
   
      cFile := FindFile('miniprint.lib', m_PreSetLib )
      if !Empty( cFile ) 
         AADD( aLines, cFile + ' +')
      end
   
      if FileExists('socket.lib', m_PreSetLib ) 
         AADD( aLines, 'socket.lib +   ')
      end
   
      if SameText( RDD4, 'sim' )
         AADD( aLines, 'hbodbc.lib +')
         AADD( aLines, 'odbc32.lib +')
      end
      
      if SameText( fUseHMGZIP, 'sim')
         AADD( aLines, 'zlib1.lib +')
         AADD( aLines, 'ziparchive.lib +')
      end
      
      if SameText( RDD3, 'sim' )   
         AADD( aLines, 'rddads.lib +')
         AADD( aLines, 'ace32.lib +')
      end
   
      if SameText( fUseHMGMySQL, 'sim')
         AADD( aLines, 'mysql.lib +')
         AADD( aLines, 'libmysql.lib +')
      end
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