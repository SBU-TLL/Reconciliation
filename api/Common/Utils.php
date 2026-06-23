<?php

class Utils
{
    function codeName($eppn){
        $netid=explode("@", $eppn);
        $vowels=["a","e","i","o","u","y"];
        $consonants =['b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'z'];
        $chars = str_split($netid[0]);
        $out="";
        
        foreach ($chars as $char) {
        $vowel=array_search($char,$vowels);
        $consonant=array_search($char,$consonants);
        
        if($vowel!==false){
            $index= ($vowel+1)%(count($vowels));
            $out.=$vowels[$index];
        }
        else{
            $index= ($consonant+4)%(count($consonants));
            $out.=$consonants[$index];
        }
        }
          return $out;
        }

}
