package Order::Helper::Settings::NewCompanySettings;
use Mojo::Base -base;

use Data::Dumper;
use Mojo::JSON qw{to_json};

sub get_new_company_settings{
    my ($self, $companies_pkey, $company_type) = @_;

    my @settings;

    if($company_type == 3){
        my $setting_properties->{username} = '';
        $setting_properties->{password} = '';
        my $setting->{companies_fkey} = $companies_pkey;
        $setting->{users_fkey} = 0;
        $setting->{defined_settings_values_pkey} = 0;
        $setting->{setting_name} = 'Orion_Login_Data';
        $setting->{setting_fkey} = 0;
        $setting->{setting_no} = 1;
        $setting->{setting_value} = 'Orion credentials';
        $setting->{setting_order} = 1;
        $setting->{setting_properties} = $setting_properties;
        $setting->{setting_backend_properties} = '';
        push @settings, $setting;
    }

    if($company_type == 3){
        my $setting_properties->{has_orion} = 0;
        my $setting->{companies_fkey} = $companies_pkey;
        $setting->{users_fkey} = 0;
        $setting->{defined_settings_values_pkey} = 0;
        $setting->{setting_name} = 'Has_Active_Orion';
        $setting->{setting_fkey} = 0;
        $setting->{setting_no} = 1;
        $setting->{setting_value} = 'Has orion';
        $setting->{setting_order} = 1;
        $setting->{setting_properties} = $setting_properties;
        $setting->{setting_backend_properties} = '';
        push @settings, $setting;
    }

    return \@settings;
}
1;
