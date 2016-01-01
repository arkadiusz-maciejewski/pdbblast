#!/usr/bin/perl -t

use CGI;
$cgi=HTTP_GET_PARAM();
$db="/data/ncbi/db/pdbatom";
$pdbdir="/data/pdb/ent";
$sequence=$HTTP{sequence};
$sequence_file=$HTTP{sequence_file};
$lastchain="0";
while(<$sequence_file>){ $sequence.=$_;}


system ("echo '$sequence'>$$.fas");

system ("blastpgp -i $$.fas -o $$.blast -j 1 -h 0.1 -e 0.1  -C $$.check -v 10000  -K 0 -d $db");

@result=&fileBufArray("$$.blast");
#system ("rm $$.fas $$.blast");

header();

if ($#result<=56) {print "Sorry - no hits found.\n";}

foreach $line (@result) 
{ 
if ($line=~/^>/ or $line=~/^  Database/) 
{ 

    if ($lastpdb) 
	{
	  	
	  $query =~ s/(.{50})/\1\n/g;
	  $query =~ s/([a-zA-Z-]{10})/\1 /g;
	  $sbjct =~ s/(.{50})/\1\n/g;
          $sbjct =~ s/([a-zA-Z-]{10})/\1 /g;		

	print ">Query\n$query\n>$lastpdb$lastchain\n$sbjct\n";
        $query="";
        $sbjct="";
	}	

    $pdb=$chain=$line; $pdb=~s/^>(....)(.).*/$1/; $chain=$2;;
    @pdb=&fileBufArray("$pdbdir/pdb$lastpdb.ent.Z"); 
    my $res,$tmpres,$x=0;
    foreach $pdbline (@pdb) 
	{
	$lastchain=' ' if ($lastchain eq '_');	
	$lastchain=$chain if ($lastchain eq "0"); 
	if ($pdbline=~/^ATOM/ and substr ($pdbline,21,1) eq $lastchain) 
	    {
	    $res=substr($pdbline,23,3);
	    if ($res ne $tmpres) { $x++;}
   	    $tmpres=$res;
	    if ($x>$start-1 and $x<$stop+1) {print "$pdbline $x $start $stop\n";}
	    }
	}
	$lastpdb=$pdb;$lastchain=$chain;$start=9999;$stop=0;	

}

# Identities = 69/200 (34%), Positives = 105/200 (52%), Gaps = 13/200 (6%)


if ($line=~/^\s*Length = (\d*).*/) {print "\nLength = $1\n";}
# Score = 95.9 bits (237), Expect = 8e-20
# Score =  533 bits (1372), Expect = e-152
if ($line=~/^\sScore = (.*).*Expect = (.*)/) {print "Score = $1\nExpect = $2\n";}
if ($line=~/^\s*Identities = \d*\/\d* \((\d*)%\), Positives = \d*\/\d* \((\d*)%\), Gaps = \d*\/\d* \((\d*)%\)/) {print "Identities = $1%\nPositives = $2%\nGapsi = $3%\n";}
if ($line=~/^Query: (\d*)\s*(.*)\s(\d*)/) { $query.=$2;}
if ($line=~/^Sbjct: (\d*)\s*(.*)\s(\d*)/) { $sbjct.=$2;
    if ($1 <= $start) { $start=$1}
    if ($3 >=$stop) {$stop=$3}
    }

}

# Subs #######################################
sub HTTP_GET_PARAM {
    my $cgi=new CGI;
    @Pnames=$cgi->param();
        foreach(@Pnames) {
        $HTTP{$_}=$cgi->param($_);
    }
    return $cgi;
}

sub fileBufArray {
    local $file = shift;
    local $oldsep = $/;
    undef $/;
    if ($file =~ /\.gz|\.Z/) {
        if (! open (FILE, "gzip -dc $file |")) {
#            print ("$0: unable to open file $file for gzip -dc");
        }
    }
    elsif (! open (FILE, $file)) {
#        print ("$0: unable to open file $file for reading");
    }
    local $buf = <FILE>;
    close (FILE);
    $/ = $oldsep;
    @buf = split (/$oldsep/, $buf);
    pop (@buf)  if ($buf[$#buf] eq '');
    return @buf;
}

sub header
{ 
my $q = new CGI;
print $q->header('text/plain');

}
