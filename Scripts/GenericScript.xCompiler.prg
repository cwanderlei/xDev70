/*
 * S�o Paulo, 21/8/2006 @ 11:23:47
 * Revisado em 21/8/2006 @ 11:23:55
 * -----------------------------
 * GenericScript.xCompiler.prg
 *
 * Arquivo contendo os comandos de Script para processamento de um projeto
 * Gen�rico, que ser� compilado e linkado usando-se um script externo.
 *    
 * O detalhe incomodo neste caso � que se o usuario quiser visualizar o processo,
 * a xDev utilizar� outro procedimento alternativo, QUE nao atribui as variaveis
 * de ambiente tais como SET PATH, SET INCLUDE, SET LIB, etc. (por enquanto...)
 *
 * Um coment�rio importante sobre este script � que nenhum comando adicional
 * ser� executado. Nem mesmo o compilador ser� executado, sendo assim por padrao 
 * o arquivo em anexo (que geralmente � um arquivo de lote .BAT) deve se encarregar
 * de chamar o MAKE.EXE e tb o LINKER.
 */
#define SW_SHOWNORMAL 1

function OnBuild  
   if Empty( fCmd )
      MsgError("Voc� deve especificar o nome do arquivo externo (.BAT,.CMD,.PIF,.EXE,.COM) que ser� executado para completar o processo de compila��o. Clique em PROJETO > PROPRIEDADES e informe o nome do arquivo externo para corrigir isto.")
      return .f.
   end
 *
 * O usu�rio quer rodar vendo progresso?
 *
   if SameText(fStyle, 'Sim')
      __Run( fCmd, SW_SHOWNORMAL )

 * Nao..., podemos ocultar o processo
   else
      __Run( fCmd)

   end   
   return ErrorLevel() == 0