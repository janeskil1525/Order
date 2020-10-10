package Order::Helper::Translations;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Try::Tiny;
use Mojo::JSON qw{from_json};
use Data::Dumper;

has 'pg';

sub details_headers{
	my($self, $module, $field_list, $data, $lan) = @_;
	
	my $translation_list = $self->get_translation_list($module, $field_list, $lan);
	my $length = scalar @{$translation_list};
	my $details;
	if($length){
		foreach my $field (@{$field_list}){
			$details->{$field->{setting_value}}->{value} = $data->{$field->{setting_value}};
			$details->{$field->{setting_value}}->{field} = $field->{setting_value};
			$details->{$field->{setting_value}}->{order} = $field->{setting_order};
			$details->{$field->{setting_value}}->{properties} = '';
			if(exists $field->{setting_properties} and $field->{setting_properties}){
				$details->{$field->{setting_value}}->{properties} = try {
					from_json $field->{setting_properties};
				}catch{
					$self->capture_message('','Daje-Utils-Translations', (ref $self), (caller(0))[3], $_);
					say $_;
					return '';
				};
			}
			my ($matching_hash) = grep {
					$_->{tag} eq $field->{setting_value}
			} @{$translation_list}
			if $length;

			if(ref($matching_hash) eq 'HASH' and exists $matching_hash->{tag}){
				$details->{$field->{setting_value}}->{label} = $matching_hash->{translation};
			}else{
				$details->{$field->{setting_value}}->{label} = $field->{setting_value};
			}
		}
	}
	return $details;
}

sub grid_header{
	my($self, $module, $field_list, $lan) = @_;

	my $translation_list = $self->get_translation_list($module, $field_list, $lan);
	my $length = scalar @{$translation_list};

	my @header_list;
	foreach my $field (@{$field_list}){
		my $header;
		#my $matching_hash;
		$header->{order} = $field->{setting_order};
		$header->{field} = $field->{setting_value};
		$header->{properties} = '';
		if($field->{setting_properties}){
			$header->{properties} = try{
				from_json $field->{setting_properties};
			}catch{
				$self->capture_message('','Daje::Utils::Sentinelsender', (ref $self), (caller(0))[3], $_);
				say $_;
				return '';
			};
		}

		my ($matching_hash) = grep {
			$_->{tag} eq $field->{setting_value}
		} @{$translation_list}
			if $length;

		if(ref($matching_hash) eq 'HASH' and exists $matching_hash->{tag}){
			$header->{headerName} = $matching_hash->{translation};
		}else{
			$header->{headerName} = $field->{setting_value};
		}
		push @header_list, $header;
	}
	return \@header_list;
}

sub get_translation_list{
	my($self, $module, $field_list, $lan) = @_;
	
	my $stmt = $self->get_query($module, $field_list, $lan);
	
	my $translation_list = try{
		$self->pg->db->query($stmt)->hashes->to_array
	}catch{
		$self->capture_message('','Daje::Utils::Sentinelsender', (ref $self), (caller(0))[3], $_);
		say $_;
	};
	
	return $translation_list;
}

sub get_query{
	my($self, $module, $field_list, $lan) = @_;
	
	my $incondition ;
	foreach (@{$field_list}){
		$incondition .= " '$_->{setting_value}',";
	}
	
	$incondition = substr ($incondition,0,-1);
	my $stmt = qq{
		SELECT tag, translation
			FROM languages JOIN translations
		ON 	languages_pkey = languages_fkey AND lan = '$lan'
			WHERE module = '$module'
		AND tag IN($incondition)
	};
	
	return $stmt;
}

1;
