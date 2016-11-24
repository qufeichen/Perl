# simple perl program that uses the linux diff command to make sure there are no duplicates in a list of files
# takes the file names of two files to be compares as parameters 

for ($i = 0; $i < @ARGV; $i++) {

	# prints name of first file being compared
	print "first file: $ARGV[$i]\n";

	for ($j = $i + 1; $j < @ARGV; $j++) {
		
		# prints name of second file being compared
		print "second file: $ARGV[$j]\n";

		my $return_value = `diff $ARGV[$i] $ARGV[$j]`;
		print $return_value;

	}
}
