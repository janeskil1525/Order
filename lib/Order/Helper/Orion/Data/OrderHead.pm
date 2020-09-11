package Order::Helper::Orion::Data::OrderHead;
use Mojo::Base 'Order::Helper::Orion::Data::Base';

use DateTime;

has 'carbreaker' => '';
has 'customerorderdate' => '';
has 'customerorderno' => '';
has 'customerref' => '';
has 'extreference' => '';
has 'extsource' => '';
has 'freight' => 0;
has 'invoiceaddress' => '';
has 'invoicecity' => '';
has 'invoicecountry' => '';
has 'invoicename' => '';
has 'invoicepostcode' => '';
has 'kind' => "X";
has 'orderdate' => sub { return DateTime->now()};
has 'ourref' => '';
has 'discount' => 0;
has 'paymentreference' => '';
has 'salesperson' => '';
has 'shippingaddress' => '';
has 'shippingcity' => '';
has 'shippingpostcode'=> '';
has 'shippingcountry' => '';
has 'shippingname' => '';
has 'shippingsms' => '';
has 'shippingphone' => '';
has 'newsletteremail' => '';
has 'newsletter' => '';
has 'text' => '';
has 'paymenttype' ;
has 'orders';
has 'rows';
has 'vrno';
has 'invfee' => 0;


1;