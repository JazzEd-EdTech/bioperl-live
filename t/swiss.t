# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
    use lib 't/lib';
    use BioperlTest;

    test_begin(-tests => 230);
	
    use_ok('Bio::SeqIO');
}

my $verbose = test_debug();

my $seqio = Bio::SeqIO->new( -verbose => $verbose,
                                     -format => 'swiss',
                                     -file   => test_input_file('test.swiss'));

isa_ok($seqio, 'Bio::SeqIO');
my $seq = $seqio->next_seq;
my @gns = $seq->annotation->get_Annotations('gene_name');

my $outfile = test_output_file();
$seqio = Bio::SeqIO->new( -verbose => $verbose,
                                 -format => 'swiss',
                                 -file   => ">$outfile");

$seqio->write_seq($seq);

# reads it in once again
$seqio = Bio::SeqIO->new( -verbose => $verbose,
                                 -format => 'swiss',
                                 -file => $outfile);

$seq = $seqio->next_seq;
isa_ok($seq->species, 'Bio::Taxon');
is($seq->species->ncbi_taxid, 6239);

# version, seq_update, dates (5 tests)
is($seq->version, 40);
my ($ann) = $seq->annotation->get_Annotations('seq_update');
is($ann->display_text, 35,'operator overloading in AnnotationI is deprecated');

my @dates = $seq->get_dates;
my @date_check = qw(01-NOV-1997 01-NOV-1997 16-OCT-2001);

for my $date (@dates) {
    my $expdate = shift @date_check;
    if ($expdate) {
        is($date, $expdate,'dates');
    } else {
        TODO: {
        local $TODO = 'grabbing seq_update with old SwissProt seqs fails roundtrip tests';
        is($date, $expdate);
        }
    }
}

my @gns2 = $seq->annotation->get_Annotations('gene_name');
# check gene name is preserved (was losing suffix in worm gene names)
#ok($#gns2 == 0 && $gns[0]->value eq $gns2[0]->value); #heikki

# test swissprot multiple RP lines
my $str = Bio::SeqIO->new(-file => test_input_file('P33897'));
$seq = $str->next_seq;
isa_ok($seq, 'Bio::Seq::RichSeqI');
my @refs = $seq->annotation->get_Annotations('reference');
is( @refs, 23);
is($refs[20]->rp, 'VARIANTS X-ALD LEU-98; ASP-99; GLU-217; GLN-518; ASP-608; ILE-633 AND PRO-660, AND VARIANT THR-13.');

# version, seq_update, dates (5 tests)
is($seq->version, 44);
($ann) = $seq->annotation->get_Annotations('seq_update');
is($ann->display_text, 28,'operator overloading in AnnotationI is deprecated');
@dates = $seq->get_dates;
@date_check = qw(01-FEB-1994 01-FEB-1994 15-JUN-2004);
for my $date (@dates) {
    is($date, shift @date_check);
}

my $ast = Bio::SeqIO->new(-verbose => $verbose,
                                  -format => 'swiss' ,
                                  -file => test_input_file('roa1.swiss'));
my $as = $ast->next_seq();

ok defined $as->seq;
is($as->id, 'ROA1_HUMAN', "id is ".$as->id);
like($as->primary_id, qr(Bio::PrimarySeq));
is($as->length, 371);
is($as->alphabet, 'protein');
is($as->division, 'HUMAN');
is(scalar $as->all_SeqFeatures(), 16);
is(scalar $as->annotation->get_Annotations('reference'), 11);

# version, seq_update, dates (6 tests)
is($as->version, 35);
($ann) = $as->annotation->get_Annotations('seq_update');
is($ann->display_text, 15,'operator overloading in AnnotationI is deprecated');
@dates = $as->get_dates;
@date_check = qw(01-MAR-1989 01-AUG-1990 01-NOV-1997);
for my $date (@dates) {
    is($date, shift @date_check);
}
($ann) = $as->annotation->get_Annotations('evidence');
is($ann->value,"1: Evidence at protein level");


