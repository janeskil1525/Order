package Order::Helper::Settings;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::JSON qw{to_json};
use Data::Dumper;
use Try::Tiny;
use Order::Helper::Settings::NewCompanySettings;
use Order::Helper::Settings::GridSettings;

has 'pg';

sub save_company_setting {
	my ($self, $data) = @_;

	my $stmt_company;
	my @args;

	$data->{setting_properties} = to_json($data->{setting_properties})
		if $data->{setting_properties};
	$data->{setting_backend_properties} = to_json($data->{setting_backend_properties})
		if $data->{setting_backend_properties};

	if($data->{defined_settings_values_pkey} > 0){
		$stmt_company = qq{
			UPDATE defined_settings_values
				SET setting_value = ?,
				setting_order = ?,
				setting_properties = ?,
				setting_backend_properties = ?
			WHERE defined_settings_values_pkey = ?
			};
		push @args, $data->{setting_value};
		push @args, $data->{setting_order};
		push @args, $data->{setting_properties};
		push @args, $data->{setting_backend_properties};
		push @args, $data->{defined_settings_values_pkey};
	}else{
		$stmt_company = qq{
			INSERT INTO defined_settings_values (
				setting_value,
				setting_order,
				setting_properties,
				setting_backend_properties,
				settings_fkey,
				companies_fkey,
				setting_no)
				VALUES (?,?,?,?,?,?,?)
			};
		push @args, $data->{setting_value};
		push @args, $data->{setting_order};
		push @args, $data->{setting_properties};
		push @args, $data->{setting_backend_properties};
		push @args, $data->{settings_fkey};
		push @args, $data->{companies_fkey};
		push @args, $data->{setting_no};
	}

	my $result = $self->pg->db->query($stmt_company, @args);

	my $response->{rows} = $result->rows;
	if($response->{rows}){
		$response->{response} = "Success";
	}else{
		$self->capture_message(
			'', 'Daje-Utils-Settings',
			(ref $self), (caller(0))[3],
			"save_company_setting Operation failed"
		);        
		$response->{response} = "Operation failed";
	}
	return $response;
}

sub get_company_setting {
	my ($self, $setting, $companies_pkey) = @_;

	my $stmt_company = qq{
		SELECT defined_settings_values_pkey, companies_fkey, setting_value, setting_order, setting_properties, setting_backend_properties
		FROM defined_settings_values
			JOIN settings
		ON settings_pkey = settings_fkey
			WHERE companies_fkey = ? AND setting_name = ?
		ORDER BY setting_order;
    };

	my $result = try {
		$self->pg->db->query($stmt_company,($companies_pkey,  $setting)) ;
	} catch {
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	};
	
	my $company_setting = $result->hash;
	$result->finish();

	return $company_setting;
}

sub get_company_setting_list{
	my ($self, $companies_pkey) = @_;

	my $stmt_company = qq{
		SELECT defined_settings_values_pkey, companies_fkey, setting_value,
			setting_order, setting_properties, setting_backend_properties, setting_name
		FROM defined_settings_values
			JOIN settings
		ON settings_pkey = settings_fkey
			WHERE companies_fkey = ?
		ORDER BY setting_order;
    };

	my $result = try {
		$self->pg->db->query($stmt_company,($companies_pkey)) ;
	} catch {
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	};

	my $company_setting = $result->hashes;

	return $company_setting;
}

sub get_settings_list {
	my ($self, $setting, $token) = @_;
	
	my $setting_value = try {
		$self->get_settings($setting, $token)->to_array();
	} catch {
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	};
	
	return $setting_value;
}

sub get_setting_value{
	my ($self, $setting, $token) = @_;
	
	my $setting_value = try {
		$self->get_settings($setting, $token)->to_array();
	} catch {
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	};
	
	my $result = try {
		my $setting = @{$setting_value}[0] ;
		return $setting->{setting_value}
	}catch{
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
		return $_;
	} if scalar @{$setting_value};

	
	return $result;
}

