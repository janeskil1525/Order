use Mojo::Base -strict, -signatures, -async_await;

use Test::More;
use Order::Helper::Client;
use Mojo::JSON qw {from_json};

sub checkout() {

    my $basket = from_json('{"basket":{"basket_pkey":3,"company":"LA","moddatetime":"2021-03-26 17:52:35.050565","payment":"","reference":"","system":"LagaPro","userid":"janeskil1525@gmail.com"},"customer":{"company":{"companies_pkey":226,"company":"LA","editnum":1,"homepage":"www.laga.se","insby":"System","insdatetime":"2019-04-10 13:45:36.458707","menu_group":1,"modby":"System","moddatetime":"2019-04-10 13:45:36.458707","name":"Lagagruppen AB","phone":"036-39 13 30","registrationnumber":"556592-7513"},"company_mails":null,"deliveryaddress":{"address1":"Ryhovsgatan 3","address2":"","address3":"","address_type":"Delivery","addresses_pkey":20,"city":"Jönköping","company":"LA","country":"Sverige","editnum":1,"insby":"Unknown","insdatetime":"2021-04-08 13:49:46.519792","modby":"Unknown","moddatetime":"2021-04-08 13:49:46.519792","name":"Lagagruppen AB","system":"LagaPro","zipcode":"55303"},"invoiceaddress":{"address1":"Ryhovsgatan 3","address2":"","address3":"","address_type":"Invoice","addresses_pkey":19,"city":"Jönköping","company":"LA","country":"Sverige","editnum":1,"insby":"Unknown","insdatetime":"2021-04-08 13:49:46.376523","modby":"Unknown","moddatetime":"2021-04-08 13:49:46.376523","name":"Lagagruppen AB","system":"LagaPro","zipcode":"55303"},"sales_mails":null,"settings":{"orion":{"hasorion":1,"logindata":{"password":"la036","username":"Laga"}}}},"items":[{"basket_fkey":3,"basket_item_pkey":10,"description":"Generator","discount":"0.00","editnum":1,"expirydate":"2021-04-04 13:48:07.719373","externalref":0,"freight":"0.00","insby":"System","insdatetime":"2021-04-04 13:48:07.719373","itemtype":1,"modby":"System","moddatetime":"2021-04-04 13:48:07.719373","price":"1200.00","quantity":1,"reservation":"73018","rfq_note":null,"stockitem":"58440626","supplier":"J","supplier_data":{"address":{"address1":"Lagerg. 22","address2":"","address3":"","address_type":"Invoice","addresses_pkey":23,"city":"HELSINGBORG","company":"J","country":"Sverige","editnum":1,"insby":"Unknown","insdatetime":"2021-04-22 15:06:10.606947","modby":"Unknown","moddatetime":"2021-04-22 15:06:10.606947","name":"Bildemonteringen Helsingborg AB","system":"LagaPro","zipcode":"254 64"},"company":{"companies_pkey":107,"company":"J","editnum":1,"homepage":"www.bildemonteringhbg.se","insby":"System","insdatetime":"2018-11-01 17:27:57.190406","menu_group":3,"modby":"System","moddatetime":"2018-11-01 17:27:57.190406","name":"Bildemonteringen Helsingborg AB","phone":"042-15 88 40","registrationnumber":"556463-9887"},"company_mails":null,"sales_mails":null,"settings":{"orion":{"hasorion":true,"logindata":{"password":"ty65","username":"Hbg"},"recyclingsystem":"Fenix5"}}}},{"basket_fkey":3,"basket_item_pkey":11,"description":"Generator","discount":"0.00","editnum":1,"expirydate":"2021-04-04 13:48:40.351439","externalref":0,"freight":"0.00","insby":"System","insdatetime":"2021-04-04 13:48:40.351439","itemtype":1,"modby":"System","moddatetime":"2021-04-04 13:48:40.351439","price":"2160.00","quantity":1,"reservation":"73019","rfq_note":null,"stockitem":"76466616","supplier":"SV","supplier_data":{"address":{"address1":"Industrivägen 8","address2":"","address3":"","address_type":"Invoice","addresses_pkey":24,"city":"ODENSBACKEN","company":"SV","country":"Sverige","editnum":1,"insby":"Unknown","insdatetime":"2021-04-22 15:06:10.914892","modby":"Unknown","moddatetime":"2021-04-22 15:06:10.914892","name":"Svensk Bilåtervinning AB","system":"LagaPro","zipcode":"715 31"},"company":{"companies_pkey":130,"company":"SV","editnum":1,"homepage":"www.svenskbilatervinning.se","insby":"System","insdatetime":"2018-11-01 17:27:57.457659","menu_group":3,"modby":"System","moddatetime":"2018-11-01 17:27:57.457659","name":"Svensk Bilåtervinning AB","phone":"019-45 06 90","registrationnumber":"556544-5953"},"company_mails":null,"sales_mails":null,"settings":{"orion":{"hasorion":true,"logindata":{"password":"matorit","username":"Svbi"},"recyclingsystem":"Fenix5"}}}}]}');

    Order::Helper::Client->new(
        endpoint_address => 'http://127.0.0.1:3011',
        key              => 'c6629f75-e46d-4829-adea-23451410b495'
    )->checkout(
        'janeskil1525@gmail.com', 'AL', 'LagaPro', $basket
    )->then(sub ($result) {
        return $result;
    })->wait;
}

ok(checkout() == 1);
done_testing();