my ($ent,$out) = undef;
($as,$seq) = undef;

$seqio = Bio::SeqIO->new(-format => 'swiss' ,
                                 -verbose => $verbose,
                                 -file => test_input_file('swiss.dat'));
$seq = $seqio->next_seq;
isa_ok($seq, 'Bio::Seq::RichSeqI');

# more tests to verify we are actually parsing correctly
like($seq->primary_id, qr(Bio::PrimarySeq));
is($seq->display_id, 'MA32_HUMAN');
is($seq->length, 282);
is($seq->division, 'HUMAN');
is($seq->alphabet, 'protein');
my @f = $seq->all_SeqFeatures();
is(@f, 2);
is($f[1]->primary_tag, 'CHAIN');
is(($f[1]->get_tag_values('description'))[0], 'COMPLEMENT COMPONENT 1, Q SUBCOMPONENT BINDING PROTEIN');

# version, seq_update, dates (5 tests)
is($seq->version, 40);
($ann) = $seq->annotation->get_Annotations('seq_update');
is($ann->display_text, 31,'operator overloading in AnnotationI is deprecated');
@dates = $seq->get_dates;
@date_check = qw(01-FEB-1995 01-FEB-1995 01-OCT-2000);
for my $date (@dates) {
    is($date, shift @date_check);
}

my @genenames = qw(GC1QBP HABP1 SF2P32 C1QBP);
($ann) = $seq->annotation->get_Annotations('gene_name');
my ($gn) = $ann->get_Annotations('name'); # take the first of an array
ok ($gn->value, shift @genenames);
my ($synonyms) = $ann->get_Annotations('synonyms'); # take the first of an array
foreach my $syn ( $synonyms->get_all_values() ) {
    ok ($syn, shift(@genenames));
}


# test for feature locations like ?..N
$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));
is($seq->display_id, 'ACON_CAEEL');
is($seq->length, 788);
is($seq->division, 'CAEEL');
is($seq->alphabet, 'protein');
is(scalar $seq->all_SeqFeatures(), 5);

my ($gn2) = $seq->annotation->get_Annotations('gene_name');
my ($name) = $ann->get_Annotations('name'); # take the first of an array
ok ($name->value, 'F54H12.1');


# test species in swissprot -- this can be a n:n nightmare
$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));
my @sec_acc = $seq->get_secondary_accessions();
is($sec_acc[0], 'P29360');
is($sec_acc[1], 'Q63631');
is($seq->accession_number, 'P42655');
my @kw = $seq->get_keywords;
is( $kw[0], 'Brain');
is( $kw[1], 'Neurone');
is($kw[3], 'Multigene family');
is($seq->display_id, '143E_HUMAN');
is($seq->species->binomial, "Homo sapiens");
is($seq->species->common_name, "Human");
is($seq->species->ncbi_taxid, 9606);

$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));
is($seq->species->binomial, "Bos taurus");
is($seq->species->common_name, "Bovine");
is($seq->species->ncbi_taxid, 9913);

# multiple genes in swissprot
$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));

my $flatnames = "(CALM1 OR CAM1 OR CALM OR CAM) AND (CALM2 OR CAM2 OR CAMB) AND (CALM3 OR CAM3 OR CAMC)";

my @ann_names = $seq->annotation->get_Annotations("gene_name");
is(scalar(@ann_names), 3, 'three genes in GN lines');

my $first_gene = $ann_names[0];
isa_ok($first_gene, 'Bio::Annotation::Collection');
my ($gn_name) = $first_gene->get_Annotations('name'); # only one name
isa_ok($gn_name, 'Bio::Annotation::SimpleValue');
is ($gn_name->value, 'CALM1', 'CALM1');

my @gn_synonyms_entry = qw (CAM1 CALM CAM);
my ($gn_synonyms) = $first_gene->get_Annotations('synonyms'); # only one synonyms object
isa_ok($gn_synonyms, 'Bio::Annotation::StructuredValue');
foreach my $syn ($gn_synonyms->get_all_values) {
    is($syn, shift(@gn_synonyms_entry), $syn);
}
# same goes for the other two genes,
# and applies to orderedlocusnames and orfnames



