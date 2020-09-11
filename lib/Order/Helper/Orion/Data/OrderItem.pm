package Order::Helper::Orion::Data::OrderItem;
use Mojo::Base 'Order::Helper::Orion::Data::Base';

use DateTime;

has 'articleno' ;
has 'carbreaker' ;
has 'customerno' ;
has 'customerorderno' ;
has 'date' => sub { return DateTime->now() } ;
has 'discount' => 0;
has 'dismantleddate' => sub { return DateTime->now() } ;
has 'kind' ;
has 'orderingcarbreaker' ;
has 'originalno' ;
has 'partdesignation' ;
has 'partid' ;
has 'position' => 0;
has 'quality' => '*';
has 'quantity' => 1;
has 'referencenumber' ;
has 'remark' ;
has 'sbrcarcode' ;
has 'sbrpartcode' ;
has 'lagawarranty';
has 'priceperitem';
1;