sub set_user_setting {
	my ($self, $setting, $token) = @_;

	my $usercompany =  $self->get_user_company($token);

	my $stmt = qq{
		INSERT INTO defined_settings_values (
				setting_no,
				setting_value,
				companies_fkey,
				settings_fkey,
				users_fkey
				) VALUES (1,?,?,(SELECT settings_pkey FROM settings WHERE setting_name = ?),?)
			ON CONFLICT(settings_fkey, setting_no, companies_fkey, users_fkey )
			DO UPDATE SET
			 	setting_value = ?,
			 	moddatetime = now(),
				editnum = defined_settings_values.editnum + 1

	};

	my $result = try {
		$self->pg->db->query($stmt,
			(
				$setting->{setting_value},
				$usercompany->{companies_fkey},
				$setting->{setting_name},
				$usercompany->{users_fkey},
				$setting->{setting_value},
			)
		);
		return 1;
	} catch {
		$self->capture_message('','Daje-Utils-Settings', (ref $self), (caller(0))[3],  $_ );
		say $_;
		return 0;
	};
	return $result
}

sub set_grid_settings{
	my ($self, $grid, $token, $gridstate) = @_;

	my $usercompany =  $self->get_user_company($token);
	my $settings = $self->get_settings($grid, $token);
	my $new_settings = Daje::Utils::GridSettings->new()->set_grid_settings($gridstate, $settings);

	my $stmt_grid;
	my $setting_no = 1;
	for my $data (@{$new_settings}) {

		my @args;
		$stmt_grid = qq{
				INSERT INTO defined_settings_values (
					setting_value,
					setting_order,
					setting_properties,
					setting_backend_properties,
					companies_fkey,
					users_fkey,
					setting_no,
					settings_fkey)
					VALUES (?,?,?,?,?,?,?,(SELECT settings_pkey FROM settings WHERE setting_name = ?))
					ON CONFLICT(settings_fkey, setting_no, companies_fkey, users_fkey )
					DO UPDATE SET
						setting_value = ?,
						setting_order = ?,
						setting_properties = ?,
						setting_backend_properties = ?,
						moddatetime = now(),
						editnum = defined_settings_values.editnum + 1
				};
		# Insert
		push @args, $data->{setting_value};
		push @args, $data->{setting_order};
		push @args, $data->{setting_properties};
		push @args, $data->{setting_backend_properties};
		push @args, $usercompany->{companies_fkey};
		push @args, $usercompany->{users_fkey};
		push @args, $data->{setting_no};
		push @args, $grid;
		# Update
		push @args, $data->{setting_value};
		push @args, $data->{setting_order};
		push @args, $data->{setting_properties};
		push @args, $data->{setting_backend_properties};



		my $result = try {
			$self->pg->db->query($stmt_grid, @args);
		} catch {
			$self->capture_message('','Daje-Utils-Settings', (ref $self), (caller(0))[3],  $_ );
			say $_;
		};
	}
}

sub get_settings{
	my ($self, $setting, $token) = @_;
	
	my $usercompany =  $self->get_user_company($token);
	
	my $stmt_full = qq{
		SELECT defined_settings_values_pkey, setting_no, setting_value, setting_order, setting_properties, setting_backend_properties
		FROM defined_settings_values
			JOIN settings
		ON settings_pkey = settings_fkey
			WHERE companies_fkey = ? AND users_fkey = ? AND setting_name = ?
		ORDER BY setting_order;
    };
	
	my $stmt_company = qq{
		SELECT setting_value, setting_order, setting_properties, setting_backend_properties, setting_no
		FROM defined_settings_values
			JOIN settings
		ON settings_pkey = settings_fkey
			WHERE companies_fkey = ? AND setting_name = ?
		ORDER BY setting_order;
    };
	
	my $stmt_default = qq{
		SELECT setting_value, setting_order, setting_properties, setting_backend_properties, setting_no
		FROM default_settings_values
			JOIN settings
		ON settings_pkey = settings_fkey
			WHERE setting_name = ?
		ORDER BY setting_order;
    };
	
	$usercompany->{companies_fkey} = 0 unless exists $usercompany->{companies_fkey} and $usercompany->{companies_fkey} > 0;
	$usercompany->{users_fkey} = 0 unless exists $usercompany->{users_fkey} and $usercompany->{users_fkey} > 0;
	
	my $result = try{
		$self->pg->db->query($stmt_full,($usercompany->{companies_fkey}, $usercompany->{users_fkey}, $setting));
	}catch{
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	};
	
	$result = try{
		$self->pg->db->query($stmt_company,($usercompany->{companies_fkey},  $setting)) ;
	}catch{
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	} unless $result->rows > 0 ;
	
	$result = try{
		$self->pg->db->query($stmt_default,($setting)) ;
	}catch{
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	} unless $result->rows > 0;
	
    my $setting_value = $result->hashes();
	
	return $setting_value;
}

