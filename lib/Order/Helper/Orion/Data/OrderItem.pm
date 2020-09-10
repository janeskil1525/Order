package Order::Helper::Orion::Data::OrderItem;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use DateTime;

has 'articleno' ;
has 'carbreaker' ;
has 'customerno' ;
has 'customerorderno' ;
has 'date' = DateTime->now() ;
has 'discount' => 0;
has 'dismantleddate' ;
has 'kind' ;
has 'orderingcarbreaker' ;
has 'originalno' ;
has 'partdesignation' ;
has 'partid' ;
has 'position' => 0;
has 'quality' ;
has 'quantity' => 1;
has 'referencenumber' ;
has 'remark' ;
has 'sbrcarcode' ;
has 'sbrpartcode' ;
has 'lagawarranty';
has 'priceperitem'
1;