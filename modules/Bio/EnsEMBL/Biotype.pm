=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut

=head1 NAME

Bio::EnsEMBL::Biotype

=head1 SYNOPSIS

    my $biotype = new Bio::EnsEMBL::Biotype(
      -name          => 'new_biotype,
      -object_type   => 'gene',
      -biotype_group => 'a_biotype_group',
      -so_acc        => 'SO::1234567',
      -description   => 'New biotype'
    );

    my $name = $biotype->name();
    my $biotype_group = $biotype->biotype_group();
    my $so_acc = $biotype->so_acc();

=head1 DESCRIPTION

This is the Biotype object class.

=head1 METHODS

=cut


package Bio::EnsEMBL::Biotype;

use strict;
use warnings;

use Bio::EnsEMBL::Storable;
use Bio::EnsEMBL::Utils::Exception qw(throw deprecate warning);
use Bio::EnsEMBL::Utils::Scalar qw(check_ref assert_ref);
use Bio::EnsEMBL::Utils::Argument qw(rearrange);

use base qw(Bio::EnsEMBL::Storable);

=head2 new

  Arg [-BIOTYPE_ID]  :
      int - dbID of the biotype
  Arg [-NAME]    :
      string - the name of the biotype (for ensembl)
  Arg [-OBJECT_TYPE] :
      string - the object type this biotype applies to (gene or transcript)
  Arg [-BIOTYPE_GROUP]  :
      string - the name of the biotype group (for ensembl)
  Arg [-SO_ACC] :
      string - the Sequence Ontology accession of this biotype
  Arg [-DESCRIPTION] :
      string - the biotype description
  Arg [-DB_TYPE] :
      string - the database type for this biotype
  Arg [-ATTRIB_TYPE_ID] :
      int - attrib_type_id

  Example    : $biotype = Bio::EnsEMBL::Biotype->new(...);
  Description: Creates a new biotype object
  Returntype : Bio::EnsEMBL::Biotype
  Exceptions : none
  Caller     : general
  Status     : Stable


=cut

sub new {
  my $caller = shift;

  my $class = ref($caller) || $caller;

  my $self = $class->SUPER::new();

  my($dbID, $name, $object_type, $biotype_group, $so_acc, $description, $db_type, $attrib_type_id) =
    rearrange([qw(BIOTYPE_ID NAME OBJECT_TYPE BIOTYPE_GROUP SO_ACC DESCRIPTION DB_TYPE ATTRIB_TYPE_ID)], @_);


  $self->{'dbID'} = $dbID;
  $self->{'name'} = $name;
  $self->{'object_type'} = $object_type;
  $self->{'biotype_group'} = $biotype_group;
  $self->{'so_acc'} = $so_acc;
  $self->{'description'} = $description;
  $self->{'db_type'} = $db_type;
  $self->{'attrib_type_id'} = $attrib_type_id;

  return $self;
}


=head2 name

  Arg [1]    : (optional) string $name
               The name of this biotype according to ensembl.
  Example    : $name = $biotype->name()
  Description: Getter/Setter for the name of this biotype.
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub name {
  my ( $self, $value ) = @_;

  if ( defined($value) ) {
    $self->{'name'} = $value;
  }

  return $self->{'name'};
}



=head2 biotype_group

  Arg [1]    : (optional) string $biotype_group
  Example    : $biotype_group = $biotype->biotype_group();
  Description: Getter/Setter for the biotype_group of this biotype.
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub biotype_group {
  my ( $self, $value ) = @_;

  if ( defined($value) ) {
    $self->{'biotype_group'} = $value;
  }

  return $self->{'biotype_group'};
}




=head2 so_acc

  Arg [1]    : (optional) string $so_acc
  Example    : $feat->so_acc();
  Description: Getter/Setter for the so_acc of this biotype.
               It must be a Sequence Ontology like accession (SO:\d*)
               -1 is the reverse (negative) so_acc and 1 is the forward
               (positive) so_acc.  No other values are permitted.
  Returntype : string
  Exceptions : thrown if an invalid so_acc argument is passed
  Caller     : general
  Status     : Stable

=cut

sub so_acc {
  my ( $self, $so_acc ) = @_;

  if ( defined($so_acc) ) {
    # throw an error if setting something that does not look like an SO acc
    throw('so_acc must be a Sequence Ontology accession')
      unless ( $so_acc =~ m/^SO:\d+/ );

    $self->{'so_acc'} = $so_acc;
  }

  return $self->{'so_acc'};
}

1;