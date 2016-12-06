# A program that reads grammar from an input file and checks whether it is suitable for building a recursive parser.
# This program checks for (a) direct left recursion and (b) left factors.
# If unsuitable, the program will modify the grammar by removing left recursion and apply left factoring on all rules.
# The program will then write the modified grammar to an output file.
#
# The grammar takes a maximum of two inputs:
# 		The first argument specifies the input grammar file (i.e. 'input.txt')
# 		The second argument (when present) specifies the name/path of the output file where the modified grammar is to be saved.
#		If the second argument is not provided, the modified grammar will be saved to a file named '<input grammar file name>_out.txt'
#
# If the format of the grammar is incorrect, and error message is printed along with a description of the syntax error.


# declare variables
@input = (); # input grammar (lines read in from file)
@midpoint = (); # resulting grammar after removing left recursion; used as input for left factoring loop
@output = (); # final output grammar
$changed = 0; # value to indicate if grammar has been modified


# set output file name
if ($ARGV[1]) {
	$output_filename = $ARGV[1];
	$output_filename =~ s/\.(.*?)$//;
}
else {
	$output_filename = $ARGV[0];
	$output_filename =~ s/\.(.*?)$//;
	$output_filename .= "_out"
}

open CONFIG, $ARGV[$1];

# read in all lines from file
while (<CONFIG>) {
	push (@input, $_);
} 

################################################################################
# 
# RETRIEVE INPUT
# 	- read in lines from file
# 	- trim whitespace and split into left and right hand side
# 	- check syntax
#
################################################################################

# split each rule into the left hand side (non-terminal) and the right hand side (productions)
@lefthands = ();
@righthands = ();

# format input (output result after left factoring)
# remove dashes, excess whitespace, split grammar into left hand side and right hand side
for ($i = 0; $i <@input; $i = $i + 1) {

	# if rule does not contain an arrow, return syntax error
	if ( !($input[$i] =~ /[-]+[>]/)) {
		print "Wrong format for input grammar!\n";
		print "Your input grammar does not contain an arrow.\n";
		exit 1;
	}

	# remove all dashes
	$input[$i] =~ s/-+//;

	# trim all whitespace
	$input[$i] =~ s/\s+/ /g;

	@split = split(/>/, $input[$i]);

	# if left hand side is a lower case letter, return syntax error
	if ($split[0] =~ /^[a-z]/) {
		print "Wrong format for input grammar!\n";
		print "Your input grammar contains a lowercase non-terminal.\n";
		exit 1;
	}

	# if a terminal (starting with lowercase letter) does not have all characters in lowercase, return syntax error
	if ($split[1] =~ /\b[a-z][a-z]*[A-Z]+/) {
		print "Wrong format for input grammar!\n";
		print "Your input grammar contains a terminal with an uppercase character.\n";
		exit 1;
	}

	push(@lefthands, $split[0]);
	push(@righthands, $split[1]);

}


################################################################################
# 
# REMOVE LEFT RECURSION
# 	- remove left recursion
#
################################################################################

