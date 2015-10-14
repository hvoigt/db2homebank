#!/usr/bin/perl
#
# Convert csv files from German Deutsche Bank to HomeBank csv format
# Copyright (C) 2015  Heiko Voigt
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Usage:
#
# 	dp2homebank.pl <filename> ><outputfilename>
#

use strict;
use warnings;
#use encoding "iso 8859-1";
use open qw( :encoding(iso8859-1) :std );

use Text::CSV;

sub convert_date {
	my ($day, $month, $year) = split('\.', $_[0]);
	$year =~ s/^20//;
	return "$day-$month-$year";
}

my $csv = Text::CSV->new({ sep_char => ';' });
my $csv_out = Text::CSV->new({ sep_char => ';' });
my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";

open(my $data, '<', $file) or die "Could not open '$file' $!\n";
my $linenumber = 0;
while (my $line = <$data>) {
	chomp $line;

	if ($linenumber < 5) {
		$linenumber++;
		next;
	}

	if ($csv->parse($line)) {
		my @fields = $csv->fields();

		if ($fields[0] =~ m/^Kontostand/) {
			$linenumber++;
			next;
		}

		my ($buchungstag, $wert, $umsatzart, $auftraggeber,
			$verwendungszweck, $iban, $bic, $kundenreferenz,
			$mandatsreferenz, $glaeubiger_id,
			$fremde_gebuehren, $betrag,
			$abweichender_empfaenger, $anzahl_auftraege,
			$soll, $haben, $waehrung) = @fields;

		my $date = convert_date($buchungstag);
		my $paymode = 0;
		my $info = "";
		my $payee = $auftraggeber;
		my $memo = $verwendungszweck;
		my $amount = '';
		if ($soll ne '') {
			$amount = $soll;
		} else {
			$amount = $haben;
		}
		my $category = "";
		my $tags = "";

		my @out_fields = ($date, $paymode, $info, $payee, $memo,
			$amount, $category, $tags);

		if ($csv_out->combine(@out_fields)) {
			my $string = $csv_out->string;
			print "$string\n";
		} else {
			my $err = $csv_out->error_input;
			print "combine() failed on argument: ", $err, "\n";
		}
	}
	$linenumber++;
}

close($data);
