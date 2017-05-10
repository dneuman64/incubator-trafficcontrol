package UI::LuaConfig;
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
#
#

# JvD Note: you always want to put Utils as the first use. Sh*t don't work if it's after the Mojo lines.
use UI::Utils;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
my $custom_config;

my $config1 = {
		name => "custom response",
		url => "https://trafficops.kabletown.net/customresponse.lua",
		vars => [
			{
				id => 1,
				config_name => "res_text",
				config_type => "string",
				config_regex => "[A-Za-z0-9]"
			},
			{
				id => 2,
				config_name => "res_code",
				config_type => "int",
				config_regex => "[0-9]"
			}
		]
	};

my $config2 = {
		name => "set host",
		url => "https://github.com/myuser/sethost.lua",
		vars => [
			{
				id => 1,
				config_name => "hostname",
				config_type => "string",
				config_regex => "[A-Za-z -]"
			}
 		]
	};
# Table view
sub index {
	my $self = shift;
	&navbarpage($self);
}

sub edit {
	my $self = shift;
	my $id   = $self->param('id');
	if ($id == 1) {
		$self->stash( config_data    => $config1 );
	} elsif ($id == 2) {
		$self->stash( config_data    => $config1 );
	}
	else {
		$self->stash( config_data    => $custom_config );
	}

	$self->stash( fbox_layout => 1 );
	$self->render( template => 'lua_config/edit' );

}

sub add {
	my $self = shift;
	$self->stash( config_data    => {} );
	$self->stash( fbox_layout => 1 );
	$self->render( template => 'lua_config/add' );
}

sub create {
	my $self = shift;
	$custom_config = {
		name => $self->param('config_data.name'),
		url =>  $self->param('config_data.url'),
		vars => [
			{
				config_name => $self->param('var.config_name'),
				config_type => $self->param('var.config_type'),
				config_regex => $self->param('var.config_regex')
			}
		]};
	$self->stash( id    => "3" );
	$self->stash( fbox_layout => 1 );
	$self->flash( message => "Successfully added config!" );
	return $self->redirect_to( '/luaconfig/3/edit' );
}

sub assign {
	my $self = shift;
	my $config_name = $self->param('config_data.name');
	my $ds_id = $self->param('id');

	if (defined($config_name)) { #POST from select profile
		if ($config_name =~ $config1->{name}) {
			$config1->{vars}[0]->{value} = "";
			$config1->{vars}[1]->{value} = "";
			$self->stash(selected_config => $config1);
		} else {
			$config2->{vars}[0]->{value} = "";
			$self->stash(selected_config => $config2);
		}
		$self->stash (
			configs => [],
		);

	} else { #GET
		my $ds_id = $self->param('id');
		my $rs_ds  = $self->db->resultset('Deliveryservice')->search( { 'me.id' => $ds_id }, { prefetch => [ 'cdn', 'type' ] } );
		my $data   = $rs_ds->single;
		my $xml_id = $data->xml_id;
		&stash_role($self);
		$self->stash(
				configs => [$config1, $config2],
				selected_config => {}
				);
		}
	$self->stash(
			fbox_layout => 1,
			xml_id => $ds_id,
			message => ""
			);
	$self->render( template => 'lua_config/assign' );


}

sub configds {
	my $self = shift;
	my $xml_id = $self->param('id');
	my $config_name = $self->param('config_data.name');

	if ($config_name =~ $config1->{name}) {
		$config1->{vars}[0]->{value} = $self->param('var.value1');
		$config1->{vars}[1]->{value} = $self->param('var.value2');
		$self->stash(selected_config => $config1);

	} else {
		$config2->{vars}[0]->{value} = $self->param('var.value1');
		$self->stash(selected_config => $config2);
	}
	$self->stash (
		configs => [],
		fbox_layout => 1,
		xml_id => $xml_id,
		message => "Successfully added config!"
	);
	# return $self->redirect_to( "/ds/$xml_id/luaconfig" );
	$self->render( template => 'lua_config/assign' );
}

1;