# same entry as before, but with the new gene names format
# CALM_HUMAN:
$seqio = Bio::SeqIO->new(-format => 'swiss',
                                 -verbose => $verbose,
                         -file => test_input_file('calm.swiss'));
$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));


@ann_names = $seq->annotation->get_Annotations("gene_name");
is(scalar(@ann_names), 3, 'three genes in new format');

$first_gene = $ann_names[0];
isa_ok($first_gene, 'Bio::Annotation::Collection');
($gn_name) = $first_gene->get_Annotations('name'); # only one name
isa_ok($gn_name, 'Bio::Annotation::SimpleValue');
is ($gn_name->value, 'CALM1', 'CALM1');
($gn_synonyms) = $first_gene->get_Annotations('synonyms'); # only one synonyms object
isa_ok($gn_synonyms, 'Bio::Annotation::StructuredValue');


@gn_synonyms_entry = qw (CAM1 CALM CAM);

foreach my $syn ($gn_synonyms->get_all_values) {
    is($syn, shift(@gn_synonyms_entry), $syn);
}
# same goes for the other two genes,
# and applies to orderedlocusnames and orfnames


# test proper parsing of references
my @litrefs = $seq->annotation->get_Annotations('reference');
is(scalar(@litrefs), 17);

my @titles = (
    '"Complete amino acid sequence of human brain calmodulin."',
    '"Multiple divergent mRNAs code for a single human calmodulin."',
    '"Molecular analysis of human and rat calmodulin complementary DNA clones. Evidence for additional active genes in these species."',
    '"Isolation and nucleotide sequence of a cDNA encoding human calmodulin."',
    '"Structure of the human CALM1 calmodulin gene and identification of two CALM1-related pseudogenes CALM1P1 and CALM1P2."',
    undef,
    '"Characterization of the human CALM2 calmodulin gene and comparison of the transcriptional activity of CALM1, CALM2 and CALM3."',
    '"Cloning of human full-length CDSs in BD Creator(TM) system donor vector."',
    '"The DNA sequence and analysis of human chromosome 14."',
    '"Generation and initial analysis of more than 15,000 full-length human and mouse cDNA sequences."',
    '"Alpha-helix nucleation by a calcium-binding peptide loop."',
    '"Solution structure of Ca(2+)-calmodulin reveals flexible hand-like properties of its domains."',
    '"Calmodulin structure refined at 1.7 A resolution."',
    '"Drug binding by calmodulin: crystal structure of a calmodulin-trifluoperazine complex."',
    '"Structural basis for the activation of anthrax adenylyl cyclase exotoxin by calmodulin."',
    '"Physiological calcium concentrations regulate calmodulin binding and catalysis of adenylyl cyclase exotoxins."',
    '"Crystal structure of a MARCKS peptide containing the calmodulin-binding domain in complex with Ca2+-calmodulin."',
);

my @locs = (
    "Biochemistry 21:2565-2569(1982).",
    "J. Biol. Chem. 263:17055-17062(1988).",
    "J. Biol. Chem. 262:16663-16670(1987).",
    "Biochem. Int. 9:177-185(1984).",
    "Eur. J. Biochem. 225:71-82(1994).",
    "Submitted (FEB-1995) to the EMBL/GenBank/DDBJ databases.",
    "Cell Calcium 23:323-338(1998).",
    "Submitted (MAY-2003) to the EMBL/GenBank/DDBJ databases.",
    "Nature 421:601-607(2003).",
    "Proc. Natl. Acad. Sci. U.S.A. 99:16899-16903(2002).",
    "Proc. Natl. Acad. Sci. U.S.A. 96:903-908(1999).",
    "Nat. Struct. Biol. 8:990-997(2001).",
    "J. Mol. Biol. 228:1177-1192(1992).",
    "Biochemistry 33:15259-15265(1994).",
    "Nature 415:396-402(2002).",
    "EMBO J. 21:6721-6732(2002).",
    "Nat. Struct. Biol. 10:226-231(2003).",
);

