use strict;
use warnings;
use 5.010;
open(FIN,">Resultado");
print FIN ("\t   Instancia\tlc\tex\n");
my @names =("e401600","e801600");
my $n_lc = 0;
my $n_ex = 0;
	foreach my $n (@names){
	    for($n_ex=1;$n_ex<=5;$n_ex++){
		print FIN ("exp. $n lc: $n_lc\n");
		close(FIN);
		print("executando instancia $n pela $n_ex\n");
		system("./m $n >>Resultado");
		open(FIN,">>Resultado");
	    }
	} 	
exit;

   


