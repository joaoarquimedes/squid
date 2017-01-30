#!/bin/bash

# --> URL de teste
#URL="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download&file=smalltestlist"
#MD5="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=information&file=smalltestlist"

# --> URL de produção
URL="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=download&file=bigblacklist"
MD5="http://urlblacklist.com/cgi-bin/commercialdownload.pl?type=information&file=bigblacklist"

FILE_SAVE="blacklist.tar.gz"

UPDATE() {
   wget "${URL}" -O "${FILE_SAVE}" > /dev/null 2> /dev/null
   if [[ $? -eq 0 ]]
   then
      echo "--> Arquivo ${FILE_SAVE} salvo, descompactando."
      tar -zxf $FILE_SAVE
      if [[ $? -eq 0 ]]
      then
         echo "--> Arquivo descompactado, removendo download ${FILE_SAVE}"
         rm -r ${FILE_SAVE}
         bDir="blacklists/"
         echo "--> Ajustando permissões do diretório $bDir"
         chown -R root. $bDir
         find $bDir -type d -print0 | xargs -0 chmod 775
         find $bDir -type f -print0 | xargs -0 chmod 664
      else
         echo "--> Erro ao descompactar o arquivo ${FILE_SAVE}"
      fi
   else
      echo "--> Erro ao realizar o download do arquivo ${FILE_SAVE}"
      rm -r "${FILE_SAVE}"
   fi
}

CHECK_MD5() {
   echo "--> Checando se houve atualização do arquivo ${FILE_SAVE}"
   url_get=$(wget "$MD5" -q -O -)
   url_md5=$(echo $url_get | cut -d "," -f 2 | sed 's/\"//g')
   loc_fil="local_md5.txt"
   loc_md5=$(cat $loc_fil)

   [[ -e $loc_md5 ]] || touch $loc_fil

   echo "--> MD5 da URL: $url_md5"
   echo "--> MD5 do arquivo local: $loc_md5"
   
   if [[ "$url_md5" != "$loc_md5" ]]
   then
      echo "--> MD5 Diferente, atualizando arquivos"
      echo "$url_md5" > $loc_fil
      UPDATE
   else
      echo "--> MD5 igual, não há necessidade de atualização"
      exit 0
   fi
}

CHECK_MD5
