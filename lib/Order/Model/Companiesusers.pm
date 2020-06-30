package Order::Model::Companiesusers;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Try::Tiny;
use Data::Dumper;
has 'pg';

sub save {
	my ($self, $companyuser) = @_;

	$companyuser->{homepage} = 'No' unless $companyuser->{homepage};
	$companyuser->{registrationnumber} = 'No' unless $companyuser->{registrationnumber};
	$companyuser->{phone} = 'No' unless $companyuser->{phone};
	my $result = 0;
	eval {
		my $db = $self->pg->db;
		my $tx = $db->begin();

		my $companies_fkey = $db->query(qq{
				INSERT INTO companies
				(company, name, registrationnumber, phone, recyclingsystem, has_orion, menu_group, homepage)
					VALUES (?, ?, ?, ?, ?, ?, ?, ?)
						ON CONFLICT (company)
					DO UPDATE
						SET moddatetime = now(),
						editnum = companies.editnum + 1,
						name = ?,
						registrationnumber = ?,
						phone = ?,
						recyclingsystem = ?,
						has_orion = ?,
						menu_group = ?,
						homepage = ?
					RETURNING companies_pkey;
			},(
					$companyuser->{company}, 				# 1
					$companyuser->{name}, 					# 2
					$companyuser->{registrationnumber},		# 3
					$companyuser->{phone}, 					# 4
					$companyuser->{recyclingsystem},		# 5
					$companyuser->{has_orion}, 				# 7
					$companyuser->{menu_group}, 			# 9
					$companyuser->{homepage},				# 11
					$companyuser->{name}, 					# 12
					$companyuser->{registrationnumber},		# 13
					$companyuser->{phone}, 					# 14
					$companyuser->{recyclingsystem},		# 15
					$companyuser->{has_orion}, 				# 17
					$companyuser->{menu_group}, 			# 19
					$companyuser->{homepage}				# 21
				)
		);

		my $users_fkey = $db->query(qq{
			INSERT INTO users(userid, username, passwd, menu_group, active)
				VALUES (?,?,?,?, ?)
				ON CONFLICT (userid)
				DO UPDATE
				SET moddatetime = now(),
					editnum = users.editnum + 1,
					username =  ?,
					passwd = ?,
					menu_group = ?,
					active = ?
				RETURNING users_pkey;
			},	(
					$companyuser->{userid},
					$companyuser->{username},
					$companyuser->{passwd},
					$companyuser->{menu_group},
					$companyuser->{active},
					$companyuser->{username},
					$companyuser->{passwd},
					$companyuser->{menu_group},
					$companyuser->{active},
				)
		);

		$db->query(qq{
				INSERT INTO users_companies (users_fkey, companies_fkey)
				VALUES(?,?)
				ON CONFLICT (users_fkey, companies_fkey)
				DO UPDATE
				SET moddatetime = now(),
					editnum = users_companies.editnum + 1
			},(
				$users_fkey,
				$companies_fkey
			)
		);
		$tx->commit;
		$result = 1;
	};
	$self->capture_message('','Order::Model::Companiesusers', (ref $self), (caller(0))[3], $@) if $@;
	say $@ if $@;

	return $result;
}
1;