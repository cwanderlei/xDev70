/*
 * São Paulo, 21/8/2006 @ 11:23:47
 * Revisado em 21/8/2006 @ 11:23:55
 * -----------------------------
 * GenericScript.xCompiler.prg
 *
 * Arquivo contendo os comandos de Script para processamento de um projeto
 * Genérico, que será compilado e linkado usando-se um script externo.
 *    
 * O detalhe incomodo neste caso é que se o usuario quiser visualizar o processo,
 * a xDev utilizará outro procedimento alternativo, QUE nao atribui as variaveis
 * de ambiente tais como SET PATH, SET INCLUDE, SET LIB, etc. (por enquanto...)
 *
 * Um comentário importante sobre este script é que nenhum comando adicional
 * será executado. Nem mesmo o compilador será executado, sendo assim por padrao 
 * o arquivo em anexo (que geralmente é um arquivo de lote .BAT) deve se encarregar
 * de chamar o MAKE.EXE e tb o LINKER.
 */
#define SW_SHOWNORMAL 1

function OnBuild  
   if Empty( fCmd )
      MsgError("Você deve especificar o nome do arquivo externo (.BAT,.CMD,.PIF,.EXE,.COM) que será executado para completar o processo de compilação. Clique em PROJETO > PROPRIEDADES e informe o nome do arquivo externo para corrigir isto.")
      return .f.
   end
 *
 * O usuário quer rodar vendo progresso?
 *
   if SameText(fStyle, 'Sim')
      __Run( fCmd, SW_SHOWNORMAL )

 * Nao..., podemos ocultar o processo
   else
      __Run( fCmd)

   end   
   return ErrorLevel() == 0