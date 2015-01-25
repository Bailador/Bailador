use Test;
use Bailador;
Bailador::import;
use Bailador::Test;

plan 1;

get '/' => sub { template 'simple.tt', 'bar' }

is_deeply get-psgi-response('GET',  '/'),  [200, ["Content-Type" => "text/html"], "a happy bar\n"],   'route GET / returns content';
