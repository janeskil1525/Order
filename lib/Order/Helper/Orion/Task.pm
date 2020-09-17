package Order::Helper::Orion::Task;
use Mojo::Base 'Daje::Utils::Sentinelsender';


sub init {
    my ($self, $minion) = @_;

    $minion->add_task(process_orion_orders => \&_process_orion_orders);
}

sub _process_orion_orders{
    my($job, $data) = @_;

    my $pg = $job->app->pg;
    my $config = $job->app->config;

    my $result = process_orion_orders($pg, $config, $data);

    if($result eq '1'){
        $job->finish({ status => 'success'});
    }else{
        $job->finish({ status => $result});
    }
}

sub process_orion_orders {
    my ($pg, $config, $data) = @_;

    my $salesorder = Order::Model::SalesOrderHead->new(pg => $pg);

    while (my $sales_order_head_pkey = $salesorder->get_order_for_export('orion')) {
        $salesorder->set_export_status($sales_order_head_pkey, 'inprogress');

        my $result = Order::Helper::Orion::Processor->new(
            pg => $pg, config => $config
        )->process_order(
            $sales_order_head_pkey
        );

        if($result eq '1') {
            $salesorder->set_export_status($sales_order_head_pkey, 'exported');
        } else {
            say 'Salesorder pkey = ' . $sales_order_head_pkey . ' Error: ' . $result;
            Daje::Utils::Sentinelsender->new(

            )->capture_message(
                '','Order::Helper::Orion::Task::process_orion_orders', 'process_orion_orders', (caller(0))[3],
                'Salesorder pkey = ' . $sales_order_head_pkey . ' Error: ' . $result
            );
            $salesorder->set_export_status($sales_order_head_pkey, $result);
        }
    }
}

sub process_orion_orders_test {
    my ($self, $pg, $config, $data) = @_;

    my $result = process_orion_orders($pg, $config, $data);

    return $result;
}


1;