my @positions = (
     undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    94, 103,
    1, 76,
    undef, undef,
    undef, undef,
    5, 148,
    1, 148,
    undef, undef,
);

foreach my $litref (@litrefs) {
    is($litref->title, shift(@titles));
    is($litref->location, shift(@locs));
    is($litref->start, shift(@positions));
    is($litref->end, shift(@positions));
}

# format parsing changes (pre-rel 9.0)

$seqio = Bio::SeqIO->new( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => test_input_file('pre_rel9.swiss'));

ok($seqio);
$seq = $seqio->next_seq;
isa_ok($seq->species, 'Bio::Taxon');
is($seq->species->ncbi_taxid, "6239");

# version, seq_update, dates (5 tests)
is($seq->version, 44);
($ann) = $seq->annotation->get_Annotations('seq_update');
is($ann->display_text, 1,'operator overloading in AnnotationI is deprecated');
@dates = $seq->get_dates;
@date_check = qw(01-NOV-1997 01-NOV-1996 30-MAY-2006 );
for my $date (@dates) {
    is($date, shift @date_check);
}

my @idcheck = qw(Z66513 T22647 Cel.30446 Q06319 Q20772 F54D5.7 WBGene00010052
		 F54D5.7 GO:0005515 IPR006089 IPR006091 IPR006090
		 IPR006092 IPR009075 IPR009100 IPR013764 PF00441
		 PF02770 PF02771 PS00072 PS00073);

for my $dblink ( $seq->annotation->get_Annotations('dblink') ) {
    is($dblink->primary_id, shift @idcheck);
}

$seqio = Bio::SeqIO->new( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => test_input_file('pre_rel9.swiss'));

my @namespaces = qw(Swiss-Prot TrEMBL TrEMBL);

while (my $seq = $seqio->next_seq) {
    is($seq->namespace, shift @namespaces);
}

# format parsing changes (rel 9.0, Oct 2006)

$seqio = Bio::SeqIO->new( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => test_input_file('rel9.swiss'));

ok($seqio);
$seq = $seqio->next_seq;
isa_ok($seq->species, 'Bio::Taxon');
is($seq->species->ncbi_taxid, 6239);

is($seq->version, 47);
($ann) = $seq->annotation->get_Annotations('seq_update');
is($ann->display_text, 1,'operator overloading in AnnotationI is deprecated');
@dates = $seq->get_dates;
@date_check = qw(01-NOV-1997 01-NOV-1996 31-OCT-2006 );
for my $date (@dates) {
    is($date, shift @date_check);
}

@idcheck = qw(Z66513 T22647 Cel.30446 Q06319 Q20772 F54D5.7 cel:F54D5.7
         WBGene00010052 F54D5.7 GO:0005515 IPR006089 IPR006091 IPR006090
         IPR006092 IPR009075 IPR013786 IPR009100 IPR013764 PF00441 PF02770
         PF02771 PS00072 PS00073 );

for my $dblink ( $seq->annotation->get_Annotations('dblink') ) {
    is($dblink->primary_id, shift @idcheck);
}

$seqio = Bio::SeqIO->new( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => test_input_file('rel9.swiss'));

@namespaces = qw(Swiss-Prot TrEMBL TrEMBL);

while (my $seq = $seqio->next_seq) {
    is($seq->namespace, shift @namespaces);
}

# bug 2288
# Q8GBD3.swiss
$seqio = Bio::SeqIO->new( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => test_input_file('Q8GBD3.swiss'));

while (my $seq = $seqio->next_seq) {
    my $lineage = join(';', $seq->species->classification);
	is ($lineage, 'Acetobacter aceti;Acetobacter subgen. Acetobacter;'.
		'Acetobacter;Acetobacteraceae;Rhodospirillales;Alphaproteobacteria;'.
		'Proteobacteria;Bacteria');
}
