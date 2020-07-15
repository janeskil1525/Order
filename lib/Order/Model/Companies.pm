package Order::Model::Companies;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Try::Tiny;
use Data::Dumper;
has 'pg';

sub save {
	my ($self, $company) = @_;

	$company->{homepage} = 'No' unless $company->{homepage};
	$company->{registrationnumber} = 'No' unless $company->{registrationnumber};
	$company->{recyclingsystem} = 'No' unless $company->{recyclingsystem};
	$company->{menu_group} = 2 unless $company->{menu_group};
	$company->{custid} = 'No' unless $company->{custid};
	$company->{phone} = 'No' unless $company->{phone};

	return $self->pg->db->query(qq{
		INSERT INTO companies
		(company, name, registrationnumber, phone, recyclingsystem, password, has_orion, username, menu_group, custid, homepage)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
				ON CONFLICT (company)
			DO UPDATE
				SET moddatetime = now(),
				editnum = companies.editnum + 1,
				name = ?,
				registrationnumber = ?,
				phone = ?,
				recyclingsystem = ?,
				password = ?,
				has_orion = ?,
				username = ?,
				menu_group = ?,
				custid = ?,
				homepage = ?;
	},(
		$company->{company}, 				# 1
		$company->{name}, 					# 2
		$company->{registrationnumber},		# 3
		$company->{phone}, 					# 4
		$company->{recyclingsystem},		# 5
		$company->{password}, 				# 6
		$company->{has_orion}, 				# 7
		$company->{username},				# 8
		$company->{menu_group}, 			# 9
		$company->{custid}, 				# 10
		$company->{homepage},				# 11
		$company->{name}, 					# 12
		$company->{registrationnumber},		# 13
		$company->{phone}, 					# 14
		$company->{recyclingsystem},		# 15
		$company->{password}, 				# 16
		$company->{has_orion}, 				# 17
		$company->{username},				# 18
		$company->{menu_group}, 			# 19
		$company->{custid}, 				# 20
		$company->{homepage}				# 21
	)
	);
}

sub list_matorit {
	my $self = shift;

	my $debug;
	my $result = try {
		$self->pg->db->select(
			'companies',
			undef,
			{
				'recyclingsystem' => 'Matorit'
			}
		)->hashes;
	} catch {
		say $_;
		$debug = $_;
	};

	return $result
}

sub list_matorit_p{
	my $self = shift;

	return $self->pg->db->select_p(
			'companies',
			undef,
			{
				'recyclingsystem' => 'Matorit'
			}
	);
}
1;