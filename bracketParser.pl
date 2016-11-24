# perl micro-parser that checks if a file containing only brackets is well balanced
# file containing brackets taken as parameter
# checks for the balance of the following brackets: () [] <> {}

@stack = ();

while (<>) {

	if ( $_ =~ /\(|\[|{|</ ) {
		push (@stack, $_);
	} 

	elsif ( $_ =~ /\)|\]|}|>/ ) {

		if ( ($stack[-1] =~ /\(/) && ($_ =~ /\)/) ) {
			pop(@stack);
		} 
		elsif ( ($stack[-1] =~ /\[/) && ($_ =~ /\]/) ) {
			pop(@stack);
		} 
		elsif ( ($stack[-1] =~ /{/) && ($_ =~ /}/) ) {
			pop(@stack);
		} 
		elsif ( ($stack[-1] =~ /</) && ($_ =~ />/) ) {
			pop(@stack);
		}
		else {
			push (@stack, $_);
		}
	}

}

if (@stack) {
	print "The brackets in this file are not balanced.\n";
} else {
	print "The brackets in this file are balanced.\n";
}

