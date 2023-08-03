/*
 * São Paulo , 16/06/2006 @ 06:36
 * Revisado em 19/08/2006 @ 07:14
 * -----------------------------
 * ClipperBlinker.xCompiler.prg
 *
 * Arquivo contendo os comandos de Script para processamento de um projeto
 * Clipper (em modo console) com o Blinker.
 */
#define CRLF  chr(13)+chr(10)

function Prepare
   return .t.
 
function UnPrepare
   return .f.
 
/*
 * Esta função é executada, sempre que a xDev precisar compilar um arquivo .PRG
 */ 
function OnFilePRG
 * Preparamos a linha de comando
   cmd := 'clipper.exe'
   cmd += ' "' + m_sFileName + '"'
   cmd += ' /o"' + m_sOutPut + '"'
   cmd += ' ' + fMemvar + ' ' + fNoLine + ' ' + fOnlyIt + ' ' + ; 
          ' ' + fNoStrt+ ' ' + fNoOpt  + ' ' + fMakPPO
 *
 * Verificarmos se ele nao quer desativar o DEBUG para este módulo em específico!
 * para isto usamos a funcao SameText() que compara os 2 argumentos ignorando 
 * letras maiúsculas / minúsculas.
 * 
   if !SameText( PRG_DisableDebug, 'sim' )
      cmd += ' ' + fDebug 
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
   cmd += " " + fMiscOption           
 * Executamos o comando específico para compilar 
   runBat(cmd)      
   
   bOk := (ErrorLevel() == 0)
   return bOk
     
function OnBuild   
   Link := fRandom( ".\", ".lnk" )
   Text := "BLINKER EXECUTABLE EXTENDED"+CRLF
   Text += "BLINKER EXECUTABLE ALIGN 64"+CRLF
   Text += "BLINKER INCREMENTAL OFF"+CRLF
   Text += "BLINKER EXECUTABLE NODELETE"+CRLF
   Text += "BLINKER EXECUTABLE CLIPPER  /F:255 /DYNF:8 /SWAPK:65535 /SWAPPATH:'\' /TEMPPATH:'\'"+CRLF
   Text += ""+CRLF
   
   Text += "NOBELL"+CRLF
   Text += "PACKCODE"+CRLF
   Text += "PACKDATA"+CRLF
   Text += ""+CRLF
   
   /*
    * Incluimos os arquivos .OBJ no projeto
    */
   aFiles := Project( "*.OBJ" )
   *alert( aFiles )

   FOR i := 1 TO Len( aFiles )
       Text += "FILE " + aFiles[i] + CRLF
   End
         
   Text += ""+CRLF

   /*
    * Incluimos os arquivos .OBJ no projeto
    */
   aFiles := Project( "*.LIB" )

   FOR i := 1 TO Len( aFiles )
       Text += "LIB " + aFiles[i] + CRLF
   End         

   Text += ""+CRLF
  
 * Testa a versão do clipper atual  
   if isClip53()
      Text += "SEARCH BLXCLP53.LIB     # Blinker library"+CRLF
      
      if SameText(fDebug,'/B')
         Text += "FILE   CLD.LIB"+CRLF
      end
      
   elseif isClip52()
      Text += "SEARCH BLXCLP52.LIB     # Blinker library"+CRLF
      
      if SameText(fDebug,'/B')
         Text += "FILE   CLD.LIB"+CRLF
      end
      
   elseif isClip51()
      Text += "SEARCH BLXCLP51.LIB     # Blinker library"+CRLF
      
      if SameText(fDebug,'/B')
         Text += "FILE   CLD.LIB"+CRLF
      end

   else
      /* Versão do Clipper não suportada */ 
      
   endif
   
   Text += "LIB    CLIPPER          # CA-Clipper library"+CRLF
   Text += "OUTPUT "+m_sOutPut+""+CRLF

   MemoWrite(link,text)   
   runBat("Blinker @" + Link)   
   FErase( Link )
   return ErrorLevel() == 0
