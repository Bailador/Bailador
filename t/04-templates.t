use Test;
use Bailador;
Bailador::import;
use Bailador::Test;

plan 1;

get '/' => sub { template 'simple.tt', 'bar' }

response-content-is 'GET', '/', "a happy bar\n";
