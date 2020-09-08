package Order::Utils::User;
use Mojo::Base "Daje::Utils::Sentinelsender";

use Try::Tiny;
use Data::Dumper;

our $VERSION = '0.4';

has 'pg';

sub getSalesUser{
    my ($self, $companies_pkey) = @_;

    my $users_pkey = try {
            my $result = $self->pg->db->query(qq{
                SELECT users_pkey FROM users
                JOIN users_companies as a ON a.users_fkey = users_pkey AND companies_fkey = ? AND active = true
                JOIN reference as b ON b.users_fkey = users_pkey
                JOIN reference_type ON b.reference_type_fkey = reference_type_pkey AND reference_type = 'SALES'
                LIMIT 1;
            }, ($companies_pkey));

        if($result->rows > 0){
            return $result->hash->{users_pkey};
        }else{
            return 0;
        }
    }catch{
        $self->capture_message("[Daje::Utils::User::getSalesUser] " . $_);
        say @_;
        return 0;
    };

    if($users_pkey == 0){ # No user was set up as sales so we just grab one from the companny
        $users_pkey = try {
            my $result =  $self->pg->db->query(qq{
            SELECT users_pkey FROM users
            JOIN users_companies as a ON a.users_fkey = users_pkey AND companies_fkey = ? AND active = true
            LIMIT 1;
        }, ($companies_pkey));
            if($result->rows > 0){
                return $result->hash->{users_pkey};
            }else{
                return 0;
            }
        }catch{
            $self->capture_message("[Daje::Utils::User::getSalesUser] " . $_);
            say @_;
            return 0;
        };
    }
    return $users_pkey
}
1;
