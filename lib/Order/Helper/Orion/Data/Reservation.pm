package Order::Helper::Orion::Data::Reservation;
use Mojo::Base 'Order::Helper::Orion::Data::Base';

has 'carbreaker';
has 'expired' => sub { return DateTime->now() } ;;
has 'extreference';
has 'extsource';
has 'id';
has 'lastupdate' => sub { return DateTime->now() } ;;
has 'partid';
# 2 betyder att delen är lagrad i kundkorg, dessa reservationer rensas efter 20 minuter.
# 3 nu ligger delen på en order.
# 5 kommer inte ihåg men sökt medc  så jag återkommer.
#6 betyder att delen är levererad från ett synkande företag så dessa delar skall inte visas
# när man söker delar. När vi byggde orions apier kom den till för att delen måste ligga kvar
# tills sista företaget hanterat ordern. Men delen är egentligen redan på väg till kund.
has 'reservationtype';
has 'usersign';

1;