# loop through all rules, one line at a time
for ( $i = 0; $i <@lefthands; $i = $i + 1) {

	# split righthands into distict productions (each separated by |)
	@productions = split(/\|/, $righthands[$i]);

	# check for left recursion on all productions

	#split each production into first term, and other terms
	@first_terms = ();
	@other_terms = ();

	for ($j = 0; $j < @productions; $j = $j + 1) {
		# separate production into first-term and other terms
		# store first term of production in @first_term, and the rest in @other_terms

		# trim leading/trailing whitespace
		$productions[$j] =~ s/^\s+|\s+$//g;

		# split on the first whitespace
		@p_split = split(/\s/, $productions[$j], 2);

		push(@first_terms, $p_split[0]);
		push(@other_terms, $p_split[1]);

	}

	# left recursion occurs when the first term of a production is the same as it's left hand side
	# compare the left hand side of each rule with the first term of all of it's productions
	
	@recursion_productions = ();
	@other_productions = ();
	$recursion_term = undef;

	#
	# loop through first terms of all productions
	#
	for ($j = 0; $j < @first_terms; $j = $j + 1) {
		
		# trim whitespace
		$lefthands[$i] =~ s/^\s+|\s+$//g;

		if ($lefthands[$i] eq $first_terms[$j]) {
			
			# left recursion is present on this term
			# add the tail end of term to recursion productions array
			push (@recursion_productions, $other_terms[$j]);

		}
		else {
			# no left recursion on this term
			# add term to other productions array
			push (@other_productions, $first_terms[$j] . " " . $other_terms[$j]);
		}

	}

	# test to see if we need to remove left recursion
	if (@recursion_productions) {

		# set changed variable to true
		# indicates that this grammar was modified
		if (!$changed) {
			$changed = 1;
		}

		# modify the original rule

		# trim leading/trailing whitespace
		$other_productions[0] =~ s/^\s+|\s+$//g;
		# construct rule
		$modified_rule = $lefthands[$i] . " -> " . $other_productions[0] . " " . $lefthands[$i] . "Prime" ;

		for ($j = 1; $j < @other_productions; $j = $j + 1) {
			$other_productions[$j] =~ s/^\s+|\s+$//g;
			$modified_rule = $modified_rule . " | " . $other_productions[$j] . " " . $lefthands[$i] . "Prime";
		}

		# generate new rule

		# trim leading/trailing whitespace
		$recursion_productions[0] =~ s/^\s+|\s+$//g;
		# generate rule
		$new_rule = $lefthands[$i] . "Prime -> " . $recursion_productions[0] . " " . $lefthands[$i] . "Prime";
		
		for ($j = 1; $j < @recursion_productions; $j = $j + 1) {
			$recursion_productions[$j] =~ s/^\s+|\s+$//g;
			$new_rule = $new_rule . " | " . $recursion_productions[$j] . " " . $lefthands[$i] . "Prime";
		}
		# add epsilon
		$new_rule = $new_rule . " | epsilon";

		# add rules to midpoint output
		push (@midpoint, $modified_rule);
		push (@midpoint, $new_rule);

	} 
	else {

		# no left recursion
		# add rule directly to output

		# cut excess whitespace
		$lefthands[$i] =~ s/\s+//g;
		$righthands[$i] =~ s/^\s+//g;

		push (@midpoint, $lefthands[$i] . " -> " . $righthands[$i]);
	}

}


#################################################################################
# 
# LEFT FACTORING
# 	- check for left factoring on all right hand side productions of each rule
#
#################################################################################

@lefthands = ();
@righthands = ();

# format input
# remove dashes, excess whitespace, split grammar into left hand side and right hand side
for ($i = 0; $i <@midpoint; $i = $i + 1) {

	# remove all dashes
	$midpoint[$i] =~ s/-+//;

	# remove all whitespace
	# $input[$i] =~ s/\s+//g;

	# trim all whitespace
	$midpoint[$i] =~ s/\s+/ /g;

	@split = split(/>/, $midpoint[$i]);

	push(@lefthands, $split[0]);
	push(@righthands, $split[1]);

}


