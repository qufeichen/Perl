# simple perl program that adds up sums of integers until integer N (retrieved as input)
#
# for example:
# for N = 3, output = 1 + (1 + 2) + (1 + 2 + 3) = 10
# for N = 4, output = 1 + (1 + 2) + (1 + 2 + 3) + (1 + 2 + 3 + 4) = 20

print "Please enter a N value: \n" ;
$n = <STDIN>;
chop $n;

$sum = 0;

for( $i = 1; $i <= $n; $i = $i + 1 ){

	$temp = 0;
	for( $j = 1; $j <= $i; $j = $j + 1) {
		$temp = $temp + $j;
	}

	$sum = $sum + $temp;

}

print "Total sum: $sum\n";

