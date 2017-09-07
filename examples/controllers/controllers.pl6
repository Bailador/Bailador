use v6.c;
use Bailador;

## EXAMPLE 1 - with class
class My::Controller::Whatever {
    method show-whatever($id) {
         "whoop whoop $id";
    }
}

get '/whatever/:id' => { class => My::Controller::Whatever, to => 'show-whatever' };

## EXAMPLE 2 - with controller that is a 'persistant between call
class My::Controller::Hash {
    has %.data is required;

    method get($id) {
        "data for $id is " ~ ($.data{$id} // '');
    }
    method delete($id) {
        %.data{$id}:delete;
        "$id is deleted";
    }
    method post($id, $data) {
        %.data{$id} = $data.Str;
        "$data is stored at $id";
    }
    method list {
        %.data.perl;
    }
}

my $controller = My::Controller::Hash.new(data => {foo => 1, bar => 2});
get    '/data/:id'       => { :$controller, to => 'get'};
delete '/data/:id'       => { :$controller, to => 'delete'};
post   '/data/:id/:data' => { :$controller, to => 'post'};
get    '/data'           => { :$controller, to => 'list'};

baile();