# loop through all rules, one line at a time
for ( $i = 0; $i <@lefthands; $i = $i + 1) {

	# split righthands into distict productions (each separated by |)
	@productions = split(/\|/, $righthands[$i]);

	# check for left factoring on all productions

	#split each production into first term, and other terms
	@first_terms = ();
	@other_terms = ();

	for ($j = 0; $j < @productions; $j = $j + 1) {
		# separate production into first-term and other terms
		# store first term of production in @first_term, and the rest in @other_terms

		# trim leading/trailing whitespace
		$productions[$j] =~ s/^\s+|\s+$//g;

		# split on the first whitespace
		@p_split = split(/\s/, $productions[$j], 2);

		push(@first_terms, $p_split[0]);
		push(@other_terms, $p_split[1]);

	}

	# we need to left factor when the first term of two or more productions are the same
	# compare the first term of each production with the first term of all other productions
	
	@factored_productions = ();
	@other_productions = ();
	$factor_term = undef;

	# initialize index array to all 0
	# index array will store a 0 if that production has not been accounted for yet
	# if production has already been accounted for, index array will store 1
	@index = (0) x @productions;

	#
	# loop through first terms of all productions
	#
	for ($j = 0; $j < @first_terms; $j = $j + 1) {

		# check index to see if production has already been tested
		# only enter loop if production has not yet been looked at
		if (!$index[$j]) {

			# boolean to indicate if this term needs leftfactoring
			$left_factor = 0;

			# current term
			# trim whitespace
			($current_term = $first_terms[$j]) =~ s/\s+//g;

			# loop through first terms of all productions after the current one
			for ($k = $j + 1; $k < @first_terms; $k = $k + 1) {
				
				# comparison term
				# trim whitespace
				($comparison_term = $first_terms[$k]) =~ s/\s+//g;

				# if the current term and the comparison term are equal, then we need to left factor
				if ($current_term eq $comparison_term) {

					# can only do one factoring per iteration
					# therefore we need to keep track of what the current factor_term is
					# if the factor term is uninitialized, initialize it
					if (!$factor_term) {
						$factor_term = $current_term;
					}

					# only perform left factoring if the current term is the factor term
					if ($current_term eq $factor_term) {

						# if this is the first term that needs factoring
						if ($left_factor == 0) {

							$left_factor = 1;
							
							# add this term to the factored productions array
							# check if it's ending is empty; if empty, add epsilon
							if ($other_terms[$j] =~ /^\s*$/) {
								push (@factored_productions, "epsilon");
							} 
							else {
								push (@factored_productions, $other_terms[$j]);
							}

						}

						# add the second term to the factored productions array
						# check if it's ending is empty; if empty, add epsilon
						if ($other_terms[$k] =~ /^\s*$/) {
							push (@factored_productions, "epsilon");
						} 
						else {
							push (@factored_productions, $other_terms[$k]);
						}

						# update index for current term and comparison term
						$index[$j] = 1;
						$index[$k] = 1;
					} 
				}
				else {
					# the current term does not need to be factored
					# update index
					$index[$j] = 1;
				}
			}

			# if there is no need to left factor this production
			# save this production the way it is into other_productions
			if ($left_factor == 0) {
				push (@other_productions, $first_terms[$j] . " " . $other_terms[$j]);
			}

		}

	}


	# check to see if terms have been added to the factored productions array
	# if array is not empty, then we must factor and create a new rule
	if (@factored_productions) {

		# set changed variable to true
		# indicates that this grammar was modified
		if (!$changed) {
			$changed = 1;
		}

		# cut whitespace from lefthand item
		$lefthands[$i] =~ s/\s+//g;

		# modify the original rule
		$modified_rule = $lefthands[$i] . " -> " . $factor_term ." ".$lefthands[$i]."Prime";
		# add productions that were not factored to the rule
		for ($k = 0; $k < @other_productions; $k = $k + 1) {
			$modified_rule = $modified_rule . " | " . $other_productions[$k];
			print "other production: $other_productions[$k]\n";

		}

		# generate new rule
		$new_rule = $lefthands[$i] . "Prime -> " . $factored_productions[0];
		# add productions that were factored to the new rule
		for ($k = 1; $k < @factored_productions; $k = $k + 1) {
			$new_rule = $new_rule . " | " . $factored_productions[$k];
		} 

		# add modified rule and new rule to the output
		push (@output, $modified_rule);
		push (@output, $new_rule);
	} 
	else {
		# no need to left factor
		# save the rule the way it is into output

		#cut excess whitespace
		$lefthands[$i] =~ s/\s+//g;
		$righthands[$i] =~ s/^\s+//g;

		push (@output, $lefthands[$i] . " -> " . $righthands[$i]);
	} 

}


#################################################################################
# 
# OUTPUT
# 	- If grammar was modified (changed == 1), save new grammar to output file
# 	- else, display "Input grammar OK"
#
#################################################################################

if ($changed) {

	# set output file name
	my $output_file = $output_filename . ".txt";

	# create the output file
	unless(open FILE, '>'.$output_file) {
	    die "Cannot to create $output_file\n";
	}

	for ($i = 0; $i < @output; $i = $i + 1) {
		print FILE "$output[$i]\n";
	}

	# close file
	close FILE;

	# print success message
	print "Grammar has been modified, and saved to $output_filename.txt\n";


	# # FOR TESTING
	# # prints the output of the modified grammar to console
	#
	# print "\nOutput after removing left recursion and left factoring:\n\n";
	# for ($i = 0; $i < @output; $i = $i + 1) {
	# 	print "$output[$i]\n";
	# }
	# print "\n";
	# print "Grammar has been modified, and saved to $output_filename.txt\n";

}
else {
	print "Input grammar OK.\n"
}
