#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Mojo::Pg;

use Order::Helper::Shoppingcart;
use Mojo::JSON qw {encode_json};

my $pg = Mojo::Pg->new->dsn(
    "dbi:Pg:dbname=Order;host=192.168.1.100;port=15432;user=postgres;password=PV58nova64"
);

my $item = {
    'userid' => 'janeskil1525@gmail.com',
    'itemtype' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
    'freight' => 0,
    'reference' => 'Jan Eskilsson (janeskil1525)',
    'description' => 'Generator',
    'extradata' => "{\"id\": 44722214, \"bid\": \"\", \"upp\": \"2\", \"vin\": \"1J8GNE8599W502957\", \"body\": \"Cbi (Helkombi)\", \"fuel\": \"Diesel\", \"part\": \"7405\", \"type\": 0, \"year\": \"2009\", \"artno\": \"1042106080\", \"block\": 0, \"image\": 3, \"model\": \"2,8 CRD 4WD\", \"orgno\": \"104210-6080\", \"price\": 1440.0, \"colour\": \"Svart\", \"effect\": \"130\", \"index2\": \"3907817405\", \"lpbuff\": 0, \"remark\": \"Denso\", \"toyear\": \"2009\", \"update\": \"2020-09-06T21:37:47\", \"weight\": null, \"carbase\": 0, \"carcode\": \"1260\", \"exportb\": 0, \"exportr\": 0, \"gearbox\": \"AUT\", \"notused\": 0, \"quality\": \"A\", \"reserve\": \"\", \"carmodel\": \"2,8 CRD 4WD\", \"engineno\": \"\", \"fromyear\": \"2008\", \"position\": 0, \"reserved\": \"\", \"scrapper\": \"\", \"subgroup\": \"\", \"warranty\": \"\", \"bodycolor\": \"SVART\", \"cabasrikt\": null, \"enginesno\": null, \"kilometer\": 19243, \"modelcode\": \"21544\", \"modelyear\": \"2009\", \"partindex\": \"126074050\", \"pricedate\": \"2020-01-09T15:50:42\", \"signature\": \"DF\", \"stockitem\": \"\", \"vinnumber\": \"1J8GNE8599W502957\", \"carbreaker\": \"AN\", \"effectunit\": \"kW\", \"enginetype\": \"9\", \"kilometers\": 19243, \"preference\": \"\", \"reserveonr\": \"\", \"sbrcarcode\": \"1260\", \"dismantleid\": 6792768, \"dismantleno\": \"390781\", \"motorcode_1\": \"9\", \"motorcode_2\": \"\", \"remarklocal\": \"\", \"sbrpartcode\": \"7405\", \"engineremark\": null, \"lagawarranty\": \"\", \"quantitytype\": 0, \"wharehouseid\": \"AN-359974\", \"carbreakerexp\": 0, \"qualityremark\": \"\", \"cardescription\": \"Jeep Cherokee\", \"originalnocopy\": \"\", \"originalnumber\": \"1042106080\", \"pricesignature\": \"PS\", \"warrantyamount\": 0.0, \"articlenonumber\": \"1042106080\", \"dismantlingdate\": \"2019-11-22T00:00:00\", \"dismantlingnote\": \"9 aut\", \"referencenumber\": 359974, \"storagelocation\": \"AFC305\", \"originalnonumber\": \"1042106080\", \"storagesignature\": \"\", \"volvoaccountancy\": 0, \"wharehouseidlaga\": \"AN-L359974\", \"articlenophysical\": \"04801338AB\", \"dissasemblycardid\": 6792768, \"visiblestockitemid\": \"04801338AB\", \"dissasemblycardnote\": \"MOTOR OCH L\x{c5}DA PK OK!!!\", \"stockitemdescription\": \"Generator\", \"articlenophysicalnumber\": \"\"}",
    'company' => 'Laga',
    'price' => '1440.0',
    'stockitem' => '44722214',
    'supplier' => {
        'address' => {
            'addresses_pkey' => 8,
            'zipcode' => '725 94',
            'name' => 'Ansta Bildemontering AB',
            'city' => "V\x{c4}STER\x{c5}S",
            'address3' => '',
            'address2' => '',
            'address1' => 'Ansta',
            'country' => 'Sverige',
            'address_type' => 'invoice'
        },
        'sales_mails' => '',
        'company' => {
            'company' => 'AN',
            'modby' => 'System',
            'name' => 'Ansta Bildemontering AB',
            'companies_pkey' => 76,
            'homepage' => 'www.anstabildemont.se',
            'editnum' => 1,
            'registrationnumber' => '556233-2592',
            'moddatetime' => '2018-11-01 17:27:56.861272',
            'menu_group' => 3,
            'insby' => 'System',
            'insdatetime' => '2018-11-01 17:27:56.861272',
            'phone' => '021-248 00   07.00-16.00'
        },
        'settings' => {
            'Has_Active_Orion' => {
                'setting_name' => 'Has_Active_Orion',
                'companies_fkey' => 226,
                'defined_settings_values_pkey' => 212,
                'setting_order' => 1,
                'setting_properties' => {
                    'has_orion' => 0
                },
                'setting_backend_properties' => '',
                'setting_value' => 'Has orion'
            },
            'Orion_Login_Data' => {
                'defined_settings_values_pkey' => 211,
                'companies_fkey' => 226,
                'setting_name' => 'Orion_Login_Data',
                'setting_order' => 1,
                'setting_backend_properties' => '',
                'setting_properties' => {
                    'username' => '',
                    'password' => ''
                },
                'setting_value' => 'Orion credentials'
            },
            'Home_route' => {
                'setting_properties' => '',
                'setting_backend_properties' => '',
                'setting_value' => 'search',
                'companies_fkey' => 226,
                'setting_name' => 'Home_route',
                'defined_settings_values_pkey' => 11115,
                'setting_order' => 0
            },
            'Max_Search_Results' => {
                'setting_order' => 0,
                'setting_name' => 'Max_Search_Results',
                'companies_fkey' => 226,
                'defined_settings_values_pkey' => 11113,
                'setting_value' => '1000',
                'setting_properties' => '',
                'setting_backend_properties' => ''
            },
            'Delsoek_path' => {
                'defined_settings_values_pkey' => 11180,
                'setting_name' => 'Delsoek_path',
                'companies_fkey' => 226,
                'setting_order' => 0,
                'setting_backend_properties' => '',
                'setting_properties' => '',
                'setting_value' => 'C:\\fenfiler\\delsoek.txt'
            },
            'Part_search_grid_fields' => {
                'defined_settings_values_pkey' => 14832,
                'companies_fkey' => 226,
                'setting_name' => 'Part_search_grid_fields',
                'setting_order' => 101,
                'setting_backend_properties' => '',
                'setting_properties' => {
                    'visible' => 'false'
                },
                'setting_value' => 'dissasemblycardid'
            },
            'Show_Price_With_Vat' => {
                'setting_name' => 'Show_Price_With_Vat',
                'companies_fkey' => 226,
                'defined_settings_values_pkey' => 11112,
                'setting_order' => 0,
                'setting_properties' => '',
                'setting_backend_properties' => '',
                'setting_value' => '0'
            },
            'Recyclingsystem' => {
                'defined_settings_values_pkey' => 144,
                'setting_name' => 'Recyclingsystem',
                'companies_fkey' => 76,
                'setting_order' => 1,
                'setting_backend_properties' => '',
                'setting_properties' => {
                    'recyclingsystemsettings' => '',
                    'recyclingsystem' => 'Fenix5'
                },
                'setting_value' => 'Recyclingsystem'
            }
        },
        'company_mails' => ''
    },
    'quantity' => 1,
    'basketid' => 'e3be837e-c2ee-612a-81aa-3b81b05bf6af',
    'delItem' => 0,
    'customer' => {
        'discount' => '0',
        'settings' => {
            'Part_search_grid_fields' => {
                'setting_value' => 'dissasemblycardid',
                'setting_properties' => {
                    'visible' => 'false'
                },
                'setting_backend_properties' => '',
                'setting_order' => 101,
                'companies_fkey' => 226,
                'setting_name' => 'Part_search_grid_fields',
                'defined_settings_values_pkey' => 14832
            },
            'Show_Price_With_Vat' => {
                'setting_order' => 0,
                'setting_name' => 'Show_Price_With_Vat',
                'companies_fkey' => 226,
                'defined_settings_values_pkey' => 11112,
                'setting_value' => '0',
                'setting_properties' => '',
                'setting_backend_properties' => ''
            },
            'Recyclingsystem' => {
                'setting_value' => 'Recyclingsystem',
                'setting_properties' => {
                    'recyclingsystem' => 'Fenix5',
                    'recyclingsystemsettings' => ''
                },
                'setting_backend_properties' => '',
                'setting_order' => 1,
                'setting_name' => 'Recyclingsystem',
                'companies_fkey' => 76,
                'defined_settings_values_pkey' => 144
            },
            'Delsoek_path' => {
                'setting_value' => 'C:\\fenfiler\\delsoek.txt',
                'setting_properties' => '',
                'setting_backend_properties' => '',
                'setting_order' => 0,
                'setting_name' => 'Delsoek_path',
                'companies_fkey' => 226,
                'defined_settings_values_pkey' => 11180
            },
            'Max_Search_Results' => {
                'setting_name' => 'Max_Search_Results',
                'companies_fkey' => 226,
                'defined_settings_values_pkey' => 11113,
                'setting_order' => 0,
                'setting_properties' => '',
                'setting_backend_properties' => '',
                'setting_value' => '1000'
            },
            'Orion_Login_Data' => {
                'setting_order' => 1,
                'setting_name' => 'Orion_Login_Data',
                'companies_fkey' => 226,
                'defined_settings_values_pkey' => 211,
                'setting_value' => 'Orion credentials',
                'setting_properties' => {
                    'username' => '',
                    'password' => ''
                },
                'setting_backend_properties' => ''
            },
            'Has_Active_Orion' => {
                'companies_fkey' => 226,
                'setting_name' => 'Has_Active_Orion',
                'defined_settings_values_pkey' => 212,
                'setting_order' => 1,
                'setting_properties' => {
                    'has_orion' => 0
                },
                'setting_backend_properties' => '',
                'setting_value' => 'Has orion'
            },
            'Home_route' => {
                'setting_value' => 'search',
                'setting_backend_properties' => '',
                'setting_properties' => '',
                'setting_order' => 0,
                'defined_settings_values_pkey' => 11115,
                'companies_fkey' => 226,
                'setting_name' => 'Home_route'
            }
        },
        'company_mails' => '',
        'externalids' => {
            'datatype' => 'externalids'
        },
        'debts' => 'ok',
        'address' => {
            'city' => "J\x{f6}nk\x{f6}ping",
            'address3' => '',
            'addresses_pkey' => 362,
            'name' => 'Lagagruppen AB',
            'zipcode' => '55303',
            'country' => 'Sverige',
            'address_type' => 'invoice',
            'address2' => '',
            'address1' => 'Ryhovsgatan 3'
        },
        'company' => {
            'menu_group' => 1,
            'moddatetime' => '2019-04-10 13:45:36.458707',
            'registrationnumber' => '556592-7513',
            'editnum' => 1,
            'homepage' => 'www.laga.se',
            'companies_pkey' => 226,
            'name' => 'Lagagruppen AB',
            'modby' => 'System',
            'company' => 'Laga',
            'phone' => '036-39 13 30',
            'insdatetime' => '2019-04-10 13:45:36.458707',
            'insby' => 'System'
        }
    },
    'stockitems_fkey' => 33061690
};



# my $item;
# $item->{token}           = 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F';
#     $item->{basketid}        = '123456543321234';
#     $item->{stockitem}       = '123456';
#     $item->{quantity}        = '1';
#     $item->{price}           = "100.00";
#     $item->{itemno}          = '10';
#     $item->{supplier}        = 'P';
#     $item->{description}     = 'Test';
#     $item->{company}     = 'F';
#     $item->{userid}     = 'jan@daje.work';
#     $item->{external_reservation} = 12345;

sub upsertitem {

    my $basket = Order::Helper::Shoppingcart->new(pg => $pg);

    my $item_json = encode_json($item);

    my $test = $basket->upsertItem($item_json);

    return 1;
}
ok(upsertitem());
done_testing();