sub get_settings_group{
	my ($self, $settinggroup, $token) = @_;

	my $usercompany =  try {
		$self->get_user_company($token);
	} catch {
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	};

	my $stmt_full = qq{
		SELECT setting_name, setting_value, setting_order, setting_properties, setting_backend_properties
		FROM defined_settings_values as a
			JOIN settings as b
		ON b.settings_pkey = a.settings_fkey
			JOIN settings_group as c
		ON b.settings_pkey = c.settings_fkey
			WHERE companies_fkey = ? AND users_fkey = ? AND setting_group = ?
		ORDER BY setting_order;
    };

	my $stmt_company = qq{
		SELECT setting_name, setting_value, setting_order, setting_properties, setting_backend_properties
		FROM defined_settings_values as a
			JOIN settings as b
		ON b.settings_pkey = a.settings_fkey
			JOIN settings_group as c
		ON b.settings_pkey = c.settings_fkey
			WHERE companies_fkey = ? AND setting_group = ?
		ORDER BY setting_order;
    };

	my $stmt_default = qq{
		SELECT setting_name, setting_value, setting_order, setting_properties, setting_backend_properties
		FROM default_settings_values as a
			JOIN settings as b
		ON b.settings_pkey = a.settings_fkey
			JOIN settings_group as c
		ON b.settings_pkey = c.settings_fkey
			WHERE setting_group = ?
		ORDER BY setting_order;
    };

	$usercompany->{companies_fkey} = 0 unless exists $usercompany->{companies_fkey} and $usercompany->{companies_fkey} > 0;
	$usercompany->{users_fkey} = 0 unless exists $usercompany->{users_fkey} and $usercompany->{users_fkey} > 0;

	my $result = try{
		$self->pg->db->query($stmt_full,($usercompany->{companies_fkey}, $usercompany->{users_fkey}, $settinggroup));
	}catch{
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	};

	$result = try{
		$self->pg->db->query($stmt_company,($usercompany->{companies_fkey},  $settinggroup)) ;
	}catch{
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	} unless $result->rows > 0 ;

	$result = try{
		$self->pg->db->query($stmt_default,($settinggroup)) ;
	}catch{
		$self->capture_message(
			'', 'Daje-Utils-Settings', (ref $self), (caller(0))[3], $_
		);
        say $_;
	} unless $result->rows > 0;

	my $setting_value = $result->hashes();

	return $setting_value;
}

sub get_user_company{
	my ($self, $token) = @_;
	
	my $stmt = qq{
		SELECT a.users_fkey, c.companies_fkey
			FROM users_token as a
		JOIN users_companies as c
			ON c.users_fkey = a.users_fkey
		AND token = ? };
		
	my $result = try {
		$self->pg->db->query($stmt,($token));		
	}catch{
		say $_;
	};
	
	my $usercompany = $result->hash;
	$result->finish;
	
	return $usercompany;
}

sub add_new_company_settings{
	my ($self, $companies_pkey, $company_type) = @_;

	my $newsettings = Order::Helper::Settings::NewCompanySettings->new()->get_new_company_settings($companies_pkey, $company_type);
	my $length = scalar @{$newsettings};

	for(my $i = 0; $i < $length; $i++){
		@{$newsettings}[$i]->{settings_fkey} = $self->pg->db->select(
			'settings',
			['settings_pkey'],
			{
				setting_name => @{$newsettings}[$i]->{setting_name}
			}
		)->hash->{settings_pkey};
		$self->save_company_setting(@{$newsettings}[$i]);
	}
	return 1;
}
1;


__DATA__

@@ settings.sql

