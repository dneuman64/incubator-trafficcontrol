package main;
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Data::Dumper;
use DBI;
use JSON;
use strict;
use warnings;
no warnings 'once';
use warnings 'all';
use Test::TestHelper;

#no_transactions=>1 ==> keep fixtures after every execution, beware of duplicate data!
#no_transactions=>0 ==> delete fixtures after every execution

BEGIN { $ENV{MOJO_MODE} = "test" }

my $schema = Schema->connect_to_database;
my $dbh    = Schema->database_handle;
my $t      = Test::Mojo->new('TrafficOps');

Test::TestHelper->unload_core_data($schema);
Test::TestHelper->load_core_data($schema);

ok $t->post_ok( '/login', => form => { u => Test::TestHelper::ADMIN_USER, p => Test::TestHelper::ADMIN_USER_PASSWORD } )->status_is(302)
	->or( sub { diag $t->tx->res->content->asset->{content}; } ), 'Should login?';

# Count the 'response number'
my $count_response = sub {
	my ( $t, $count ) = @_;
	my $json = decode_json( $t->tx->res->content->asset->slurp );
	my $r    = $json->{response};
	return $t->success( is( scalar(@$r), $count ) );
};

# there are currently 3 servers of type EDGE or ORG where server.cdn == ds.cdn not assigned to ds 100
$t->get_ok('/api/1.2/deliveryservices/100/servers/unassigned')->status_is(200)->$count_response(4)
	->or( sub { diag $t->tx->res->content->asset->{content}; } );

# we will assign 2 more servers to ds 100
ok $t->post_ok('/api/1.2/deliveryserviceserver' => {Accept => 'application/json'} => json => {
			"dsId" => 100,
			"servers" => [ 1400, 1600 ]
		})
		->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
		->json_is( "/alerts/0/level" => "success" )
		->json_is( "/alerts/0/text" => "Server assignments complete." )
	, 'Are the servers assigned to the delivery service?';

# there are now 2 servers of type EDGE or ORG where server.cdn == ds.cdn not assigned to ds 100
$t->get_ok('/api/1.2/deliveryservices/100/servers/unassigned')->status_is(200)->$count_response(2)
	->or( sub { diag $t->tx->res->content->asset->{content}; } );

# there are currently 6 servers of type EDGE or ORG that can be assigned to ds 100
$t->get_ok('/api/1.2/deliveryservices/100/servers/eligible')->status_is(200)->$count_response(6)
	->or( sub { diag $t->tx->res->content->asset->{content}; } );

# It gets existing delivery services
ok $t->get_ok("/api/1.2/deliveryservices")->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content} } )
		->json_is( "/response/0/xmlId", "steering-ds1" )
		->json_is( "/response/0/logsEnabled", 0 )
		->json_is( "/response/0/ipv6RoutingEnabled", 1 )
		->json_is( "/response/1/xmlId", "steering-ds2" );

ok $t->get_ok("/api/1.2/deliveryservices?logsEnabled=true")->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content} } )
		->json_is( "/response/0/xmlId", "test-ds1" )
		->json_is( "/response/0/logsEnabled", 1 )
		->json_is( "/response/0/ipv6RoutingEnabled", 1 )
		->json_is( "/response/1/xmlId", "test-ds4" );

ok $t->post_ok('/api/1.2/deliveryservices' => {Accept => 'application/json'} => json => {
			"active" => \0,
			"cdnId" => 100,
			"displayName" => "ds_displayname_1",
			"dscp" => 0,
			"geoLimit" => 0,
			"geoProvider" => 0,
			"initialDispersion" => 1,
			"ipv6RoutingEnabled" => 0,
			"logsEnabled" => 0,
			"missLat" => 45,
			"missLong" => 45,
			"multiSiteOrigin" => 0,
			"orgServerFqdn" => "http://10.75.168.91",
			"protocol" => 1,
			"qstringIgnore" => 0,
			"rangeRequestHandling" => 0,
			"regionalGeoBlocking" => 0,
			"signed" => 0,
			"typeId" => 7,
			"xmlId" => "ds_1",
		})
    ->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
		->json_is( "/response/0/active" => 0)
		->json_is( "/response/0/cdnName" => "cdn1")
		->json_is( "/response/0/displayName" => "ds_displayname_1")
		->json_is( "/response/0/xmlId" => "ds_1")
		->json_is( "/response/0/multiSiteOrigin" => 0)
		->json_is( "/response/0/orgServerFqdn" => "http://10.75.168.91")
		->json_is( "/response/0/protocol" => 1)
		->json_is( "/response/0/regionalGeoBlocking" => 0)
		->json_is( "/response/0/type" => "DNS")
            , 'Does the deliveryservice details return?';

