use strict;
use warnings;
use 5.010;
open(FIN,">Resultado");
print FIN ("\t   Instancia\tlc\tex\n");
my @names =("a05100","a05200","a10100","a10200","a20100","a20200","b05100","b05200","b10100","b10200","b20100","b20200","c05100","c05200","c10100","c10200","c10400","c15900","c20100","c20200","c20400","c30900","c40400","c60900","c201600","c401600","c801600","d05100","d05200","d10100","d10200","d10400","d15900","d20100","d20200","d20400","d30900","d40400","d60900","d201600","d401600","d801600","e05100","e05200","e10100","e10200","e10400","e15900","e20100","e20200","e20400","e30900","e40400","e60900","e201600","e401600","e801600");
my $n_lc = 0;
my $n_ex = 0;
for($n_lc=50;$n_lc<=150;$n_lc+=10){
	foreach my $n (@names){
	    for($n_ex=1;$n_ex<=5;$n_ex++){
		print FIN ("exp. $n lc: $n_lc n_ex: $n_ex\n");
		close(FIN);
		print("executando instancia $n pela $n_ex com lc $n_lc");
		system("./m $n $n_lc >>Resultado");
		open(FIN,">>Resultado");
	    }
	} 	
}
exit;

   


