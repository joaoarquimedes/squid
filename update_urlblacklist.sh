#!/bin/bash
#
# Este script tem por objetivo checar periodicamente as atualizações disponíveis das listas
# negras da URL http://urlblacklist.com e atualizar os arquivos locais.

# --> URL de teste
#URL="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download&file=smalltestlist"
#MD5="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=information&file=smalltestlist"

# --> URL de produção
URL="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download&file=bigblacklist"
MD5="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=information&file=bigblacklist"

FILE_SAVE="blacklist.tar.gz"
DATESTAMP() { date +"%Y/%m/%d %H:%M:%S" ; }

# Obtendo MD5 disponível pelo site
url_md5=$(wget "$MD5" -q -O - | cut -d "," -f 2 | sed 's/\"//g')


UPDATE() {
   wget "${URL}" -O "${FILE_SAVE}" > /dev/null 2> /dev/null
   if [[ $? -eq 0 ]]
   then
      file_md5=$(md5sum ${FILE_SAVE} | cut -d " " -f 1)
      echo "$(DATESTAMP) --> MD5 do arquivo ${FILE_SAVE}: ${file_md5}"
      if [[ "$url_md5" != "$file_md5" ]]
      then
         echo "$(DATESTAMP) --> Download do arquivo ${FILE_SAVE} incompleto, MD5 diferente. Saindo do script"
         exit 1
      fi

      bDir="blacklists/"
      echo "$(DATESTAMP) --> Limpando diretório $bDir"
      mv $bDir /tmp/

      echo "$(DATESTAMP) --> Arquivo ${FILE_SAVE} salvo, descompactando."
      tar -zxf $FILE_SAVE > /dev/null 2> /dev/null
      if [[ $? -eq 0 ]]
      then
         echo "$(DATESTAMP) --> Arquivo descompactado, removendo download ${FILE_SAVE}"
         rm -r ${FILE_SAVE}
         echo "$(DATESTAMP) --> Ajustando permissões do diretório $bDir"
         chown -R root. $bDir
         find $bDir -type d -print0 | xargs -0 chmod 775
         find $bDir -type f -print0 | xargs -0 chmod 664
      else
         echo "$(DATESTAMP) --> Erro ao descompactar o arquivo ${FILE_SAVE}"
         rm -r "${FILE_SAVE}"
      fi
   else
      echo "$(DATESTAMP) --> Erro ao realizar o download do arquivo ${FILE_SAVE}"
      rm -r "${FILE_SAVE}"
   fi
}

CHECK_MD5() {
   echo "$(DATESTAMP) --> Checando se houve atualização do arquivo ${FILE_SAVE}"

   loc_fil="local_md5.txt"
   [[ ! -e $loc_fil ]] && touch $loc_fil
   loc_md5=$(cat $loc_fil)

   echo "$(DATESTAMP) --> MD5 da URL: $url_md5"
   echo "$(DATESTAMP) --> MD5 do arquivo local: $loc_md5"
   
   if [[ "$url_md5" != "$loc_md5" ]]
   then
      echo "$(DATESTAMP) --> MD5 Diferente, atualizando arquivos"
      echo "$url_md5" > $loc_fil
      UPDATE
   else
      echo "$(DATESTAMP) --> MD5 igual, não há necessidade de atualização"
      exit 0
   fi
}

CHECK_MD5