my $ds_id = &get_ds_id('ds_1');
ok $t->put_ok('/api/1.2/deliveryservices/' . $ds_id => {Accept => 'application/json'} => json => {
			"active" => \1,
			"cdnId" => 100,
			"displayName" => "ds_displayname_11",
			"dscp" => 1,
			"geoLimit" => 1,
			"geoProvider" => 1,
			"initialDispersion" => 2,
			"ipv6RoutingEnabled" => 1,
			"logsEnabled" => 1,
			"missLat" => 45,
			"missLong" => 45,
			"multiSiteOrigin" => 0,
			"orgServerFqdn" => "http://10.75.168.91",
			"protocol" => 2,
			"qstringIgnore" => 1,
			"rangeRequestHandling" => 1,
			"regionalGeoBlocking" => 1,
			"signed" => 1,
			"typeId" => 7,
			"xmlId" => "ds_1",
        })
    ->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
		->json_is( "/response/0/active" => 1)
		->json_is( "/response/0/cdnName" => "cdn1")
		->json_is( "/response/0/displayName" => "ds_displayname_11")
		->json_is( "/response/0/xmlId" => "ds_1")
		->json_is( "/response/0/multiSiteOrigin" => 0)
		->json_is( "/response/0/orgServerFqdn" => "http://10.75.168.91")
		->json_is( "/response/0/protocol" => 2)
		->json_is( "/response/0/regionalGeoBlocking" => 1)
		->json_is( "/response/0/type" => "DNS")
            , 'Does the deliveryservice details return?';


ok $t->delete_ok('/api/1.2/deliveryservices/' . $ds_id)->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } );

ok $t->put_ok('/api/1.2/deliveryservices/' . $ds_id => {Accept => 'application/json'} => json => {
			"active" => \1,
			"cdnId" => 100,
			"displayName" => "ds_displayname_11",
			"dscp" => 1,
			"geoLimit" => 1,
			"geoProvider" => 1,
			"initialDispersion" => 2,
			"ipv6RoutingEnabled" => 1,
			"logsEnabled" => 1,
			"missLat" => 45,
			"missLong" => 45,
			"multiSiteOrigin" => 0,
			"orgServerFqdn" => "http://10.75.168.91",
			"protocol" => 2,
			"qstringIgnore" => 1,
			"rangeRequestHandling" => 1,
			"regionalGeoBlocking" => 1,
			"signed" => 1,
			"typeId" => 7,
			"xmlId" => "ds_1",
})->status_is(404)->or( sub { diag $t->tx->res->content->asset->{content}; } );

ok $t->post_ok(
	'/api/1.2/deliveryservices/test-ds1/servers' => { Accept => 'application/json' } => json => {
		"serverNames" => [ "atlanta-edge-01", "atlanta-edge-02" ]
	}
	)->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )->json_is( "/response/xmlId" => "test-ds1" )
	->json_is( "/response/serverNames/0" => "atlanta-edge-01" )->json_is( "/response/serverNames/1" => "atlanta-edge-02" ),
	'Does the assigned servers return?';

ok $t->get_ok("/api/1.2/deliveryservices")->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content} } )
	->json_is( "/response/0/xmlId", "steering-ds1" )->json_is( "/response/0/logsEnabled", 0 )->json_is( "/response/0/ipv6RoutingEnabled", 1 )
	->json_is( "/response/1/xmlId", "steering-ds2" );

$t->get_ok('/api/1.2/deliveryservices?logsEnabled=true')->status_is(200)->$count_response(2);

ok $t->put_ok('/api/1.2/snapshot/cdn1')->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } );

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );
$dbh->disconnect();
done_testing();

sub get_ds_id {
    my $xml_id = shift;
    my $q      = "select id from deliveryservice where xml_id = \'$xml_id\'";
    my $get_svr = $dbh->prepare($q);
    $get_svr->execute();
    my $p = $get_svr->fetchall_arrayref( {} );
    $get_svr->finish();
    my $id = $p->[0]->{id};
    return $id;
}
