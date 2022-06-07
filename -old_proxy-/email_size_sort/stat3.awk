#
#   Mail Stat
##
        { 
	  split($5,A,"<|>");
	  S1=A[2];
	  split($6,A,"=|,");
	  S3=A[2];
          i=split($7, A, "=|,");
          for (j=2; j<i; j++)
	    {
	     A1=index(A[j],"<");		
	     split(A[j],SS,"<|>");
	     if (A1 == 0) {S2=A[j]} else {S2=SS[2]};
	     A1=index(S2,"@");		
	     if (A1 == 0) {S2=S2 "@nkmz.donetsk.ua"} else {};
   	     pop[$2 " " $3 " " $4 ";" S1 ";" S2 ";" S3];
	    }	  
	}
END 	{ for ( cc in pop ) 
	{print cc pop[cc] | "sort -n"} }
