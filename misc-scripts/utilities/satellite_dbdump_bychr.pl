#!/usr/local/bin/perl
# 
# $Id$
# 
#

=head1 NAME

 sattelite_dbdump_bychr

=head1 SYNOPSIS

  This script generates a dump of an EnsEMBL satellite database for
  particular chromosome. Useful to create a small but fully functional
  ensembl installation, e.g. for a laptop. It needs access to an ensembl-lite
  database (for golden path etc.)

  (1) Needs to be called within a new directory where you want
     all the files to be written

  (2) with a user that is allowed to use mysqldump

  (3) needs to be run on the host that runs the daemon

  (4) Usage: 

       satellite_dbdump_bychr  -<dbtype> <dbinstance>
  
     e.g
  
       satellite_dbdump_bychr  -disease homo_sapiens_disease_110

     Known types are: family disease maps expression est # snp 

=head1 DESCRIPTION

This script generates a full dump of one or several EnsEMBL sattelite
database for a particular chromosome. Useful to create a small but fully
functional EnsEMBL db (e.g. laptop mini-mirror) 

Based on make_dbdumpk_bychr (which should be used for the core, embl and
EST database. embl is a problem still, however.

=cut

;

use Bio::EnsEMBL::DBLoader;
use Getopt::Long;

my $workdir = `pwd`; chomp($workdir);
my $host = "localhost";
my $port   = '';
my $litedb = ''; # 'homo_sapiens_lite_110'; # force user to provide it
my $dbuser = 'ensadmin';
my $dbpass = undef;
my $module = 'Bio::EnsEMBL::DBSQL::DBAdaptor';
my $chr = 'chr21';                      # smaller than chr22
# my $lim;
my $mysql = 'mysql'; 
my $mysqldump = 'mysqldump'; # in $PATH we trust
#                  /mysql/current/bin/mysqldump

# satellites:
my $famdb;
my $diseaseb;
my $mapsdb;
my $expressiondb;
my $estdb;
my $snpdb;
# end of satellites

&GetOptions( 
            'port:n'     => \$port,
            'litedb:s'   => \$litedb,
            'dbuser:s'   => \$dbuser,
            'dbpass:s'   => \$dbpass,
            'module:s'   => \$module,
            'chr:s'      => \$chr,
            'workdir:s'  => \$workdir,
            'limit:n'    => \$lim,
            'family:s' => \$famdb,
            'disease:s' => \$diseasedb,
            'maps:s' => \$mapsdb,
            'expression:s' => \$expressiondb,
            'est:s' => \$estdb,
            'snp:s' => \$snpdb,
           );

die "need a litedb; use -litedb something " unless $litedb;
die "chromosome names should start with 'chr'" unless $chr =~ /^chr/;
my $pass_arg=""; $pass_arg="-p$dbpass" if $dbpass;

my $limit;
if ($lim) {
    $limit = "limit $lim";
}

&dump_family($famdb);
&dump_disease($diseasedb);
&dump_maps($mapsdb);
&dump_expression($expressiondb);
&dump_snp($snpdb);

&dump_est($estdb);

sub dump_family { 
    my ($satdb) = @_;
    return unless $satdb;

    dump_schema($satdb);

    my $sql;
    $sql = "
SELECT distinct f.* 
FROM $satdb.family f, $litedb.gene g
WHERE g.chr_name = '$chr'
  and g.family = f.id
  $limit
";
    dump_data($sql, $satdb, 'family' );

    $sql = "
SELECT fm.* 
FROM $satdb.family_members fm, $satdb.family f, $litedb.gene g
WHERE g.chr_name = '$chr'
  and g.family = f.id
  and f.internal_id  = fm.family
  $limit
";
    dump_data($sql, $satdb, 'family_members' );
}                                       # family

sub dump_disease {
    my ($satdb) = @_;
    return unless $satdb;

    dump_schema($satdb);

# may need an ALTER TABLE gene ADD KEY(gene_symbol);
    my $sql;
    $sql = "
SELECT dg.*
FROM  $satdb.gene dg, 
      $litedb.gene lg, 
      $litedb.gene_xref lgx
WHERE lg.chr_name = '$chr' 
  AND lg.gene = lgx.gene 
  AND lgx.display_id = dg.gene_symbol
";
    dump_data($sql, $satdb, 'gene' );

    $sql = "
SELECT dd.*
FROM  $satdb.gene dg, 
      $satdb.disease dd,
      $litedb.gene lg, 
      $litedb.gene_xref lgx
WHERE lg.chr_name = '$chr' 
  AND lg.gene = lgx.gene 
  AND lgx.display_id = dg.gene_symbol
  AND dd.id = dg.id;
";
    dump_data($sql, $satdb, 'disease' );

# here's the sql to restrict the disease_index_*list, but they're so small
# it's really not worth the trouble. Left here in case anyone is interested
#     $sql = "
# SELECT ddl.*
# FROM  $satdb.gene dg, 
#       $satdb.disease_index_doclist ddl,
#       $litedb.gene lg, 
#       $litedb.gene_xref lgx
# WHERE lg.chr_name = '$chr' 
#   AND lg.gene = lgx.gene 
#   AND lgx.display_id = dg.gene_symbol
#   AND ddl.id  = dg.id
# ";

    foreach my $w ( qw(doc stop vector word) ) {
        my $table = "disease_index_${w}list";
        $sql = "select * from $satdb.$table";
        dump_data($sql, $satdb, $table );
    }
}                                       # disease

sub dump_maps {
    my ($satdb) = @_;
    return unless $satdb;

    warn "ignoring non-RHdb markers !\n";
    dump_schema($satdb);

    my $chr_short = $chr;
    $chr_short =~ s/^chr//;

    my $sql;

    # the simple ones having a chromosome column:
    foreach my $table ( qw(ChromosomeBands CytogeneticMap RHMaps Fpc_Contig)) {
        $sql = "
SELECT * FROM $satdb.$table WHERE chromosome = '$chr_short'
";
        dump_data($sql, $satdb, $table );
    }

    $sql = "SELECT * FROM $satdb.Map";  # 4 rows
    dump_data($sql, $satdb, $table );

    # less simple ones that can both use the RHMaps table
    foreach my $table ( qw(Marker MarkerSynonym) ) {              
        $sql = "
SELECT t.* 
FROM $satdb.$table t,
     $satdb.RHMaps r
WHERE t.marker=r.marker 
  AND r.chromosome = '$chr_short'
";
        dump_data($sql, $satdb, $table );
    }    

    # this one needs a join 
    $sql="
SELECT cl.*
FROM $satdb.Fpc_Clone cl,
     $satdb.Fpc_Contig cg
WHERE cg.chromosome = '$chr_short'
  AND cl.contig_id = cg.contig_id
";
    dump_data($sql, $satdb, 'Fpc_Clone' );
}                                       # maps

sub dump_expression  {
    my ($satdb) = @_;
    return unless $satdb;

    warn "ignoring any non-ENSG aliases";
    my $dumpdir = "$workdir/$satdb";
    dump_schema($satdb);

    # small ones:
    foreach $table ( qw(key_word lib_key library source ) ) {
        $sql = "select * from $satdb.$table";
        dump_data($sql, $satdb, $table);
    }
    # frequency                            ;
    # seqtag                               ;
    # seqtag_alias                         ;
    $sql = "
SELECT sa.*
FROM $satdb.seqtag_alias sa, 
     $litedb.gene lg
WHERE sa.db_name = 'ensgene'
  AND sa.external_name =lg.name
  AND lg.chr_name = '$chr'
";
    dump_data($sql, $satdb, 'seqtag_alias');

    $sql = "
SELECT st.*
FROM  $satdb.seqtag st,
      $satdb.seqtag_alias sa, 
      $litedb.gene lg
WHERE sa.db_name = 'ensgene'
  AND sa.external_name =lg.name
  AND lg.chr_name = '$chr'
  AND st.seqtag_id = sa.seqtag_id
";
    dump_data($sql, $satdb, 'seqtag');

    $sql = "
SELECT f.*
FROM  $satdb.frequency f,
      $satdb.seqtag_alias sa, 
      $litedb.gene lg
WHERE sa.db_name = 'ensgene'
  AND sa.external_name =lg.name
  AND lg.chr_name = '$chr'
  AND f.seqtag_id = sa.seqtag_id
";
    dump_data($sql, $satdb, 'frequency');
}                                       # expression

sub dump_snp  {
    my ($satdb) = @_;
    return unless $satdb;

    warn "ignoring any non-ENSG aliases";
    my $dumpdir = "$workdir/$satdb";
    dump_schema($satdb);

    my @small_ones = qw(Assay ContigHit Locus  Pop Resource Submitter);
    foreach my $table ( @small_ones ) { 
        $sql = "select * from $satdb.$table";
        dump_data($sql, $satdb, $table);
    }

    #  RefSNP:
    $sql = "
SELECT rs.*
FROM   $satdb.RefSNP rs, 
       $litedb.gene_snp lgs,
       $litedb.gene lg
WHERE  lg.chr_name = '$chr'
 AND   lg.gene = lgs.gene
 AND   lgs.refsnpid = rs.id 
";
    dump_data($sql, $satdb, 'RefSNP');
    
    #  SubSNP
    $sql = "
SELECT ss.*
FROM   $satdb.SubSNP ss, 
       $litedb.gene_snp lgs,
       $litedb.gene lg
WHERE  lg.chr_name = '$chr'
 AND   lg.gene = lgs.gene
 AND   lgs.refsnpid = ss.refsnpid 
";


# (or should the last bit be ``lgs.refsnpid = ss.id'') ? 
    dump_data($sql, $satdb, 'SubSNP');

#  Hit        
    $sql = "
SELECT h.*
FROM   $satdb.Hit h, 
       $litedb.gene_snp lgs,
       $litedb.gene lg
WHERE  lg.chr_name = '$chr'
 AND   lg.gene = lgs.gene
 AND   lgs.refsnpid = h.refsnpid 
";
    dump_data($sql, $satdb, 'Hit');

# ignore these (says Heikki):
#  Freq  
#  GPHit      
#  SubPop     

}                                       # snp

sub dump_est  {
    my ($satdb) = @_;
    warn "no written, doing nohting";
    return undef;
    return unless $satdb;
}                                       # est

sub dump_schema {
    my ($satdb) = @_;

    my $destdir = "$workdir/$satdb";
    my $destfile = "$satdb.sql";

    unless (-d $destdir) {
        mkdir $destdir, 0755 || die "mkdir $destdir: $!";
    }

    my $d = "$destdir/$destfile";

    warn "Dumping database schema of $satdb to $d\n";
    die "$d exists" if -s $d ;
    $command = "$mysqldump -u $dbuser $pass_arg -d $satdb > $d ";
    if ( system($command) ) {
        die "Error: ``$command'' ended with exit status $?";
    }
}

sub dump_data {
    my($sql, $satdb, $tablename) = @_;
    my ($destdir) = "$workdir/$satdb";
    my ($datfile)=  "$tablename.dat";

    unless (-d $destdir) {
        mkdir $destdir, 0755 || die "mkdir $destdir: $!";
    }
    
    $sql =~ s/\s+/ /g;
    
    my $cmd = "echo \"$sql\" | $mysql -q --batch -u $dbuser -p$dbpass $litedb > $destdir/$datfile";
    warn "dumping: $cmd\n";

    if ( system($cmd) ) { 
        die "``$cmd'' exited with exit-status $?";
    }
}

## stuff below is not used (yet), since everything is done by plain SQL

## This comes from family-input.pl, and should at one point be put somewhere
## more central (the ones in EnsEMBL load modules etc. that are not relevant)
## Takes string that looks like
## "database=foo;host=bar;user=jsmith;passwd=secret", connects to mysql
## and return the handle
sub db_connect { 
    my ($dbcs) = @_;

    my %keyvals= split('[=;]', $dbcs);
    my $user=$keyvals{'user'};
    my $paw=$keyvals{'pass'};
#    $dbcs =~ s/user=[^;]+;?//g;
#    $dbcs =~ s/password=[^;]+;?//g;
# (mysql doesn't seem to mind the extra user/passwd values, leave them)

    my $dsn = "DBI:mysql:$dbcs";

    my $dbh=DBI->connect($dsn, $user, $paw) ||
      die "couldn't connect using dsn $dsn, user $user, password $paw:" 
         . $DBI::errstr;
    $dbh->{RaiseError}++;
    $dbh;
}                                       # db_connect

sub unique {
    
    my @unique;
    my %seen = ();
    foreach my $item (@_) {
	push(@unique,$item) unless $seen{$item}++;
    }
    return @unique;
}

sub get_inlist {
    my $string_flag = shift (@_);
    my $string;
    foreach my $element (@_) {
	if ($string_flag) {
	    $string .= "'$element',";
	}
	else {
	    $string .= "$element,";
	}
    }
    $string =~ s/,$//;
    return "($string)";
} 
